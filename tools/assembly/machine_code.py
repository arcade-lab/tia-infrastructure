"""
Utilities for machine code translation.
"""

import numpy as np

from assembly.exception import AssemblyException


def build_true_ptm(cp, instruction):
    """
    Build the integer representation of the true predicate trigger mask.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of the true half of the ptm
    """

    # OR in the predicates.
    true_ptm = 0
    for predicate in reversed(instruction.trigger.true_predicates):
        if predicate > cp.num_predicates:
            exception_string = f"Predicate {predicate} is out of range on the target architecture with " \
                               + f"{cp.num_predicates} predicates."
            raise AssemblyException(exception_string)
        true_ptm |= 1 << predicate

    # Check sizing, and return the integer.
    true_ptm = int(true_ptm)
    if true_ptm.bit_length() > cp.true_ptm_width:
        raise AssemblyException("True ptm exceeds its allotted bit width.")
    return true_ptm


def build_false_ptm(cp, instruction):
    """
    Build the integer representation of the false predicate trigger mask.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of the false half of the ptm
    """

    # OR in the predicates.
    false_ptm = 0
    for predicate in reversed(instruction.trigger.false_predicates):
        if predicate > cp.num_predicates:
            exception_string = f"Predicate {predicate} is out of range on the target architecture with " \
                               + f"{cp.num_predicates} predicates."
            raise AssemblyException(exception_string)
        false_ptm |= 1 << predicate

    # Check sizing, and return the integer.
    false_ptm = int(false_ptm)
    if false_ptm.bit_length() > cp.false_ptm_width:
        raise AssemblyException("False ptm exceeds its allotted bit width.")
    return false_ptm


def build_ptm(cp, instruction):
    """
    Build the integer representation of the concatenated predicate trigger mask.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of the ptm
    """

    # Concatenate the two ptm halves.
    ptm = build_true_ptm(cp, instruction)
    ptm <<= cp.false_ptm_width
    ptm |= build_false_ptm(cp, instruction)

    # Check sizing, and return the integer.
    ptm = int(ptm)
    if ptm.bit_length() > cp.ptm_width:
        raise AssemblyException("ptm exceeds its allotted bit width.")
    return ptm


def build_ici(cp, instruction):
    """
    Build the integer representation of the input channel indices.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of the ici
    """
    # Check sizing.
    if len(instruction.trigger.input_channels) > cp.max_num_input_channels_to_check:
        exception_string = f"The {len(instruction.trigger.input_channels)} input channels to check exceed the " \
                           + f"architecture's specified maximum of {cp.max_num_input_channels_to_check}."
        raise AssemblyException(exception_string)

    # Concatenate the indices together.
    ici = 0
    for i, input_channel in enumerate(reversed(instruction.trigger.input_channels)):
        ici |= input_channel + 1  # Recall that a zero-filled ici slot implies a null value.
        if i != len(instruction.trigger.input_channels) - 1:
            ici <<= cp.single_ici_width

    # Append empty slots.
    num_null_slots = cp.max_num_input_channels_to_check - len(instruction.trigger.input_channels)
    ici <<= num_null_slots * cp.single_ici_width

    # Check sizing and return the integer.
    ici = int(ici)
    if ici.bit_length() > cp.ici_width:
        raise AssemblyException("ici exceeds its allotted bit width.")
    return ici


def build_ictb(cp, instruction):
    """
    Build the integer representation of the input channel tag Booleans.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of the ictb
    """

    # Check sizing.
    if len(instruction.trigger.input_channel_tag_booleans) > cp.max_num_input_channels_to_check:
        exception_string = f"The {len(instruction.trigger.input_channel_tag_booleans)} input channel tags to check " \
                           + f"exceed the architecture's specified maximum of {cp.max_num_input_channels_to_check}."
        raise AssemblyException(exception_string)

    # Concatenate the Booleans together.
    ictb = 0
    for i, boolean in enumerate(reversed(instruction.trigger.input_channel_tag_booleans)):
        ictb |= boolean
        if i != len(instruction.trigger.input_channels) - 1:
            ictb <<= 1

    # Append empty slots.
    num_null_slots = cp.max_num_input_channels_to_check - len(instruction.trigger.input_channels)
    ictb <<= num_null_slots

    # Check sizing, and return the integer.
    ictb = int(ictb)
    if ictb.bit_length() > cp.ictb_width:
        raise AssemblyException("ictb exceeds its allotted bit width.")
    return ictb


