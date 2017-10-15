"""
Classes and utilities for encapsulating physical constraints of target hardware and simulator.
"""

import sys

import numpy as np

from assembly.instruction import Op, SourceType, DestinationType
from parameters.exception import ParametrizationException


class CoreParameters:
    """
    Parameters for the physical processing element core target of the assembler and simulator.
    """

    def __init__(self, architecture=None, device_word_width=None, immediate_width=None, mm_instruction_width=None,
                 num_instructions=None, num_predicates=None, num_registers=None, has_multiplier=None,
                 has_two_word_product_multiplier=None, has_scratchpad=None, num_scratchpad_words=None,
                 latch_based_instruction_memory=None, ram_based_immediate_storage=None, num_input_channels=None,
                 num_output_channels=None, channel_buffer_depth=None, max_num_input_channels_to_check=None,
                 num_tags=None, has_speculative_predicate_unit=None, has_effective_queue_status=None,
                 has_debug_monitor=None, has_performance_counters=None):
        """
        Generic initializer for a CoreParameters instance. Likely only to be used through alternative constructors.

        :param architecture: device type
        :param device_word_width: data word width for computation
        :param immediate_width: immediate width per instruction
        :param mm_instruction_width: number of memory mapped bits available for the instruction
        :param num_instructions: number of instructions available to be stored in the core
        :param num_predicates: number of predicate registers
        :param num_registers: number of general purpose data registers
        :param has_multiplier: whether we have an integer multiplier
        :param has_two_word_product_multiplier: whether we have a full high/low two-word product
        :param has_scratchpad: whether we have a private scratchpad memory
        :param num_scratchpad_words: number of words in the scratchpad memory
        :param latch_based_instruction_memory: whether to use latches for the instruction memory instead of flip-flops
        :param ram_based_immediate_storage: whether to use a small RAM to store the immediates of the instructions
        :param num_input_channels: number of channels coming from the interconnect into the core
        :param num_output_channels: number of channels going to the interconnect from the core
        :param channel_buffer_depth: depth of input and output channel buffers
        :param max_num_input_channels_to_check: how many channels and instruction can depend on in this architecture
        :param num_tags: number of different tag types supported by the architecture
        :param has_speculative_predicate_unit: whether to use speculation to keep the pipeline full
        :param has_effective_queue_status: whether to use detailed queue accounting
        :param has_debug_monitor: whether to include a debug monitor that can read predicate and register information
        :param has_performance_counters: whether to include performance counters
        """

        # Generic inializer.
        self.architecture = architecture
        self.device_word_width = device_word_width
        self.immediate_width = immediate_width
        self.mm_instruction_width = mm_instruction_width
        self.num_instructions = num_instructions
        self.num_predicates = num_predicates
        self.num_registers = num_registers
        self.has_multiplier = has_multiplier
        self.has_two_word_product_multiplier = has_two_word_product_multiplier
        self.has_scratchpad = has_scratchpad
        self.num_scratchpad_words = num_scratchpad_words
        self.latch_based_instruction_memory = latch_based_instruction_memory
        self.ram_based_immediate_storage = ram_based_immediate_storage
        self.num_input_channels = num_input_channels
        self.num_output_channels = num_output_channels
        self.channel_buffer_depth = channel_buffer_depth
        self.max_num_input_channels_to_check = max_num_input_channels_to_check
        self.num_tags = num_tags
        self.has_speculative_predicate_unit = has_speculative_predicate_unit
        self.has_effective_queue_status = has_effective_queue_status
        self.has_debug_monitor = has_debug_monitor
        self.has_performance_counters = has_performance_counters

    # --- Alternative Constructor ---

    @classmethod
    def from_dictionary(cls, dictionary):
        """
        Instantiate a CoreParameters wrapper from a dictionary.

        :param dictionary: loaded from a configuration file or elsewhere
        :return: new CoreParameters instance
        """

        # Filter the dictionary with only parameters necessary for the initializer.
        key_filter_set = {"architecture",
                          "device_word_width",
                          "immediate_width",
                          "mm_instruction_width",
                          "num_instructions",
                          "num_predicates",
                          "num_registers",
                          "has_multiplier",
                          "has_two_word_product_multiplier",
                          "has_scratchpad",
                          "num_scratchpad_words",
                          "latch_based_instruction_memory",
                          "ram_based_immediate_storage",
                          "num_input_channels",
                          "num_output_channels",
                          "channel_buffer_depth",
                          "max_num_input_channels_to_check",
                          "num_tags",
                          "has_speculative_predicate_unit",
                          "has_effective_queue_status",
                          "has_debug_monitor",
                          "has_performance_counters"}
        filtered_core_dictionary = {key: dictionary[key] for key in key_filter_set}

        # Unpack the dictionary into the initializer.
        return cls(**filtered_core_dictionary)

    # --- Check on the Validity of Properties ---

    def validate_instruction_format(self):
        """
        Raise an error if the architectural specification is incomplete and an attempt is made to access derived
        properties.
        """

        # Make sure all attributes are set.
        valid = True
        for key in self.__dict__:
            if self.__dict__[key] is None:
                valid = False
                break
        if not valid:
            print(self.__dict__, file=sys.stderr)
            exception_string = f"The parameter {key} must be nonnull."
            raise ParametrizationException(exception_string)

        # Get the total number of bits for output checking purposes.
        non_immediate_instruction_field_bit_counts = [1,  # vi.
                                                      self.ptm_width,
                                                      self.ici_width,
                                                      self.ictb_width,
                                                      self.ictv_width,
                                                      self.op_width,
                                                      self.st_width,
                                                      self.si_width,
                                                      self.dt_width,
                                                      self.di_width,
                                                      self.oci_width,
                                                      self.oct_width,
                                                      self.icd_width,
                                                      self.pum_width]
        non_immediate_instruction_width = sum(non_immediate_instruction_field_bit_counts)

        # Make sure the proposed instruction encoding can actually fit.
        used_instruction_code_space = non_immediate_instruction_width + self.immediate_width
        if used_instruction_code_space > self.mm_instruction_width:
            exception_string = f"The instruction with the given architectural parameters has a width of " \
                               + f"{used_instruction_code_space} bits and cannot fit within the defined " \
                               + f"memory-mapped  instruction width of {self.mm_instruction_width} bits."
            raise ParametrizationException(exception_string)
        if used_instruction_code_space > self.phy_instruction_width:
            exception_string = f"The instruction with the given architectural parameters has a width of " \
                               + f"{used_instruction_code_space} bits and cannot fit within the defined physical " \
                               + f"instruction width of {self.phy_instruction_width} bits."
            raise ParametrizationException(exception_string)

    # --- Derived Properties ---

    @property
    def true_ptm_width(self):
        return self.num_predicates

    @property
    def false_ptm_width(self):
        return self.num_predicates

    @property
    def ptm_width(self):
        return self.true_ptm_width + self.false_ptm_width

    @property
    def single_ici_width(self):
        return int(np.ceil(np.log2(self.num_input_channels + 1)))  # Extra slot for the implied null value.

    @property
    def ici_width(self):
        return self.max_num_input_channels_to_check * self.single_ici_width

    @property
    def tag_width(self):
        return int(np.ceil(np.log2(self.num_tags)))

    @property
    def ictb_width(self):
        return self.max_num_input_channels_to_check

    @property
    def ictv_width(self):
        return self.max_num_input_channels_to_check * self.tag_width

    @property
    def op_width(self):
        return int(np.ceil(np.log2(len(Op))))

    @property
    def single_st_width(self):
        return int(np.ceil(np.log2(len(SourceType))))  # SourceType already has an explicit null value.

    @property
    def st_width(self):
        return 3 * self.single_st_width

    @property
    def single_si_width(self):
        return int(np.ceil(np.log2(max(self.num_registers, self.num_input_channels))))

    @property
    def si_width(self):
        return 3 * self.single_si_width

    @property
    def dt_width(self):
        return int(np.ceil(np.log2(len(DestinationType))))  # DestinationType already has an explicit null value.

    @property
    def di_width(self):
        return int(np.ceil(np.log2(max(self.num_registers, self.num_output_channels, self.num_predicates))))

    @property
    def oci_width(self):
        return self.num_output_channels

    @property
    def oct_width(self):
        return self.tag_width

    @property
    def icd_width(self):
        return self.num_input_channels

    @property
    def true_pum_width(self):
        return self.true_ptm_width

    @property
    def false_pum_width(self):
        return self.false_ptm_width

    @property
    def pum_width(self):
        return self.true_pum_width + self.false_pum_width

    @property
    def non_immediate_instruction_width(self):
        non_immediate_instruction_widths = [1,  # vi.
                                            self.ptm_width,
                                            self.ici_width,
                                            self.ictb_width,
                                            self.ictv_width,
                                            self.op_width,
                                            self.st_width,
                                            self.si_width,
                                            self.dt_width,
                                            self.di_width,
                                            self.oci_width,
                                            self.oct_width,
                                            self.icd_width,
                                            self.pum_width]
        return sum(non_immediate_instruction_widths)

    @property
    def phy_instruction_width(self):
        return self.non_immediate_instruction_width + self.immediate_width

    @property
    def padding_width(self):
        return self.mm_instruction_width - self.phy_instruction_width
