"""
Triggers, instructions and related utilities.
"""

from enum import IntEnum

import numpy as np

from assembly.exception import AssemblyException


# --- Operations ---

class Op(IntEnum):
    """
    All operations are word granularity for now. There is no attempt at overflow protection/trapping and thus unsigned
    operations are only noted as such out of necessity.
    """

    # Base ISA.
    nop = 0
    mov = 1
    add = 2
    sub = 3
    sl = 4
    asr = 5
    lsr = 6
    eq = 7
    ne = 8
    sgt = 9
    ugt = 10
    slt = 11
    ult = 12
    sge = 13
    uge = 14
    sle = 15
    ule = 16
    band = 17
    bnand = 18
    bor = 19
    bnor = 20
    bxor = 21
    bxnor = 22
    land = 23
    lnand = 24
    lor = 25
    lnor = 26
    lxor = 27
    lxnor = 28
    gby = 29  # Not yet implemented.
    sby = 30  # Not yet implemented.
    cby = 31  # Not yet implemented.
    mby = 32  # Not yet implemented.
    gb = 33
    sb = 34
    cb = 35
    mb = 36
    clz = 37
    ctz = 38
    halt = 39

    # Scratchpad extensions.
    lsw = 40
    ssw = 41

    # Load-store extensions.
    rlw = 42  # Not yet implemented.
    olw = 43  # Not yet implemented.
    sw = 44  # Not yet implemented.

    # Multiplication extensions.
    lmul = 45
    shmul = 46
    uhmul = 47
    mac = 48

    # Floating-point extensions.
    itf = 49  # Not yet implemented.
    utf = 50  # Not yet implemented.
    fti = 51  # Not yet implemented.
    ftu = 52  # Not yet implemented.
    feq = 53  # Not yet implemented.
    fne = 54  # Not yet implemented.
    fgt = 55  # Not yet implemented.
    flt = 56  # Not yet implemented.
    fle = 57  # Not yet implemented.
    fge = 58  # Not yet implemented.
    fadd = 59  # Not yet implemented.
    fsub = 60  # Not yet implemented.
    fmul = 61  # Not yet implemented.
    fmac = 62  # Not yet implemented.


# The operations below are just raw function declarations in the instruction namespace. Enumerated operations are mapped
# to these implementations as a simulation reference.

def nop(a, b, c):
    return np.uint32(0)


def mov(a, b, c):
    return np.uint32(a)


def add(a, b, c):
    return np.uint32(np.int32(a) + np.int32(b))


def sub(a, b, c):
    return np.uint32(np.int32(a) - np.int32(b))


def sl(a, b, c):
    return np.uint32(np.uint32(a) << np.uint32(b))


def asr(a, b, c):
    return np.uint32(np.int32(a) >> np.uint32(b))


def lsr(a, b, c):
    return np.uint32(np.uint32(a) >> np.uint32(b))


def eq(a, b, c):
    return np.uint32(np.uint32(a) == np.uint32(b))


def ne(a, b, c):
    return np.uint32(np.uint32(a) != np.uint32(b))


def sgt(a, b, c):
    return np.uint32(np.int32(a) > np.int32(b))


def ugt(a, b, c):
    return np.uint32(np.uint32(a) > np.uint32(b))


def slt(a, b, c):
    return np.uint32(np.int32(a) < np.int32(b))


def ult(a, b, c):
    return np.uint32(np.uint32(a) < np.uint32(b))


def sge(a, b, c):
    return np.uint32(np.int32(a) >= np.int32(b))


def uge(a, b, c):
    return np.uint32(np.uint32(a) >= np.uint32(b))


def sle(a, b, c):
    return np.uint32(np.int32(a) <= np.int32(b))


def ule(a, b, c):
    return np.uint32(np.uint32(a) <= np.uint32(b))


def band(a, b, c):
    return np.uint32(np.uint32(a) & np.uint32(b))


def bnand(a, b, c):
    return ~band(a, b)


def bor(a, b, c):
    return np.uint32(np.uint32(a) | np.uint32(b))


def bnor(a, b, c):
    return ~bor(a, b)


def bxor(a, b, c):
    return np.uint32(np.uint32(a) ^ np.uint32(b))


def bxnor(a, b, c):
    return ~bxor(a, b)


def land(a, b, c):
    return np.uint32(bool(a) & bool(b))


def lnand(a, b, c):
    return np.uint32(not land(a, b))


def lor(a, b, c):
    return np.uint32(bool(a) | bool(b))


def lnor(a, b, c):
    return np.uint32(not lor(a, b))


def lxor(a, b, c):
    return np.uint32(bool(a) ^ bool(b))


def lxnor(a, b, c):
    return np.uint32(not lxor(a, b))


def gb(a, b, c):
    return np.uint32((np.uint32(a) >> np.uint32(b)) & np.uint32(0x1))


def sb(a, b, c):
    if c == 0:
        mask = ~np.uint32(1 << np.uint32(b))
        return np.uint32(np.uint32(a) & mask)
    else:
        mask = np.uint32(1 << np.uint32(b))
        return np.uint32(np.uint32(a) | mask)


def cb(a, b, c):
    return np.uint32(np.uint32(a) & ~np.uint32(1 << np.uint32(b)))


def mb(a, b, c):
    return np.uint32(np.uint32(a) | np.uint32(1 << np.uint32(b)))


def clz(a, b, c):
    for i in reversed(range(32)):
        if (np.uint32(a) >> i) & 0x1 == 1:
            break
    else:
        i = 32
    if b:
        return np.uint32(i)
    else:
        return np.uint32(31 - i)


def ctz(a, b, c):
    for i in range(32):
        if (np.uint32(a) >> i) & 0x1 == 1:
            break
    else:
        i = 32
    if b:
        return np.uint32(i)
    else:
        return np.uint32(i)


def halt(a, b, c):
    return 0  # Implemented directly in the ProcessingElement instance.


def lsw(a, b, c):
    return 0  # Implemented directly in the ProcessingElement instance.


def ssw(a, b, c):
    return 0  # Implemented directly in the ProcessingElement instance.


