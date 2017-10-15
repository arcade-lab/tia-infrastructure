"""
Memories and related utilities.
"""

from enum import IntEnum

import numpy as np

from simulator.interconnect import Packet, SenderChannelBuffer, ReceiverChannelBuffer


class ReadPort:
    """
    Read port interface.
    """

    def __init__(self, name, buffer_depth):
        """
        Initialize a read port.

        :param name: an English name
        :param buffer_depth: access buffer depth
        """

        # Derive buffer names.
        self.name = name
        self.addr_in_channel_buffer = ReceiverChannelBuffer(f"{name} Address-In Channel Buffer", buffer_depth)
        self.data_out_channel_buffer = SenderChannelBuffer(f"{name} Data-Out Channel Buffer", buffer_depth)
        self.pending_read_packet = None


class WritePort:
    """
    Write port interface.
    """

    def __init__(self, name, buffer_depth):
        """
        Initialize a write port.

        :param name: an English name
        :param buffer_depth: access buffer depth
        """

        # Derive buffer names.
        self.name = name
        self.addr_in_channel_buffer = ReceiverChannelBuffer(f"{name} Address-In Channel Buffer", buffer_depth)
        self.data_in_channel_buffer = ReceiverChannelBuffer(f"{name} Data-In Channel Buffer", buffer_depth)


class Memory:
    """
    Memory with arbitrary read and write ports and stream ports.
    """

    def __init__(self, name, size):
        """
        Initialize a memory element.

        :param name: an English name
        :param size: number of words of storage
        """

        # Set to values expected upon reset.
        self.name = name
        self.contents = np.zeros(size, dtype=np.uint32)
        self.read_ports = []
        self.write_ports = []

    # --- Setup Methods ---

    def add_read_port(self, read_port):
        # Accessor method.
        self.read_ports.append(read_port)

    def add_write_port(self, write_port):
        # Accessor method.
        self.write_ports.append(write_port)

    # --- System Registration Method ---

    def _register(self, system):
        """
        Register the memory with the system event loop.
        
        :param system: the rest of the system
        """

        # Register the memory itself and any buffers.
        system.memories.append(self)
        for read_port in self.read_ports:
            system.buffers.append(read_port.addr_in_channel_buffer)
            system.buffers.append(read_port.data_out_channel_buffer)
        for write_port in self.write_ports:
            system.buffers.append(write_port.addr_in_channel_buffer)
            system.buffers.append(write_port.data_in_channel_buffer)

    # --- Time-stepping Method ---

    def iterate(self, debug):
        """
        Perform a single cycle of execution.

        :param debug: whether to print out information about internal state
        """

        # Write out the current contents of memory if debugging.
        if debug:
            print(f"name: {self.name}")
            print("contents:")
            i = 0
            while i < 10:
                if i < len(self.contents):
                    print(f"0x{self.contents[i]:08x}")
                else:
                    break
                i += 1
            if len(self.contents) > 10:
                print("...\n")
            else:
                print("bound\n")

        # Output data packet origination and pending reads.
        for read_port in self.read_ports:
            if read_port.data_out_channel_buffer.peripheral_destination is not None:
                if (not read_port.data_out_channel_buffer.peripheral_destination.full
                    and not read_port.data_out_channel_buffer.empty):
                    read_data_packet = read_port.data_out_channel_buffer.dequeue()
                    read_port.data_out_channel_buffer.peripheral_destination.enqueue(read_data_packet)
            if read_port.pending_read_packet:
                if not read_port.data_out_channel_buffer.full:
                    if debug:
                        print(f"{read_port.name} read {read_port.pending_read_packet}.\n")
                    read_port.data_out_channel_buffer.enqueue(read_port.pending_read_packet)
                    read_port.pending_read_packet = None

        # Serve all valid requests on available ports.
        for read_port in self.read_ports:
            if not read_port.addr_in_channel_buffer.empty and read_port.pending_read_packet is None:
                read_addr_packet = read_port.addr_in_channel_buffer.dequeue()
                read_addr = read_addr_packet.value
                if debug:
                    print(f"{read_port.name} requesting data at address {read_addr_packet}.\n")
                read_port.pending_read_packet = Packet(read_addr_packet.tag, self.contents[read_addr])

        # Perform all valid write requests on available ports.
        for write_port in self.write_ports:
            if not write_port.addr_in_channel_buffer.empty and not write_port.data_in_channel_buffer.empty:
                write_addr_packet = write_port.addr_in_channel_buffer.dequeue()
                write_addr = write_addr_packet.value
                write_data_packet = write_port.data_in_channel_buffer.dequeue()
                write_data = write_data_packet.value
                if debug:
                    print(f"{write_port.name} writing {write_data_packet} at address {write_addr_packet}.\n")
                self.contents[write_addr] = write_data

    # --- Reset Method ---

    def reset(self):
        """
        Reset the memory.
        """

        # Note: we assume the contents of the memory is persistent.

        # Reset any internal state.
        for read_port in self.read_ports:
            read_port.pending_read_packet = None
        for write_port in self.write_ports:
            pass  # No internal state for now.

        # Reset any buffers.
        for read_port in self.read_ports:
            read_port.addr_in_channel_buffer.reset()
            read_port.data_out_channel_buffer.reset()
        for write_port in self.write_ports:
            write_port.addr_in_channel_buffer.reset()
            write_port.data_in_channel_buffer.reset()