def build_ictv(cp, instruction):
    """
    Build the integer representation of the input channel tag values.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of the ictv
    """

    # Check sizing.
    if len(instruction.trigger.input_channel_tags) > cp.max_num_input_channels_to_check:
        exception_string = f"The {len(instruction.trigger.input_channel_tags)} input channel tags to check exceed " \
                           + f"the architecture's specified maximum of {cp.max_num_input_channels_to_check}."
        raise AssemblyException(exception_string)

    # Concatenate the values together.
    ictv = 0
    for i, tag_value in enumerate(reversed(instruction.trigger.input_channel_tags)):
        ictv |= tag_value
        if i != len(instruction.trigger.input_channel_tags) - 1:
            ictv <<= cp.tag_width

    # Append empty slots.
    num_null_slots = cp.max_num_input_channels_to_check - len(instruction.trigger.input_channel_tags)
    ictv <<= num_null_slots * cp.tag_width

    # Check sizing, and return the integer.
    ictv = int(ictv)
    if ictv.bit_length() > cp.ictv_width:
        raise AssemblyException("ictv exceeds its allotted bit width.")
    return ictv


def build_op(cp, instruction):
    """
    Build the integer representation of a datapath operation.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of op
    """

    # Should already have the correct value.
    op = instruction.op

    # Check sizing, and return the integer.
    op = int(op)
    if op.bit_length() > cp.op_width:
        raise AssemblyException("op exceeds its allotted bit width.")
    return op


def build_st(cp, instruction):
    """
    Build the integer representation of the source types.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of st
    """

    # Check sizing.
    if len(instruction.source_indices) > 3:
        exception_string = f"The {len(instruction.source_indices)} sources exceed the architecture's specified " \
                           + f"maximum of 3."
        raise AssemblyException(exception_string)

    # Concatenate the values together.
    st = 0
    num_source_types = len(instruction.source_types)
    if num_source_types > 2:
        st |= int(instruction.source_types[2])
    st <<= cp.single_st_width
    if num_source_types > 1:
        st |= int(instruction.source_types[1])
    st <<= cp.single_st_width
    if num_source_types > 0:
        st |= int(instruction.source_types[0])

    # Check sizing, and return the integer.
    st = int(st)
    if st.bit_length() > cp.st_width:
        raise AssemblyException("st exceeds its allotted bit width.")
    return st


def build_si(cp, instruction):
    """
    Build the integer representation of the source indices.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of si
    """

    # Check sizing.
    if len(instruction.source_indices) > 3:
        exception_string = f"The {len(instruction.source_indices)} sources exceed the architecture's specified " \
                           + f"maximum of 3."
        raise AssemblyException(exception_string)

    # Concatenate the values together.
    si = 0
    num_source_indices = len(instruction.source_indices)
    if num_source_indices > 2:
        if instruction.source_indices[2] != 0:
            si |= instruction.source_indices[2]
    si <<= cp.single_si_width
    if num_source_indices > 1:
        if instruction.source_indices[1] != 0:
            si |= instruction.source_indices[1]
    si <<= cp.single_si_width
    if num_source_indices > 0:
        if instruction.source_indices[0] != 0:
            si |= instruction.source_indices[0]

    # Check sizing, and return the integer.
    si = int(si)
    if si.bit_length() > cp.si_width:
        raise AssemblyException("si exceeds its allotted bit width.")
    return si


def build_dt(cp, instruction):
    """
    Build the integer representation of destination type.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of dt
    """

    # Should already have the correct value.
    dt = instruction.destination_type

    # Check sizing, and return the integer.
    dt = int(dt)
    if dt.bit_length() > cp.di_width:
        raise AssemblyException("dt exceeds its allotted bit width.")
    return dt


