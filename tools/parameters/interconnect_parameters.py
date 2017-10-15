"""
Classes and utilities for encapsulating physical constraints of target hardware.
"""

from parameters.exception import ParametrizationException


class InterconnectParameters:
    """
    Parameters for routers and interconnect links.
    """

    def __init__(self, router_type=None, num_router_sources=None, num_router_destinations=None, num_input_channels=None,
                 num_output_channels=None, router_buffer_depth=None, num_physical_planes=None):
        """
        Generic initializer for an InterconnectParameters instance.
        
        :param router_type: router type string
        :param num_router_sources: number of non-local sources
        :param num_router_destinations: number of non-local destinations
        :param num_input_channels: number of local connections going to the core
        :param num_output_channels: number of local connections coming from the core
        :param router_buffer_depth: depth of buffers internal to the router
        :param num_physical_planes: number of physical network planes in the interconnect
        """

        # Initialize all the fields.
        self.router_type = router_type
        self.num_router_sources = num_router_sources
        self.num_router_destinations = num_router_destinations
        self.num_input_channels = num_input_channels
        self.num_output_channels = num_output_channels
        self.router_buffer_depth = router_buffer_depth
        self.num_physical_planes = num_physical_planes

    @classmethod
    def from_dictionary(cls, dictionary):
        """
        Instantiate an InterconnectParameters wrapper from a dictionary.

        :param dictionary: loaded from a configuration file or elsewhere
        :return: new InterconnectParameters instance
        """

        # Filter the dictionary with only parameters necessary for the initializer.
        key_filter_set = {"router_type",
                          "num_router_sources",
                          "num_router_destinations",
                          "num_input_channels",
                          "num_output_channels",
                          "router_buffer_depth",
                          "num_physical_planes"}
        filtered_interconnect_dictionary = {key: dictionary[key] for key in key_filter_set}

        # Unpack the dictionary into the initializer.
        return cls(**filtered_interconnect_dictionary)