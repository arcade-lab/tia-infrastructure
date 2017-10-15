"""
Channels and related utilities.
"""

from collections import deque

from simulator.exception import SimulatorException


class Packet:
    """
    Packet to be sent along a local LID connection.
    """

    def __init__(self, tag, value):
        """
        Initialize a packet.

        :param tag: enumerated tag
        :param value: data segment
        """

        # Expected initialization.
        self.tag = tag
        self.value = value

    def __repr__(self):
        return f"<tag: 0x{self.tag:01x}, value: 0x{self.value:08x}>"


class Buffer:
    """
    LID buffer.
    """

    def __init__(self, name, depth):
        """
        Initialize a LID channel.

        :param name: for debugging usage
        :param depth: depth of queue
        """

        # Expected initialization.
        self.name = name
        self.deque = deque(maxlen=depth)
        self.depth = depth
        self.staged_enqueue = False
        self.staged_packet = None
        self.staged_dequeue = False
        self.pending = False

    # --- Queue Access Methods and Properties ---

    def enqueue(self, packet):
        """
        Enqueue a packet on the channel. Will raise an exception if the channel is full.

        :param packet: packet to enqueue
        """

        # Perform a quick check then stage a packet to be enqueued.
        if self.full:
            raise SimulatorException("Attempted to enqueue a packet on a full buffer.")
        self.staged_enqueue = True
        self.staged_packet = packet
        self.pending = True

    def dequeue(self):
        """
        Dequeue the next value on the channel. Will raise an exception if the channel is empty.

        :return: dequeued packet
        """

        # Perform a quick check then stage a packet to dequeue, and return the contents of said packet.
        if self.empty:
            raise SimulatorException("Attempted to dequeue a packet from an empty buffer.")
        self.staged_dequeue = True
        self.pending = True
        return self.peek()

    def peek(self):
        """
        Return the next item in the channel.

        :return: head of the channel's FIFO
        """

        # Perform a quick check then just return what we see.
        if self.empty:
            raise SimulatorException("Attempted to peek the next value on an empty buffer.")
        return self.deque[0]

    def commit(self, debug):
        """
        Finish outstanding channel transactions after all PEs and MEs have had state updates via calls to *.iterate().

        :param debug: whether to print out information about internal state
        """

        # Output internal information if debugging.
        if debug:
            print(f"name: {self.name}")
            print(f"depth: {self.depth}")
            print(f"contents: {[packet for packet in self.deque]}\n")

        # If there are any pending packets to enqueue or dequeue, do so now.
        if self.pending:
            if self.staged_dequeue:
                self.deque.popleft()  # Discard since it has already been returned to the dequeue() call.
                self.staged_dequeue = False
            if self.staged_enqueue:
                self.deque.append(self.staged_packet)
                self.staged_enqueue = False
                self.staged_packet = None
            self.pending = False

    def reset(self):
        """
        Reset internal state and empty the buffer.
        """

        # Restore initial state.
        self.staged_enqueue = False
        self.staged_packet = None
        self.staged_dequeue = False
        self.pending = False

        # Manually empty the internal deque.
        while len(self.deque) != 0:
            self.deque.popleft()

    @property
    def count(self):
        return len(self.deque)

    @property
    def remaining(self):
        return self.depth - self.count

    @property
    def full(self):
        return len(self.deque) == self.depth

    @property
    def empty(self):
        return len(self.deque) == 0


class SenderChannelBuffer(Buffer):
    """
    This peripheral destination field is meant to be used a hook for the event loop so that the memory can enqueue new
    words into buffers in the main processing element array.
    """

    # Call the parent class initializer and add the field.
    def __init__(self, name, depth):
        super(SenderChannelBuffer, self).__init__(name, depth)
        self.peripheral_destination = None


class ReceiverChannelBuffer(Buffer):
    pass


class RoutingBuffer(Buffer):
    pass
