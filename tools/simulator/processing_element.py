"""
Processing elements and related utilities.
"""

from constants.direction import reverse_direction_map
from simulator.core import Core
from simulator.exception import SimulatorException
from simulator.router import router_type_map, router_type_name_type_map


class ProcessingElement:
    def __init__(self, name, cp, ip):
        """
        Initialize a processing element.
        
        :param name: an English name
        :param cp: a CoreParameters instance
        :param ip: an InterconnectParameters instance
        """

        # Initialize each component.
        self.name = name
        self.core = Core(name, cp)
        if ip.router_type not in router_type_name_type_map:
            raise SimulatorException("Unsupported router type.")
        self.router = router_type_map[router_type_name_type_map[ip.router_type]](ip, self.core)

    # --- Setup Methods ---

    def connect_to_sender_channel_buffer(self, direction, sender_channel_buffer):
        # Wrapper around router functionality.
        self.router.connect_to_sender_channel_buffer(direction, sender_channel_buffer)

    def connect_to_receiver_channel_buffer(self, direction, receiver_channel_buffer):
        # Wrapper around router functionality.
        self.router.connect_to_receiver_channel_buffer(direction, receiver_channel_buffer)

    # --- System Registration Method ---

    def _register(self, system):
        """
        Register the processing element with the system event loop.
        
        :param system: the rest of the system
        """

        # Register the processing element core and router and append ourselves to the main event loop.
        system.register(self.core)
        system.register(self.router)
        system.processing_elements.append(self)

    # --- Time-stepping Method ---

    def iterate(self, debug, keep_execution_trace):
        """
        Perform a single cycle of execution.

        :param debug: whether to print out information about internal state
        """

        # Run the two components.
        self.core.iterate(debug, keep_execution_trace)
        self.router.iterate(debug)

    # --- Reset Method ---

    def reset(self):
        """
        Reset the processing element.
        """

        # Reset the core and router.
        self.core.reset()
        self.router.reset()


def connect_processing_elements(processing_element_a, processing_element_b, direction_a_to_b):
    """
    Use the processing element router connection methods to conveniently connect two processing elements along an
    axis defined by direction_a_to_b.
    
    :param processing_element_a: the first processing element
    :param processing_element_b: the second processing element
    :param direction_a_to_b: the cardinal direction between processing elements a and b
    """

    # Connect in both directions.
    processing_element_a.router.connect_to_processing_element(direction_a_to_b, processing_element_b)
    processing_element_b.router.connect_to_processing_element(reverse_direction_map[direction_a_to_b],
                                                              processing_element_a)