def build_di(cp, instruction):
    """
    Build the integer representation of destination index.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of di
    """

    # If it exists, again we have to increment it by one to show it is not void.
    if instruction.destination_index is not None:
        di = instruction.destination_index
    else:
        di = 0

    # Check sizing, and return the integer.
    di = int(di)
    if di.bit_length() > cp.di_width:
        raise AssemblyException("di exceeds its allotted bit width.")
    return di


def build_oci(cp, instruction):
    """
    Build the integer representation of the output channel indices array.

    :param cp: CoreParameters instance of the target architecture.
    :param instruction: Instruction instance
    :return: integer representation of oci
    """

    # OR in the output channels.
    oci = 0
    for output_channel in reversed(range(cp.num_output_channels)):
        if output_channel in instruction.output_channel_indices:
            oci |= 1
        if output_channel != 0:
            oci <<= 1

    # Check sizing, and return the integer.
    oci = int(oci)
    if oci.bit_length() > cp.oci_width:
        raise AssemblyException("oci exceeds its allotted bit width.")
    return oci


def build_oct(cp, instruction):
    """
    Build the integer representation of the destination tag.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of oct
    """

    # If it exists, again we have to increment it by one to show it is not void.
    if instruction.output_channel_tag is not None:
        oct = instruction.output_channel_tag
    else:
        oct = 0

    # Check sizing, and return the integer.
    oct = int(oct)
    if oct.bit_length() > cp.oct_width:
        raise AssemblyException("oct exceeds its allotted bit width.")
    return oct


def build_icd(cp, instruction):
    """
    Build the integer representation of the input channels to dequeue.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of icd
    """

    # OR in the literal array of bits.
    icd = 0
    for input_channel in reversed(range(cp.num_input_channels)):
        if input_channel in instruction.input_channels_to_dequeue:
            icd |= 1
        if input_channel != 0:
            icd <<= 1

    # Check sizing, and return the integer.
    icd = int(icd)
    if icd.bit_length() > cp.icd_width:
        raise AssemblyException("icd exceeds its allotted bit width.")
    return icd


def build_true_pum(cp, instruction):
    """
    Build the integer representation of the true predicate update mask.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of the true half of pum
    """

    # OR in the predicates.
    true_pum = 0
    for predicate, boolean in zip(instruction.predicate_update_indices, instruction.predicate_update_values):
        if predicate > cp.num_predicates:
            exception_string = f"Predicate {predicate} is out of range on the target architecture with" \
                               + f"{cp.num_predicates} predicates."
            raise AssemblyException(exception_string)
        if boolean:
            true_pum |= 1 << predicate

    # Check sizing, and return the integer.
    true_pum = int(true_pum)
    if true_pum.bit_length() > cp.true_pum_width:
        raise AssemblyException("True pum exceeds its allotted bit width.")
    return true_pum


def build_false_pum(cp, instruction):
    """
    Build the integer representation of the false predicate update mask.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of the false half of pum
    """

    # OR in the predicates.
    false_pum = 0
    for predicate, boolean in zip(instruction.predicate_update_indices, instruction.predicate_update_values):
        if predicate > cp.num_predicates:
            exception_string = f"Predicate {predicate} is out of range on the target architecture with " \
                               + f"{cp.num_predicates} predicates."
            raise AssemblyException(exception_string)
        if not boolean:
            false_pum |= 1 << predicate

    # Check sizing, and return the integer.
    false_pum = int(false_pum)
    if false_pum.bit_length() > cp.false_pum_width:
        raise AssemblyException("False pum exceeds its allotted bit width.")
    return false_pum


def build_pum(cp, instruction):
    """
    Build the integer representation of the concatenated predicate update mask.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: integer representation of the pum
    """

    # Concatenate the two pum halves.
    pum = build_true_pum(cp, instruction) << cp.false_ptm_width
    pum |= build_false_pum(cp, instruction)

    # Check sizing, and return the integer.
    pum = int(pum)
    if pum.bit_length() > cp.ptm_width:
        raise AssemblyException("pum exceeds its allotted bit width.")
    return pum