def lmul(a, b, c):
    return np.uint32(np.uint64(np.uint32(a)) * np.uint64(np.uint32(b)))


def shmul(a, b, c):
    product = np.int64(np.int64(np.int32(a)) * np.int64(np.int32(b)))
    return np.uint32((int(product) >> 32) & 0xFFFFFFFF)


def uhmul(a, b, c):
    product = np.uint64(np.uint64(np.uint32(a)) * np.uint64(np.uint32(b)))
    return np.uint32((int(product) >> 32) & 0xFFFFFFFF)


def mac(a, b, c):
    product = np.int64(np.int64(np.int32(b)) * np.int64(np.int32(c)))
    return np.uint32((np.int64(np.int32(a)) + product) & 0xFFFFFFFF)


# The dictionary to perform the mapping between op type and implementation.
op_implementation_map = {Op.nop: nop,
                         Op.mov: mov,
                         Op.add: add,
                         Op.sub: sub,
                         Op.sl: sl,
                         Op.asr: asr,
                         Op.lsr: lsr,
                         Op.eq: eq,
                         Op.ne: ne,
                         Op.sgt: sgt,
                         Op.ugt: ugt,
                         Op.slt: slt,
                         Op.ult: ult,
                         Op.sge: sge,
                         Op.uge: uge,
                         Op.sle: sle,
                         Op.ule: ule,
                         Op.band: band,
                         Op.bor: bor,
                         Op.bxor: bxor,
                         Op.land: land,
                         Op.lor: lor,
                         Op.lxor: lxor,
                         Op.gb: gb,
                         Op.sb: sb,
                         Op.cb: cb,
                         Op.mb: mb,
                         Op.clz: clz,
                         Op.ctz: ctz,
                         Op.halt: halt,
                         Op.lsw: lsw,
                         Op.ssw: ssw,
                         Op.lmul: lmul,
                         Op.shmul: shmul,
                         Op.uhmul: uhmul,
                         Op.mac: mac}


# --- Trigger ---

class Trigger:
    """
    Trigger. Used as the front-end scheduling apparatus for instructions and as such is an attribute of the Instruction
    class. Contains a variety of static methods used in the parsing of trigger statements in assembly instructions.
    """

    def __init__(self, true_predicates=None, false_predicates=None, input_channels=None, input_channel_tags=None,
                 input_channel_tag_booleans=None, output_channel_indices=None):
        """
        Generic initializer for a Trigger instance.

        :param true_predicates: predicates that must be set to true to trigger an instruction
        :param false_predicates: predicates that must be set to false to trigger an instruction
        :param input_channels: input channels that must not be empty to trigger an instruction
        :param input_channel_tags: tag values that either must or must not be present on input channels to trigger an
                                   instruction
        :param input_channel_tag_booleans: Booleans which specify whether a tag must or must not be equal to a tag given
                                           in input_channel_tags
        :param output_channel_indices: the output channels which must not be full to tirgger an instruction
        """

        # Setting attributes according to keyword arguments.
        if true_predicates is None:
            self.true_predicates = []
        else:
            self.true_predicates = true_predicates
        if false_predicates is None:
            self.false_predicates = []
        else:
            self.false_predicates = false_predicates
        if input_channels is None:
            self.input_channels = []
        else:
            self.input_channels = input_channels
        if input_channel_tags is None:
            self.input_channel_tags = []
        else:
            self.input_channel_tags = input_channel_tags
        if input_channel_tag_booleans is None:
            self.input_channel_tag_booleans = []
        else:
            self.input_channel_tag_booleans = input_channel_tag_booleans
        if output_channel_indices is None:
            self.output_channel_indices = []
        else:
            self.output_channel_indices = output_channel_indices

    # --- Instruction Parsing and Building Methods ---

    def add_predicate_conditions_from_bin_string(self, predicate_bin_string):
        """
        Set the true and false predicates required for a trigger to be valid.

        :param predicate_bin_string: the (0, 1, X)-valued sensitivity string
        """

        # Fill in the fields using the class method.
        self.true_predicates, self.false_predicates = Trigger.parse_predicate_bin_string(predicate_bin_string)

    def add_predicate_conditions_from_string(self, predicate_string):
        """
        Set the predictate conditions based on a complete predicate condition statement.

        :param predicate_string: predicate condition statement
        """

        # Fill in the field using the class method.
        predicate_bin_string = Trigger.extract_predicate_bin_string(predicate_string)
        self.add_predicate_conditions_from_bin_string(predicate_bin_string)

    def add_input_channels_conditions_from_string(self, input_channel_string):
        """
        Set the input channel tags and Booleans based on a with substatement.

        :param input_channel_string: the required input channel conditions in string form
        """

        # Fill in the fields using the class methods.
        input_channel_tokens = Trigger.tokenize_input_channel_string(input_channel_string)
        self.input_channels += Trigger.extract_input_channels(input_channel_tokens)
        self.input_channel_tags += Trigger.extract_input_channel_tags(input_channel_tokens)
        self.input_channel_tag_booleans += Trigger.extract_input_channel_tag_booleans(input_channel_tokens)

    # --- Static Methods for Parsing ---

    @staticmethod
    def extract_predicate_bin_string(predicate_string):
        """
        Given a "%p == 0XX1010X"-type expression, extract the binary string segment.

        :param predicate_string: expression to parse
        :return: binary string
        """

        # Make sure the predicate string is well formed before returing the contents of the string.
        if predicate_string.split("==")[0].strip() != "%p":
            raise AssemblyException("Expected predicate condition to be of the form \"%p == [binary string]\".")
        return predicate_string.split("==")[1].strip()

    @staticmethod
    def parse_predicate_bin_string(predicate_bin_string):
        """
        Determine the true and false predicate lists from a binary/dont-care expression.

        :param predicate_bin_string: a binary string input, e.g., "100XX01"
        :return: a tuple of the true predicate list and the false predicate list
        """

        # Both lists are initially empty.
        true_predicates = []
        false_predicates = []

        # Parse each character in the reversed binary/don't-care string, and update the lists accordingly.
        for i, c in enumerate(predicate_bin_string[::-1]):
            if c.isalpha():
                if c == 'X' or c == 'x':
                    continue
                else:
                    exception_string = f"Encountered an invalid character in predicate condition string: {c}"
                    raise AssemblyException(exception_string)
            else:
                if c == '0':
                    false_predicates.append(i)
                elif c == '1':
                    true_predicates.append(i)
                else:
                    exception_string = f"Encountered an invalid character in predicate condition string: {c}"
                    raise AssemblyException(exception_string)

        # Return the completed lists.
        return true_predicates, false_predicates

    @staticmethod
    def tokenize_input_channel_string(input_channel_string):
        """
        Given a "!%i1.tag0, %i6.tag1..." input string, return a list of tokens.

        :param input_channel_string: input channel expression
        :return: list of tokens
        """

        # Get the raw tokens and remove any extraneous whitespace.
        raw_comma_separated_tokens = input_channel_string.split(",")
        for i, raw_token in enumerate(raw_comma_separated_tokens):
            raw_comma_separated_tokens[i] = raw_token.strip()

        # Build the list of input channel tokens (assuming comma separation).
        input_channel_tokens = []
        for raw_token in raw_comma_separated_tokens:
            if raw_token == "":
                continue
            if raw_token.startswith("%i") or raw_token.startswith("!%i"):
                input_channel_tokens.append(raw_token)
            else:
                exception_string = f"{raw_token} is not a valid input channel condition."
                raise AssemblyException(exception_string)

        # Return the completed list of tokens.
        return input_channel_tokens

    @staticmethod
    def extract_input_channels(input_channel_tokens):
        """
        Given a "!%i1.tag0, %i6.tag1..." input string that has been tokenized, extract the channel indices for each
        channel.

        :param input_channel_tokens: tokenized input channels expression
        :return: a list of input channel indices
        """

        # Select the relevant characters from each token, and convert them to integers.
        input_channels = []
        for token in input_channel_tokens:
            input_channel = token.split('.')[0].split('!')[-1]
            input_channel_index = int(input_channel[2:])
            input_channels.append(input_channel_index)

        # Return the completed list of input channels.
        return input_channels

    @staticmethod
    def extract_input_channel_tags(input_channel_tokens):
        """
        Given a "!%i1.tag0, %i6.tag1..." input string that has been tokenized, extract the tags for each channel and
        evaluate them.

        :param input_channel_tokens: tokenized input channels expression
        :return: a list of tag objects
        """

        # Select the relevant tag characters from each token, and evaluate them as tag objects.
        input_channel_tags = []
        for token in input_channel_tokens:
            tag = token.split('.')[1]
            input_channel_tags.append(int(tag))

        # Return the completed list of input channel tags.
        return input_channel_tags

    @staticmethod
    def extract_input_channel_tag_booleans(input_channel_tokens):
        """
        Given a "!%i1.tag0, %i6.tag1..." input string that has been tokenized, extract the Boolean values.

        :param input_channel_tokens:
        :return: a list of booleans
        """

        # Check for Boolean negation '!' characters at the beginning of each tag.
        input_channel_tag_booleans = []
        for token in input_channel_tokens:
            if token.startswith('!'):
                input_channel_tag_booleans.append(False)
            else:
                input_channel_tag_booleans.append(True)

        # Return the completed list of input channel tag Booleans.
        return input_channel_tag_booleans


