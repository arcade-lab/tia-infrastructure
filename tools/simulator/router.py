"""
Interconnect routers and related utilities.
"""

from enum import IntEnum

from constants.direction import reverse_direction_map, direction_name_map
from simulator.exception import SimulatorException
from simulator.interconnect import Buffer, SenderChannelBuffer, ReceiverChannelBuffer


# TODO: Refactor how InterconnectParameters get passed in.


class RouterType(IntEnum):
    software = 0
    switch = 1
    virtual_circuit = 2


class Router:
    """
    Router base class.
    """

    def __init__(self, ip, core):
        """
        Initialize a router.

        :param ip: an InterconnectParameters instance
        :param core: the processing element core containing input and output buffers
        """

        # Connect the router to the input and output channel buffers and the physical link buffers.
        self.core = core
        self.input_channel_buffers = core.input_channel_buffers
        self.output_channel_buffers = core.output_channel_buffers
        self.local_buffers = None
        self.source_buffers = None
        self.destination_buffers = None

    # --- Base Class Methods ---

    def connect_to_processing_element(self, direction, processing_element):
        """
        Link a router to another software router/core processing element.

        :param direction: direction from the current processing element to the neighboring processing element
        :param processing_element: neighboring processing element
        """

        # Implemented in child classes.
        pass

    def connect_to_sender_channel_buffer(self, direction, sender_channel_buffer):
        """
        Connect the router to a buffer that emits packets.

        :param direction: direction from the current processing element to the buffer
        :param sender_channel_buffer: sending buffer
        """

        # Implemented in child classes.
        pass

    def connect_to_receiver_channel_buffer(self, direction, receiver_channel_buffer):
        """
        Connect the router to a buffer that receives packets.

        :param direction: direction from the current processing element to the buffer
        :param receiver_channel_buffer: receiving buffer
        """

        # Implemented in child classes.
        pass

    def _register(self, system):
        """
        Register the router with the system event loop.

        :param system: the rest of the system
        """

        # Implemented in child classes.
        pass

    def iterate(self, debug):
        """
        Perform a single cycle of execution.

        :param debug: whether to print out information about internal state
        """

        # Implemented in child classes.
        pass

    def reset(self):
        """
        Reset any internal state.
        """

        # Implemented in child classes.
        pass


class SoftwareRouter(Router):
    """
    A Router implementation that leaves all routing up to the hardware. That is, the four input and output channels all
    have a cardinal direction associated with them and route to/from the nearest neighbor in that direction.
    """

    def __init__(self, ip, core):
        """
        Initialize the software router. Nothing in particular to do here since this router is just wires from the input
        and output channel buffers to the physical links.

        :param ip: an InterconnectParameters instance
        :param core: the processing element core containing input and output buffers
        """

        # Call the parent class initializer, and initialize buffers.
        super(SoftwareRouter, self).__init__(ip, core)
        self.local_buffers = None  # References to neighbor input/output channel buffers instead of true local buffers.
        self.source_buffers = [None] * ip.num_router_sources
        self.destination_buffers = [None] * ip.num_router_destinations

    # --- Base Class Method Implementations ---

    def connect_to_processing_element(self, direction, processing_element):
        """
        Link a router to another software router/core processing element.

        :param direction: direction from the current processing element to the neighboring processing element
        :param processing_element: neighboring processing element
        """

        # Make sure we are connecting to a processing element that is also using a software router.
        if not isinstance(processing_element.router, SoftwareRouter):
            raise SimulatorException(f"Cannot connect a {type(self)} to a {type(processing_element.router)}.")

        # Associate the two processing elements' source and destination buffers directly with their input and output
        # channel buffers.
        self.destination_buffers[direction] \
            = processing_element.core.input_channel_buffers[reverse_direction_map[direction]]
        self.source_buffers[direction] \
            = processing_element.core.output_channel_buffers[reverse_direction_map[direction]]

    def connect_to_sender_channel_buffer(self, direction, sender_channel_buffer):
        """
        Connect the router to a buffer that emits packets.

        :param direction: direction from the current processing element to the buffer
        :param sender_channel_buffer: sending buffer
        """

        # Make sure we are connecting to the correct type of buffer.
        if not isinstance(sender_channel_buffer, SenderChannelBuffer):
            exception_string = f"Cannot connect a channel buffer interface to a {type(sender_channel_buffer)}."
            raise SimulatorException(exception_string)

        # The buffer is now one of our immediate sources.
        self.source_buffers[direction] = sender_channel_buffer

    def connect_to_receiver_channel_buffer(self, direction, receiver_channel_buffer):
        """
        Connect the router to a buffer that receives packets.

        :param direction: direction from the current processing element to the buffer
        :param receiver_channel_buffer: receiving buffer
        """

        # Make sure we are connecting to the correct type of buffer.
        if not isinstance(receiver_channel_buffer, ReceiverChannelBuffer):
            exception_string = f"Cannot connect a channel buffer interface to a {type(receiver_channel_buffer)}."
            raise SimulatorException(exception_string)

        # The buffer is now one of our immediate destinations.
        self.destination_buffers[direction] = receiver_channel_buffer

    def _register(self, system):
        """
        Register the router with the system event loop.

        :param system: the rest of the system
        """

        # Nothing to register
        pass

    def iterate(self, debug):
        """
        Perform a single cycle of execution.

        :param debug: whether to print out information about internal state
        """

        # Assume the router has nothing to route initially.
        active = False

        # Print a debug header.
        if debug:
            print(f"name: {self.core.name} Software Router")

        # Route all incoming packets to the appropriate input channel buffer.
        for i, source_buffer in enumerate(self.source_buffers):
            if source_buffer is not None:
                input_channel_direction = i
                input_channel_buffer = self.input_channel_buffers[input_channel_direction]
                if not input_channel_buffer.full and not source_buffer.empty:
                    packet = source_buffer.dequeue()
                    input_channel_buffer.enqueue(packet)
                    active = True
                    if debug:
                        direction = reverse_direction_map[i]
                        debug_string = f"Routed {packet} from source {i} {direction_name_map[direction]} to input " \
                                       + f"channel buffer {i}."
                        print(debug_string)

        # Route all output channel buffer packets to the appropriate destination.
        for i, destination_buffer in enumerate(self.destination_buffers):
            if destination_buffer is not None:
                output_channel_direction = i
                output_channel_buffer = self.output_channel_buffers[output_channel_direction]
                if not output_channel_buffer.empty and not destination_buffer.full:
                    packet = output_channel_buffer.dequeue()
                    destination_buffer.enqueue(packet)
                    active = True
                    if debug:
                        debug_string = f"Routed {packet} from output channel buffer {i} {direction_name_map[i]} to " \
                                       + f"destination {i}."
                        print(debug_string)

        # Handle the case where there is no activity, and also pad the debug output with vertical space.
        if debug:
            if not active:
                print("No activity.")
            print("")  # Output field separator.

    def reset(self):
        """
        Reset any internal state.
        """

        # This class of router has no internal state.
        pass


class SwitchRouter(Router):
    # Future release.
    pass

class VirtualCircuitRouter(Router):
    # Future release.
    pass


router_type_map = {RouterType.software: SoftwareRouter,
                   RouterType.switch: SwitchRouter,
                   RouterType.virtual_circuit: VirtualCircuitRouter}


router_type_name_type_map = {"software": RouterType.software,
                             "switch": RouterType.switch,
                             "virtual_circuit": RouterType.virtual_circuit}
