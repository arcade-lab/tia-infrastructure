"""
A collection of generators for simulator systems.
"""

from constants.direction import *
from simulator.array import Array
from simulator.block import Block
from simulator.memory import *
from simulator.processing_element import ProcessingElement
from simulator.quartet import Quartet
from simulator.system import System


def build_ats_system(num_rows, num_columns, cp, ip, sp):
    """
    Build an array test system (primarily for functional simulation of abstract systems).

    :param num_rows: rows of processing elements in the array
    :param num_columns: columns processing elements in the array
    :param cp: a CoreParameters instance
    :param ip: an InterconnectParameters instance
    :param sp: a SystemParameters instance
    :return: a configured system
    """

    # Initialize an array of the requested size and a data memory.
    system = System()
    array = Array(name="array_0", num_rows=num_rows, num_columns=num_columns, cp=cp, ip=ip)
    system.register(array)
    memory = Memory("memory", sp.num_test_data_memory_words)

    # Create an array of read ports attached along the north edge.
    read_ports = [ReadPort(f"read_port_{i}", sp.test_data_memory_buffer_depth) for i in range(num_columns)]
    for j, read_port in enumerate(read_ports):
        processing_element = array.processing_elements[j]
        processing_element.connect_to_receiver_channel_buffer(Direction.north, read_port.addr_in_channel_buffer)
        processing_element.connect_to_sender_channel_buffer(Direction.north, read_port.data_out_channel_buffer)
        memory.add_read_port(read_port)

    # Create an array of write ports attached along the south edge.
    write_ports = [WritePort(f"write_port_{i}", sp.test_data_memory_buffer_depth) for i in range(int(num_columns / 2))]
    for j, write_port in enumerate(write_ports):
        base_processing_element_index = (num_rows - 1) * num_columns
        address_processing_element_index = base_processing_element_index + 2 * j
        data_processing_element_index = base_processing_element_index + 2 * j + 1
        address_processing_element = array.processing_elements[address_processing_element_index]
        data_processing_element = array.processing_elements[data_processing_element_index]
        address_processing_element.connect_to_receiver_channel_buffer(Direction.south, write_port.addr_in_channel_buffer)
        data_processing_element.connect_to_receiver_channel_buffer(Direction.south, write_port.data_in_channel_buffer)
        memory.add_write_port(write_port)

    # Register the memory (must be done after all ports are instantiated and linked).
    system.register(memory)

    # Verify and alphabetize the components for debug output.
    system.finalize()

    # Return the configured system.
    return system


def build_pets_system(cp, ip, sp):
    """
    Build the representation of the hardware processing element test system.

    :param cp: a CoreParameters instance
    :param ip: an InterconnectParameters instance
    :param sp: a SystemParameters instance
    :return: a configured system
    """

    # Initialize a single processing element (which must be called "processing_element_0") and a data memory.
    system = System()
    processing_element = ProcessingElement(name="processing_element_0", cp=cp, ip=ip)
    system.register(processing_element)
    memory = Memory("memory", sp.num_test_data_memory_words)

    # Wire up the first read port.
    read_port_0 = ReadPort("read_port_0", sp.test_data_memory_buffer_depth)
    processing_element.connect_to_receiver_channel_buffer(Direction.north, read_port_0.addr_in_channel_buffer)
    processing_element.connect_to_sender_channel_buffer(Direction.north, read_port_0.data_out_channel_buffer)
    memory.add_read_port(read_port_0)

    # Wire up the second read port.
    read_port_1 = ReadPort("read_port_1", sp.test_data_memory_buffer_depth)
    processing_element.connect_to_receiver_channel_buffer(Direction.east, read_port_1.addr_in_channel_buffer)
    processing_element.connect_to_sender_channel_buffer(Direction.east, read_port_1.data_out_channel_buffer)
    memory.add_read_port(read_port_1)

    # Wire up the write port.
    write_port = WritePort("write_port", sp.test_data_memory_buffer_depth)
    processing_element.connect_to_receiver_channel_buffer(Direction.south, write_port.addr_in_channel_buffer)
    processing_element.connect_to_receiver_channel_buffer(Direction.west, write_port.data_in_channel_buffer)
    memory.add_write_port(write_port)

    # Register the memory (must be done after all ports are instantiated and linked).
    system.register(memory)

    # Verify and alphabetize the components for debug output.
    system.finalize()

    # Return the configured system.
    return system