# --- Instruction ---

class SourceType(IntEnum):
    """
    Immediate, channel, data register or null.
    """

    # For binary encoding.
    null = 0
    immediate = 1
    channel = 2
    register = 3


class DestinationType(IntEnum):
    """
    Channel, data register, predicate or null.
    """

    # For binary encoding.
    null = 0
    channel = 1
    register = 2
    predicate = 3


class Instruction:
    """
    Instruction. Used to encapsulate trigger conditions, datapath operations and internal and external state updates.
    Used in both functional simulation and in the assembler. Contains a variety of static methods used in the parsing of
    assembly instructions.
    """

    def __init__(self, trigger=None, op=None, source_types=None, source_indices=None, immediate=None,
                 destination_type=None, destination_index=None, output_channel_tag=None, output_channel_indices=None,
                 input_channels_to_dequeue=None, predicate_update_indices=None, predicate_update_values=None,
                 number=None):
        """
        Generic initializer for an Instruction instance.

        :param trigger: Trigger instance for the instruction trigger
        :param op: enumerated Op type for datapath operation
        :param source_types: list of enumerated SourceTypes
        :param source_indices: list of source indices
        :param immediate: immediate value
        :param destination_type: enumerated DestinationType
        :param destination_index: destination index
        :param output_channel_indices: index list of output channels
        :param output_channel_tag: the tag with which to enqueue an operation result if the destination is a channel
        :param input_channels_to_dequeue: list of input channels to dequeue when the instruction is triggered
        :param predicate_update_indices: indices of predicates to update
        :param predicate_update_values: values with which to update those predicates
        :param number: used in the assembler for informative error messages
        """

        # Setting attributes according to keyword arguments.
        self.trigger = trigger
        self.op = op
        if source_types is None:
            self.source_types = []
        else:
            self.source_types = source_types
        if source_indices is None:
            self.source_indices = []
        else:
            self.source_indices = source_indices
        self.immediate = immediate
        self.destination_type = destination_type
        self.destination_index = destination_index
        if output_channel_indices is None:
            self.output_channel_indices = []
        else:
            self.output_channel_indices = output_channel_indices
        self.output_channel_tag = output_channel_tag
        if input_channels_to_dequeue is None:
            self.input_channels_to_dequeue = []
        else:
            self.input_channels_to_dequeue = input_channels_to_dequeue
        if predicate_update_indices is None:
            self.predicate_update_indices = []
        else:
            self.predicate_update_indices = predicate_update_indices
        if predicate_update_values is None:
            self.predicate_update_values = []
        else:
            self.predicate_update_values = predicate_update_values
        self.number = number

    # --- Alternative Constructor ---

    @classmethod
    def from_string(cls, instruction_string):
        """
        Instantiate a new instruction from an assembly string of the form:

        when %p == [predicate binary string] with [input channels and their tags]:
            [op] [dest], [source 0], [source 1]; deq [input channels to dequeue]; set %p = [predicate binary string];

        :param instruction_string: string to parse
        :return: an initialized instruction
        """

        # Modify an empty instruction by using add_*() methods on the various instruction fields.
        instruction = Instruction()
        instruction_fields = InstructionFields.from_instruction_string(instruction_string)
        trigger = Trigger()
        trigger.add_predicate_conditions_from_string(instruction_fields.trigger_predicate_conditions_string)
        if instruction_fields.trigger_input_channel_conditions_string is not None:
            trigger.add_input_channels_conditions_from_string(instruction_fields.trigger_input_channel_conditions_string)
        instruction.trigger = trigger
        instruction.add_datapath_instruction_from_string(instruction_fields.datapath_instruction_string)
        if instruction_fields.dequeue_input_channels_string is not None:
            instruction.add_dequeue_input_channels_from_string(instruction_fields.dequeue_input_channels_string)
        if instruction_fields.predicate_update_string is not None:
            instruction.add_predicate_updates_from_strings(instruction_fields.trigger_predicate_conditions_string,
                                                           instruction_fields.predicate_update_string)

        # Return the initialized instruction.
        return instruction

    # --- Instruction Parsing and Building Methods ---

    def add_datapath_instruction_from_string(self, datapath_string):
        """
        Add datapath operation information to an instruction based on an "[op] [dest], [source 0], [source 1]" string.

        :param datapath_string: datapath instruction string
        """

        # Tokenize the input string.
        datapath_tokens = Instruction.tokenize_datapath_string(datapath_string)

        # Determine the operation.
        self.op = Instruction.extract_op(datapath_tokens)

        # Handle different numbers of sources and destinations.
        num_tokens = len(datapath_tokens)
        if num_tokens == 1:
            self.source_types = [SourceType.null, SourceType.null, SourceType.null]
            self.source_indices = [0, 0, 0]
        elif num_tokens == 2:
            self.source_types = [SourceType.null, SourceType.null, SourceType.null]
            self.source_indices = [0, 0, 0]
        elif num_tokens == 3:
            if self.op == Op.ssw:
                self.source_types.append(Instruction.extract_special_sw_source_type(datapath_tokens))
                if self.source_types[0] == SourceType.immediate:
                    self.source_indices.append(0)
                    self.immediate = Instruction.extract_special_sw_immediate(datapath_tokens)
                else:
                    self.source_indices.append(Instruction.extract_special_sw_source_index(datapath_tokens))
                self.source_types.append(Instruction.extract_source_type(datapath_tokens, 0))
                if self.source_types[1] == SourceType.immediate:
                    self.source_indices.append(0)
                    self.immediate = Instruction.extract_immediate(datapath_tokens, 0)
                else:
                    self.source_indices.append(Instruction.extract_source_index(datapath_tokens, 0))
            else:
                self.source_types.append(Instruction.extract_source_type(datapath_tokens, 0))
                self.source_types.append(SourceType.null)
                if self.source_types[0] == SourceType.immediate:
                    self.source_indices.append(0)
                    self.immediate = Instruction.extract_immediate(datapath_tokens, 0)
                else:
                    self.source_indices.append(Instruction.extract_source_index(datapath_tokens, 0))
                self.source_indices.append(0)  # Arbitrary index.
            self.source_types.append(SourceType.null)
            self.source_indices.append(0)
        elif num_tokens == 4:
            self.source_types.append(Instruction.extract_source_type(datapath_tokens, 0))
            if self.source_types[0] == SourceType.immediate:
                self.source_indices.append(0)
                self.immediate = Instruction.extract_immediate(datapath_tokens, 0)
            else:
                self.source_indices.append(Instruction.extract_source_index(datapath_tokens, 0))
            self.source_types.append(Instruction.extract_source_type(datapath_tokens, 1))
            if self.source_types[1] == SourceType.immediate:
                self.source_indices.append(0)
                self.immediate = Instruction.extract_immediate(datapath_tokens, 1)
            else:
                self.source_indices.append(Instruction.extract_source_index(datapath_tokens, 1))
            self.source_types.append(SourceType.null)
            self.source_indices.append(0)
        elif num_tokens == 5:
            self.source_types.append(Instruction.extract_source_type(datapath_tokens, 0))
            if self.source_types[0] == SourceType.immediate:
                self.source_indices.append(0)
                self.immediate = Instruction.extract_immediate(datapath_tokens, 0)
            else:
                self.source_indices.append(Instruction.extract_source_index(datapath_tokens, 0))
            self.source_types.append(Instruction.extract_source_type(datapath_tokens, 1))
            if self.source_types[1] == SourceType.immediate:
                self.source_indices.append(0)
                self.immediate = Instruction.extract_immediate(datapath_tokens, 1)
            else:
                self.source_indices.append(Instruction.extract_source_index(datapath_tokens, 1))
            self.source_types.append(Instruction.extract_source_type(datapath_tokens, 2))
            if self.source_types[2] == SourceType.immediate:
                self.source_indices.append(0)
                self.immediate = Instruction.extract_immediate(datapath_tokens, 2)
            else:
                self.source_indices.append(Instruction.extract_source_index(datapath_tokens, 2))
        else:
            raise AssemblyException("Illegal number of datapath tokens.")

        # Determine destination information for instructions with destinations, and update the trigger.
        if num_tokens > 1 and self.op != Op.ssw:
            self.destination_type = Instruction.extract_destination_type(datapath_tokens)
            if self.destination_type == DestinationType.channel:
                if self.trigger is not None:
                    if Instruction.destination_has_multiple_output_channels(datapath_tokens):
                        self.destination_index = 0
                        self.trigger.output_channel_indices = Instruction.extract_destination_indices(datapath_tokens)
                        self.output_channel_indices = self.trigger.output_channel_indices
                    else:
                        self.destination_index = Instruction.extract_destination_index(datapath_tokens)
                        self.trigger.output_channel_indices = [self.destination_index]
                        self.output_channel_indices = self.trigger.output_channel_indices
                else:
                    raise AssemblyException("Instructions with datapaths that affect channels require their triggers "
                                            + "to be instantiated before processing their datapath operations.")
                self.output_channel_tag = Instruction.extract_destination_tag(datapath_tokens)
            else:
                self.destination_index = Instruction.extract_destination_index(datapath_tokens)
        else:
            self.destination_type = DestinationType.null
            self.destination_index = None

    def add_dequeue_input_channels_from_string(self, dequeue_input_channels_string):
        """
        Add the channels to dequeue to an instruction based on a "deq [channel to dequeue], [another] ..." string.

        :param dequeue_input_channels_string: dequeue expression
        """

        # For each token extract the relevant chanel index.
        dequeue_input_channels = []
        tokens = Instruction.tokenize_dequeue_input_channels_string(dequeue_input_channels_string)
        for token in tokens[1:]:
            input_channel = token.split(',')[0]
            if not input_channel.startswith("%i"):
                exception_string = f"Invalid argument in dequeue statement: {input_channel}."
                raise(exception_string)
            input_channel_index = int(input_channel[2:])
            dequeue_input_channels.append(input_channel_index)

        # Add the channels that need to be dequeued.
        self.input_channels_to_dequeue += dequeue_input_channels

    def add_predicate_updates_from_bin_strings(self, original_predicate_bin_string, desired_predicate_bin_string):
        """
        Add predicate update information to an instruction using the original and desired predicate strings.

        :param original_predicate_bin_string: original predicate state as a binary string
        :param desired_predicate_bin_string: desired predicate state as a binary string
        """

        # Add predicate update information.
        self.predicate_update_indices, self.predicate_update_values = \
            Instruction.determine_predicates_to_update(original_predicate_bin_string, desired_predicate_bin_string)

    def add_predicate_updates_from_strings(self, trigger_predicate_string, update_predicate_string):
        """
        Using a conditional "%p == [binary string]" and an assignment "%p = [binary string]" note which predicates must
        be updated in an instruction.

        :param trigger_predicate_string: trigger condition string
        :param update_predicate_string: predicate assignment string
        """

        # Extract the binary strings and recompute with them.
        trigger_predicate_bin_string = Trigger.extract_predicate_bin_string(trigger_predicate_string)
        update_predicate_bin_string = Instruction.extract_predicate_bin_string(update_predicate_string)
        self.add_predicate_updates_from_bin_strings(trigger_predicate_bin_string, update_predicate_bin_string)

    # --- Static Methods for Parsing ---

    @staticmethod
    def extract_predicate_bin_string(predicate_string):
        """
        Given a "set %p = 0XX1010X"-type expression, extract the binary string segment.

        :param predicate_string: expression to parse
        :return: binary string
        """

        # Check syntax and remove the set operator.
        if not predicate_string.strip().startswith("set"):
            raise AssemblyException("Expected predicate update to be of the form \"set %p = [binary string]\".")
        predicate_string = predicate_string.strip()[3:]
        if predicate_string.split("=")[0].strip() != "%p" or "==" in predicate_string:
            raise AssemblyException("Expected predicate update to be of the form \"set %p = [binary string]\".")

        # Return the RHS of the assignment.
        return predicate_string.split("=")[1].strip()

    @staticmethod
    def parse_predicate_bin_string(predicate_bin_string):
        """
        Determine the true and false predicate lists from a binary/dont-care expression.

        :param predicate_bin_string: a binary string input, e.g., "100XX01"
        :return: a tuple of the true predicate list and the false predicate list
        """

        # Both lists are initially empty.
        true_predicates = []
        false_predicates = []

        # Parse each character in the reversed binary/don't-care string, and update the lists accordingly.
        for i, c in enumerate(predicate_bin_string[::-1]):
            if c.isalpha():
                if c == 'X' or c == 'x' or c == 'Z' or c == 'z':
                    continue
                else:
                    exception_string = f"Predicate binary strings may only contain 0, 1, X or Z, not {c}."
                    raise AssemblyException(exception_string)
            else:
                if c == '0':
                    false_predicates.append(i)
                elif c == '1':
                    true_predicates.append(i)
                else:
                    exception_string = f"Predicate binary strings may only contain 0, 1 X or Z not {c}."
                    raise AssemblyException(exception_string)

        # Return the completed lists.
        return true_predicates, false_predicates

    @staticmethod
    def tokenize_datapath_string(datapath_string):
        """
        Retrieve datapath tokens from a datapath string.

        :param datapath_string: datapath string with terminating ';' removed (e.g., mov %i5.tag $100, etc.)
        :return: list of tokens
        """

        # Determine if there is a high-fanout instruction.
        multiple_output_channels = False
        if '{' in datapath_string:
            if '}' in datapath_string:
                multiple_output_channels = True
            else:
                raise AssemblyException("Unexpected character '{'.")

        # Get the raw tokens and remove any extraneous whitespace.
        raw_comma_separated_tokens = datapath_string.split(",")
        for i, raw_token in enumerate(raw_comma_separated_tokens):
            raw_comma_separated_tokens[i] = raw_token.strip()

        # Reassemble the multiple output channel token if needed.
        if multiple_output_channels:
            reassembled_raw_comma_separated_tokens = []
            token_reassembled = False
            acc = None
            for i, raw_token in enumerate(raw_comma_separated_tokens):
                if not token_reassembled:
                    if acc is None:
                        if '{' in raw_token:
                            if i != 0:
                                raise AssemblyException("'{...}' syntax is reserved for the destination.")
                            acc = raw_token
                        else:
                            reassembled_raw_comma_separated_tokens.append(raw_token)
                    else:
                        acc += ',' + raw_token
                        if '{' in acc and '}' in acc:
                            if acc.index('{') < acc.index('}'):
                                reassembled_raw_comma_separated_tokens.append(acc)
                                token_reassembled = True
                                acc = None
                            else:
                                raise AssemblyException("The multiple output channel index field must be "
                                                        + "'%o{x, y, z}.tag'.")
                else:
                    reassembled_raw_comma_separated_tokens.append(raw_token)
            raw_comma_separated_tokens = reassembled_raw_comma_separated_tokens

        # Make sure there is an operation expression.
        if " " not in raw_comma_separated_tokens[0]:
            AssemblyException("The operation and destination must be space separated.")

        # Separate the operator and rebuild the token list.
        raw_space_separated_tokens = raw_comma_separated_tokens[0].split(" ")
        if len(raw_space_separated_tokens) > 2:
            exception_string = f"Missing comma in datapath instruction: {datapath_string}"
            raise AssemblyException(exception_string)
        raw_space_separated_tokens += raw_comma_separated_tokens[1:]
        for raw_token in raw_space_separated_tokens:
            if " " in raw_token:
                exception_string = f"Expected a comma in the datapath statement between these two tokens: {raw_token}."
                AssemblyException(exception_string)

        # Separate the operation token from the rest, and make sure the datapath tokens are all sensible.
        op_token = raw_space_separated_tokens[0]
        raw_destination_and_source_tokens = raw_space_separated_tokens[1:]
        for raw_token in raw_destination_and_source_tokens:
            if not raw_token.startswith("%") and not raw_token.startswith("$"):
                exception_string = f"{raw_token} is not a valid datapath token."
                raise AssemblyException(exception_string)
        destination_and_source_tokens = raw_destination_and_source_tokens

        # Return the reassembled tokens.
        return [op_token] + destination_and_source_tokens

    @staticmethod
    def extract_op(datapath_tokens):
        """
        Extract the op from a traditional datapath instruction.

        :param datapath_tokens: datapath instruction tokens
        :return: the operation object associated with it
        """

        # Select the operation from the tokenized input.
        op_token = datapath_tokens[0]

        # Attempt to look up the operation.
        try:
            op = eval(f"Op.{op_token}")
        except AttributeError:
            exception_string = f"Unrecognized instruction: {op_token}"
            raise AssemblyException(exception_string)

        # Return the operation type.
        return op

    @staticmethod
    def extract_special_sw_source_type(datapath_tokens):
        """
        Extract the first source type for an sw instruction.

        :param datapath_tokens: datapath instruction tokens
        :return: the extracted source type
        """

        # Isolate the source term.
        source_token = datapath_tokens[1]

        # Use syntax hints to determine the type, and return it.
        if source_token.startswith('$'):
            return SourceType.immediate
        elif source_token.startswith("%i"):
            return SourceType.channel
        elif source_token.startswith("%r"):
            return SourceType.register
        else:
            exception_string = f"Unrecognized special source token {source_token} for an sw instruction."
            raise AssemblyException(exception_string)

    @staticmethod
    def extract_source_type(datapath_tokens, source_number):
        """
        Extract the source type for a given source.

        :param datapath_tokens: datapath instruction tokens
        :param source_number: which source to work on
        :return: the extracted source type
        """

        # Isolate the source term.
        source_token = datapath_tokens[source_number + 2]
        # Use syntax hints to determine the type, and return it.
        if source_token.startswith('$'):
            return SourceType.immediate
        elif source_token.startswith("%i"):
            return SourceType.channel
        elif source_token.startswith("%r"):
            return SourceType.register
        else:
            exception_string = f"Unrecognized source token: {source_token}."
            raise AssemblyException(exception_string)

    @staticmethod
    def extract_special_sw_source_index(datapath_tokens):
        """
        Extract the first source index for an sw instruction.

        :param datapath_tokens: datapath instruction tokens
        :return: the extracted source index
        """

        # Isolate the source term.
        source_token = datapath_tokens[1]

        # Check the source token's validity.
        if len(source_token) < 3 or not source_token.startswith('%'):
            exception_string = f"Unrecognized source token: {source_token}."
            raise AssemblyException(exception_string)

        # Attempt to convert the index to an integer.
        try:
            source_index = int(source_token[2:])
        except ValueError:
            exception_string = f"Unrecognized source token: {source_token}."
            raise AssemblyException(exception_string)

        # Return the source index.
        return source_index

    @staticmethod
    def extract_source_index(datapath_tokens, source_number):
        """
        Determine the source index for a given source.

        :param datapath_tokens: datapath instruction tokens
        :param source_number: which source to work on
        :return: the extracted source index
        """

        # Isolate the source term.
        source_token = datapath_tokens[source_number + 2]

        # Check the source token's validity.
        if len(source_token) < 3 or not source_token.startswith('%'):
            exception_string = f"Unrecognized source token: {source_token}."
            raise AssemblyException(exception_string)

        # Attempt to convert the index to an integer.
        try:
            source_index = int(source_token[2:])
        except ValueError:
            exception_string = f"Unrecognized source token: {source_token}."
            raise AssemblyException(exception_string)

        # Return the source index.
        return source_index

    @staticmethod
    def extract_special_sw_immediate(datapath_tokens):
        """
        Determine the immediate value of the first source.

        :param datapath_tokens: datapath instruction tokens
        :return: the extracted immediate.
        """

        # Isolate the immediate source term.
        source_token = datapath_tokens[1]

        # Check the immediate source token's validity.
        if len(source_token) < 2 or not source_token.startswith('$'):
            exception_string = f"{source_token} is not a valid source."
            raise AssemblyException(exception_string)

        # Attempt to convert the immediate to an integer.
        try:
            immediate = int(source_token[1:])
        except ValueError:
            try:
                immediate = int(source_token[1:], base=16)
            except ValueError:
                exception_string = f"{source_token} is not a valid source."
                raise AssemblyException(exception_string)

        # Return the immediate.
        return immediate

    @staticmethod
    def extract_immediate(datapath_tokens, source_number):
        """
        Determine immediate value a source represents.

        :param datapath_tokens: datapath instruction tokens
        :param source_number: which source to work on
        :return: the extracted immediate
        """

        # Isolate the immedate source term.
        source_token = datapath_tokens[source_number + 2]

        # Check the immediate source token's validity.
        if len(source_token) < 2 or not source_token.startswith('$'):
            exception_string = f"{source_token} is not a valid source."
            raise AssemblyException(exception_string)

        # Attempt to convert the immediate to an integer.
        try:
            immediate = int(source_token[1:])
        except ValueError:
            try:
                immediate = int(source_token[1:], base=16)
            except ValueError:
                exception_string = f"{source_token} is not a valid source."
                raise AssemblyException(exception_string)

        # Return the immediate.
        return immediate

    @staticmethod
    def destination_has_multiple_output_channels(datapath_tokens):
        """
        Determine whether the destination token has multiple output channel syntax.

        :param datapath_tokens: datapath instruction tokens
        :return: Boolean result
        """

        # Isolate the destination term.
        destination_token = datapath_tokens[1]

        # Characterize the destination token.
        if destination_token.startswith("%o"):
            if '{' in destination_token and '}' in destination_token:
                return True
        return False

    @staticmethod
    def extract_destination_type(datapath_tokens):
        """
        Determine the destination type. (The token is always assumed to be the first term of a datapath instruction.)

        :param datapath_tokens: datapath instruction tokens
        :return: the extracted destination type
        """

        # Isolate the destination term.
        destination_token = datapath_tokens[1]

        # Determine the destination type.
        if destination_token.startswith("%o"):
            return DestinationType.channel
        elif destination_token.startswith("%r"):
            return DestinationType.register
        elif destination_token.startswith("%p"):
            return DestinationType.predicate
        else:
            exception_string = f"Unrecognized destination token: {destination_token}."
            raise AssemblyException(exception_string)

    @staticmethod
    def extract_destination_index(datapath_tokens):
        """
        Determine the destination index. (The token is always assumed to be the first term of a datapath instruction.)

        :param datapath_tokens: datapath instruction tokens
        :return: the extracted destination index
        """

        # Isolate the destination token.
        destination_token = datapath_tokens[1]

        # Strip away the tag.
        destination = destination_token.split('.')[0]

        # Check the destination token's validity.
        if len(destination) < 3 or not destination.startswith('%'):
            exception_string = f"{destination_token} is not a valid destination."
            raise AssemblyException(exception_string)

        # Attempt to convert the destination index into an integer.
        try:
            destination_index = int(destination[2:])
        except ValueError:
            exception_string = f"{destination} is not a valid destination."
            raise AssemblyException(exception_string)

        # Return the destination index.
        return destination_index

    @staticmethod
    def extract_destination_indices(datapath_tokens):
        """
        Build a list of destination indices (presumably to be used with a multiple-output-channel destination).

        :param datapath_tokens: datapath instruction tokens
        :return: list of numerical indices
        """

        # Check syntax.
        for i, token in enumerate(datapath_tokens):
            if '{' in token or '}' in token:
                if i != 1:
                    raise AssemblyException("'{...}' index syntax is reserved for the destination.")

        # Isolate the destination token.
        destination_token = datapath_tokens[1]

        # Determine the numerical values for the destination indices.
        indices_string = destination_token.split('{')[1].split('}')[0]
        indices_list = []
        for index_string in indices_string.split(","):
            try:
                indices_list.append(int(index_string))
            except ValueError:
                exception_string = f"{index_string} is not a valid index."
                raise AssemblyException(exception_string)

        # Make sure the indices are unique.
        if len(set(indices_list)) != len(indices_list):
            raise AssemblyException("The indices in a high-fan-out instruction must be unique.")

        # Return the completed list.
        return indices_list

    @staticmethod
    def extract_destination_tag(datapath_tokens):
        """
        Determine the destination tag. (The token is always assumed to be the first term of a datapath instruction.)

        :param datapath_tokens: datapath instruction tokens
        :return: the extracted destination tag
        """

        # Isolate the token.
        destination_token = datapath_tokens[1]

        # Check that there is a tag.
        if len(destination_token.split('.')) != 2:
            exception_string = f"The channel destination {destination_token} must have a tag."
            raise AssemblyException(exception_string)

        # Extract the tag.
        tag = destination_token.split('.')[1]

        # Convert to an integer and return.
        return int(tag)

    @staticmethod
    def tokenize_dequeue_input_channels_string(dequeue_input_channels_string):
        """
        Retrieve datapath tokens from a datapath string.

        :param dequeue_input_channels_string: datapath string with terminating ';' removed (e.g., deq mov %i5.tag $100,
                                              etc.)
        :return: list of tokens
        """

        # Get the raw tokens and remove any extraneous whitespace.
        raw_comma_separated_tokens = dequeue_input_channels_string.split(",")
        for i, raw_token in enumerate(raw_comma_separated_tokens):
            raw_comma_separated_tokens[i] = raw_token.strip()

        # Make sure there is a dequeue expression.
        if " " not in raw_comma_separated_tokens[0]:
            AssemblyException("The dequeue expression and first argument must be space separated.")

        # Separate the operator and rebuild the token list.
        raw_space_separated_tokens = raw_comma_separated_tokens[0].split(" ")
        raw_space_separated_tokens += raw_comma_separated_tokens[1:]
        for raw_token in raw_space_separated_tokens:
            if " " in raw_token:
                exception_string = f"Expected a comma in the datapath statement between these two tokens: {raw_token}."
                raise AssemblyException(exception_string)

        # Separate the operation token from the rest, and make sure the datapath tokens are all sensible.
        deq_token = raw_space_separated_tokens[0]
        raw_input_channel_tokens = raw_space_separated_tokens[1:]
        for raw_token in raw_input_channel_tokens:
            if not raw_token.startswith("%i"):
                exception_string = f"{raw_token} is not a valid datapath token."
                raise AssemblyException(exception_string)
        input_channel_tokens = raw_input_channel_tokens

        # Return the reassembled tokens.
        return [deq_token] + input_channel_tokens

    @staticmethod
    def determine_predicates_to_update(original_predicate_bin_string, desired_predicate_bin_string):
        """
        Generate predicate update indices and values based on the initial and desired predicate states.

        :param original_predicate_bin_string: original predicate state in a binary string
        :param desired_predicate_bin_string: desired predicate state in a binary string
        :return: a tuple of the predicate indices and their update values
        """

        # Empty list to be populated with (predicate index, predicate value) tuples.
        predicate_update_tuples = []

        # Parse both the original and desired predicate strings.
        original_true_predicates, original_false_predicates = \
            Instruction.parse_predicate_bin_string(original_predicate_bin_string)
        desired_true_predicates, desired_false_predicates = \
            Instruction.parse_predicate_bin_string(desired_predicate_bin_string)

        # Determine the predicates that must be set to True.
        for predicate in desired_true_predicates:
            if predicate not in original_true_predicates:
                predicate_update_tuples.append((predicate, True))

        # Determine the predicates that must be set to False.
        for predicate in desired_false_predicates:
            if predicate not in original_false_predicates:
                predicate_update_tuples.append((predicate, False))

        # Rearrange the predicates for consistency.
        predicate_update_tuples = sorted(predicate_update_tuples, key=lambda t: t[0])

        # Extract the indices and values from the tuple list into separate lists.
        predicate_update_indices = [t[0] for t in predicate_update_tuples]
        predicate_update_values = [t[1] for t in predicate_update_tuples]

        # Return the indices and values for the update.
        return predicate_update_indices, predicate_update_values

    # --- Instruction Validation Method ---

    def validate(self, cp):
        # TODO
        pass