def build_immediate(cp, instruction):
    """
    Build the integer representation of the immediate.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: the integer representation of the immediate.
    """

    # Make sure we actually have an immediate value, and if not, return zero.
    if instruction.immediate is None:
        return 0

    # Check sizing.
    if instruction.immediate.bit_length() > cp.immediate_width:
        raise AssemblyException("The immediate exceeds its allotted bit width.")

    # Unsigned conversion and masking.
    unsigned = int(np.uint32(instruction.immediate))  # max immediate is 32 bits.
    mask = 0
    for i in range(cp.immediate_width):
        mask |= 1
        if i != cp.immediate_width - 1:
            mask <<= 1
    masked = unsigned & mask

    # Return the masked value.
    return masked


def build_machine_code_instruction(cp, instruction):
    """
    Build the entire bit pattern for the instruction.

    :param cp: CoreParameters instance for the target architecture
    :param instruction: Instruction instance
    :return: the integer representation of the instruction
    """

    # OR in all the fields in the instruction word.
    machine_code = 1  # vi is valid.
    machine_code <<= cp.ptm_width
    machine_code |= build_ptm(cp, instruction)
    machine_code <<= cp.ici_width
    machine_code |= build_ici(cp, instruction)
    machine_code <<= cp.ictb_width
    machine_code |= build_ictb(cp, instruction)
    machine_code <<= cp.ictv_width
    machine_code |= build_ictv(cp, instruction)
    machine_code <<= cp.op_width
    machine_code |= build_op(cp, instruction)
    machine_code <<= cp.st_width
    machine_code |= build_st(cp, instruction)
    machine_code <<= cp.si_width
    machine_code |= build_si(cp, instruction)
    machine_code <<= cp.dt_width
    machine_code |= build_dt(cp, instruction)
    machine_code <<= cp.di_width
    machine_code |= build_di(cp, instruction)
    machine_code <<= cp.oci_width
    machine_code |= build_oci(cp, instruction)
    machine_code <<= cp.oct_width
    machine_code |= build_oct(cp, instruction)
    machine_code <<= cp.icd_width
    machine_code |= build_icd(cp, instruction)
    machine_code <<= cp.pum_width
    machine_code |= build_pum(cp, instruction)
    machine_code <<= cp.immediate_width
    machine_code |= build_immediate(cp, instruction)
    machine_code <<= cp.padding_width

    # Return the integer representation.
    return machine_code


def build_program_binary(cp, program):
    """
    Convert the program to a list of 32-bit words to be written out to disk or programmed into the hardware.
    :param cp: CoreParameters instance for the target architecture
    :param program: a ProcessingElementProgram instance
    :return: the register initialization settings and the instructions as two lists of 32-bit words
    """

    # Generate register initialization data as 32-bit words.
    register_words = []
    for register_value in program.register_values:
        unsigned = int(np.uint32(register_value))  # max word size is 32 bits.
        mask = 0
        for i in range(cp.device_word_width):
            mask |= 1
            if i != cp.device_word_width - 1:
                mask <<= 1
        masked = unsigned & mask
        register_words.append(np.uint32(masked))

    # Machine code instructions are sliced into individual 32-bit words.
    if cp.mm_instruction_width % 32 != 0:
        raise AssemblyException("Memory-mapped instructions must be in multiples of 32-bit words.")
    mm_instruction_word_width = int(cp.mm_instruction_width / 32)
    assembled_instructions = [build_machine_code_instruction(cp, instruction) for instruction in program.instructions]
    instruction_words = []
    for assembled_instruction in assembled_instructions:
        for i in range(mm_instruction_word_width):
            instruction_words.append((assembled_instruction >> i * 32) & 0xffffffff)

    # Append empty instructions to fill out remaining instruction memory.
    if len(assembled_instructions) < cp.num_instructions:
        num_empty_instructions = cp.num_instructions - len(assembled_instructions)
        for _ in range(num_empty_instructions):
            instruction_words += [0] * mm_instruction_word_width

    # Return the two lists.
    return register_words, instruction_words