def build_qts_system(cp, ip, sp):
    """
    Build the representation of the hardware quartet test system.

    :param cp: a CoreParameters instance
    :param ip: an InterconnectParameters instance
    :param sp: a SystemParameters instance
    :return: a configured system
    """

    # Initialize a quartet and a data memory.
    system = System()
    quartet = Quartet(name="quartet_0", cp=cp, ip=ip, row_base_index=0, column_base_index=0, num_columns=2)
    system.register(quartet)
    memory = Memory("memory", sp.num_test_data_memory_words)

    # Wire up the first read port.
    read_port_0 = ReadPort("read_port_0", sp.test_data_memory_buffer_depth)
    quartet.processing_elements[0].connect_to_receiver_channel_buffer(Direction.north,
                                                                      read_port_0.addr_in_channel_buffer)
    quartet.processing_elements[0].connect_to_sender_channel_buffer(Direction.north,
                                                                    read_port_0.data_out_channel_buffer)
    memory.add_read_port(read_port_0)

    # Wire up the second read port.
    read_port_1 = ReadPort("read_port_0", sp.test_data_memory_buffer_depth)
    quartet.processing_elements[1].connect_to_receiver_channel_buffer(Direction.north,
                                                                      read_port_1.addr_in_channel_buffer)
    quartet.processing_elements[1].connect_to_sender_channel_buffer(Direction.north,
                                                                    read_port_1.data_out_channel_buffer)
    memory.add_read_port(read_port_1)

    # Wire up the write port.
    write_port = WritePort("write_port", sp.test_data_memory_buffer_depth)
    quartet.processing_elements[2].connect_to_receiver_channel_buffer(Direction.south,
                                                                      write_port.addr_in_channel_buffer)
    quartet.processing_elements[3].connect_to_receiver_channel_buffer(Direction.south,
                                                                      write_port.data_in_channel_buffer)
    memory.add_write_port(write_port)

    # Register the memory (must be done after all ports are instantiated and linked).
    system.register(memory)

    # Verify and alphabetize the components for debug output.
    system.finalize()

    # Return the configured system.
    return system


def build_bts_system(cp, ip, sp):
    """
    Build the representation of the hardware block test system.

    :param cp: a CoreParameters instance
    :param ip: an InterconnectParameters instance
    :param sp: a SystemParameters instance
    :return: a configured system
    """

    # Initialize a single block and a data memory.
    system = System()
    block = Block(name="block_0", cp=cp, ip=ip, row_base_index=0, column_base_index=0, num_columns=4)
    system.register(block)
    memory = Memory("memory", sp.num_test_data_memory_words)

    # Wire up the first read port.
    read_port_0 = ReadPort("read_port_0", sp.test_data_memory_buffer_depth)
    block.quartets[0].processing_elements[0].connect_to_receiver_channel_buffer(Direction.north,
                                                                                read_port_0.addr_in_channel_buffer)
    block.quartets[0].processing_elements[0].connect_to_sender_channel_buffer(Direction.north,
                                                                              read_port_0.data_out_channel_buffer)
    memory.add_read_port(read_port_0)

    # Wire up the second read port.
    read_port_1 = ReadPort("read_port_1", sp.test_data_memory_buffer_depth)
    block.quartets[0].processing_elements[1].connect_to_receiver_channel_buffer(Direction.north,
                                                                                read_port_1.addr_in_channel_buffer)
    block.quartets[0].processing_elements[1].connect_to_sender_channel_buffer(Direction.north,
                                                                              read_port_1.data_out_channel_buffer)
    memory.add_read_port(read_port_1)

    # Wire up the third read port.
    read_port_2 = ReadPort("read_port_2", sp.test_data_memory_buffer_depth)
    block.quartets[1].processing_elements[0].connect_to_receiver_channel_buffer(Direction.north,
                                                                                read_port_2.addr_in_channel_buffer)
    block.quartets[1].processing_elements[0].connect_to_sender_channel_buffer(Direction.north,
                                                                              read_port_2.data_out_channel_buffer)
    memory.add_read_port(read_port_2)

    # Wire up the fourth read port.
    read_port_3 = ReadPort("read_port_3", sp.test_data_memory_buffer_depth)
    block.quartets[1].processing_elements[1].connect_to_receiver_channel_buffer(Direction.north,
                                                                                read_port_3.addr_in_channel_buffer)
    block.quartets[1].processing_elements[1].connect_to_sender_channel_buffer(Direction.north,
                                                                              read_port_3.data_out_channel_buffer)
    memory.add_read_port(read_port_3)

    # Wire up the write port.
    write_port = WritePort("write_port", sp.test_data_memory_buffer_depth)
    block.quartets[2].processing_elements[2].connect_to_receiver_channel_buffer(Direction.south,
                                                                                write_port.addr_in_channel_buffer)
    block.quartets[2].processing_elements[3].connect_to_receiver_channel_buffer(Direction.south,
                                                                                write_port.data_in_channel_buffer)
    memory.add_write_port(write_port)

    # Register the memory (must be done after all ports are instantiated and linked).
    system.register(memory)

    # Verify and alphabetize the components for debug output.
    system.finalize()

    # Return the configured system.
    return system