class InstructionFields:
    def __init__(self, trigger_predicate_conditions_string=None, trigger_input_channel_conditions_string=None,
                 datapath_instruction_string=None, dequeue_input_channels_string=None, predicate_update_string=None):
        """
        Generic initializer for a Trigger instance.

        :param trigger_predicate_conditions_string: "%p == XXXX1010", etc.
        :param trigger_input_channel_conditions_string: "!%i0.valid, %i7.tag", etc.
        :param datapath_instruction_string: "add %r1, %i0, $10", etc.
        :param dequeue_input_channels_string: "%i0, %i1", etc.
        :param predicate_update_string: "%p = XXXX01010", etc.
        """

        # Setting attributes according to keyword arguments.
        self.trigger_predicate_conditions_string = trigger_predicate_conditions_string
        self.trigger_input_channel_conditions_string = trigger_input_channel_conditions_string
        self.datapath_instruction_string = datapath_instruction_string
        self.dequeue_input_channels_string = dequeue_input_channels_string
        self.predicate_update_string = predicate_update_string

    # --- Alternative Constructor ---

    @classmethod
    def from_instruction_string(cls, instruction_string):
        """
        Instantiate a new InstructionFields instance from an assembly string of the form:

        when %p == [predicate binary string] with [input channels and their tags]:
            [op] [dest], [source 0], [source 1]; deq [input channels to dequeue]; set %p = [predicate binary string];

        :param instruction_string: string to parse
        :return: an initialized InstructionFields instance
        """

        # Fields to be filled in manually.
        instruction_fields = InstructionFields()

        # Split up the trigger and operation segments.
        if len(instruction_string.split(':')) != 2:
            raise AssemblyException("Expected an instruction of the form \"when (predicate trigger) [with (input "
                                    + "channel tags)]: (operations)\".")
        trigger_segment, operation_segment = instruction_string.split(':')
        trigger_segment = trigger_segment.strip()
        operation_segment = operation_segment.strip()

        # Check for the validity of the trigger statement, and strip away syntactic sugar.
        if not trigger_segment.startswith("when"):
            raise AssemblyException("Trigger expressions must start with \"when\".")
        trigger_segment = trigger_segment[4:].strip()

        # Extract any input channel tag requirements.
        if "with" in trigger_segment:
            split_trigger_segement = trigger_segment.split("with")
            instruction_fields.trigger_predicate_conditions_string = split_trigger_segement[0].strip()
            instruction_fields.trigger_input_channel_conditions_string = split_trigger_segement[1].strip()
        else:
            instruction_fields.trigger_predicate_conditions_string = trigger_segment

        # Split the operation segment according to ';' delimiters.
        if not operation_segment.endswith(';'):
            raise AssemblyException("Statements must be terminated with the ';' character.")
        operation_segment = operation_segment[0:-1]
        operation_segment_fields = operation_segment.split(';')

        # Fill in the the instruction fields for the operation segment according to the number of individual statements.
        num_operation_segment_fields = len(operation_segment_fields)
        for i in range(num_operation_segment_fields):
            operation_segment_fields[i] = operation_segment_fields[i].strip()
        if num_operation_segment_fields == 0:
            raise AssemblyException("No operation statements present.")
        elif num_operation_segment_fields == 1:
            instruction_fields.datapath_instruction_string = operation_segment_fields[0]
        elif num_operation_segment_fields == 2:
            instruction_fields.datapath_instruction_string = operation_segment_fields[0]
            if operation_segment_fields[1].startswith("deq"):
                instruction_fields.dequeue_input_channels_string = operation_segment_fields[1]
            elif operation_segment_fields[1].startswith("set"):
                instruction_fields.predicate_update_string = operation_segment_fields[1]
            else:
                exception_string = f"Unrecognized secondary operation: {operation_segment_fields[1]}."
                raise AssemblyException(exception_string)
        elif num_operation_segment_fields == 3:
            instruction_fields.datapath_instruction_string = operation_segment_fields[0]
            for i in range(1, 3):
                if operation_segment_fields[i].startswith("deq"):
                    if instruction_fields.dequeue_input_channels_string is not None:
                        raise AssemblyException("Cannot have two references to deq in an instruction. Group dequeuing "
                                                + "operations into a single deq statement.")
                    instruction_fields.dequeue_input_channels_string = operation_segment_fields[i]
                elif operation_segment_fields[i].startswith("set"):
                    if instruction_fields.predicate_update_string is not None:
                        raise AssemblyException("Cannot set the predicates to multiple values in a single instruction.")
                    instruction_fields.predicate_update_string = operation_segment_fields[i]
                else:
                    exception_string = f"Unrecognized secondary operation: {operation_segment_fields[i]}."
                    raise AssemblyException(exception_string)

        # Return the instantiated InstructionFields object.
        return instruction_fields
