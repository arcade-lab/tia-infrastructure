"""
Classes and utilities for encapsulating physical constraints of target hardware.
"""

from parameters.exception import ParametrizationException


class SystemParameters:
    """
    Parameters for routers and interconnect links.
    """

    def __init__(self, host_word_width=None, num_test_data_memory_words=None, test_data_memory_buffer_depth=None):
        """
        Generic initializer for a SystemParameters instance.
        
        :param host_word_width: bus width for MMIO access via the host
        :param num_test_data_memory_words: size of the test data memory
        :param test_data_memory_buffer_depth: depth of the test data memory access buffers
        """

        # Initialize all the fields.
        self.host_word_width = host_word_width
        self.num_test_data_memory_words = num_test_data_memory_words
        self.test_data_memory_buffer_depth = test_data_memory_buffer_depth

    @classmethod
    def from_dictionary(cls, dictionary):
        """
        Instantiate a SystemParameters wrapper from a dictionary.

        :param dictionary: loaded from a configuration file or elsewhere
        :return: new SystemParameters instance
        """

        # Filter the dictionary with only parameters necessary for the initializer.
        key_filter_set = {"host_word_width",
                          "num_test_data_memory_words",
                          "test_data_memory_buffer_depth"}
        filtered_system_dictionary = {key: dictionary[key] for key in key_filter_set}

        # Unpack the dictionary into the initializer.
        return cls(**filtered_system_dictionary)