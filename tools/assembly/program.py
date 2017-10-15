"""
Utilities for building programs from assembly source files for simulated and physical hardware.
"""

import re

from assembly.exception import AssemblyException
from assembly.instruction import Instruction


def apply_macros(macro_dictionary, program_string):
    """
    Apply macros to the source code.

    :param macro_dictionary: a dictionary of macros (e.g., {"UINT32_MAX": 4294967296, "SAVED_REG": "%r0"})
    :param program_string: assembly program
    :return: the program with macros substituted
    """

    # Sort the macros from longest to shortest to cover the case where macros are substrings of one another.
    macros = macro_dictionary.keys()
    macros = sorted(macros, key=lambda m: -len(m))

    # Replace all the macros with their values.
    for macro in macros:
        program_string = program_string.replace(macro, str(macro_dictionary[macro]))  # Allow for duck-typed macros.

    # Return the preprocessed program.
    return program_string


def split_program_by_processing_element_label(program_string):
    """
    Split a program string into a list of individual processing element programs based on the location of <*> labels.

    :param program_string: multiline string containing an assembly program with <*> labels
    :return: the corresponding list of label-string tuples
    """

    # Find the labels.
    labels = re.findall(r"<(.*?)>", program_string)

    # Replace all instances of processing element delimiter with just the bookends "<>" as a sigil.
    program_string = re.sub(r"<.*>", "<>", program_string)

    # Split the program string into a list of processing element programs and delete the leading null field.
    processing_element_program_strings = program_string.split("<>")
    del processing_element_program_strings[0]

    # Return the resulting list.
    return list(zip(labels, processing_element_program_strings))


class ProcessingElementProgram:
    """
    Program of register initialization values and instructions for a processing element.
    """

    def __init__(self, cp, label, register_values, instructions):
        """
        Default initializer.

        :param cp: a CoreParameters instance
        :param label: processing element label
        :param register_values: initial register values as abstract Python integers
        :param instructions: list of Instruction instances
        """

        # Default initialization.
        self.cp = cp
        self.label = label
        self.register_values = register_values
        self.instructions = instructions

    # --- Alternative Constructor ---

    @classmethod
    def from_label_and_string(cls, cp, label, processing_element_program_string):
        """
        Build from a processing element label and register-file initialization/instruction string.

        :param cp: a CoreParameters instance
        :param label: processing element label
        :param processing_element_program_string: register setting statements and instructions
        :return: an initialized instance
        """

        # Build fields manually.
        try:
            register_string, instruction_string = \
                ProcessingElementProgram.split_into_register_and_instruction_strings(processing_element_program_string)
            register_values = \
                ProcessingElementProgram.convert_register_initialization_statements_to_register_values(cp, register_string)
            instructions = \
                ProcessingElementProgram.convert_processing_element_instructions_string_to_instructions(instruction_string)
        except AssemblyException as e:
            exception_string = f"Error parsing program {label}: {str(e)}"
            raise AssemblyException(exception_string)
        return cls(cp, label, register_values, instructions)

    # --- Static Methods for Program Construction ---

    @staticmethod
    def split_into_register_and_instruction_strings(processing_element_program_string):
        """
        Split the program string into register file initialization and instruction segments.

        :param processing_element_program_string: multiline processing element program string
        :return: a register string and an instruction string
        """

        # Accumulate lines of each type.
        program_string_lines = processing_element_program_string.split('\n')
        register_lines = []
        instruction_lines = []
        for line in program_string_lines:
            if line.strip().startswith("init"):
                register_lines.append(line)
                instruction_lines.append("")  # to keep track of line numbers.
            else:
                instruction_lines.append(line)

        # Rebuild the strings, and return them.
        register_string = "\n".join(register_lines)
        instruction_string = "\n".join(instruction_lines)
        return register_string, instruction_string

    @staticmethod
    def extract_register_initialization_data_from_statement(statement):
        """
        Extract the register index and register data from an initialization statement.

        :param statement: "set %r5 = 0x1234;", for example
        :return: the index and data as integers
        """

        # Strip the statement of comments and whitespace.
        statement = re.sub(r"#.*", "", statement)
        statement = statement.strip()

        # Extract the register index.
        register_index_pattern = r"init\s*%r(\d+)\s*,.*"
        match = re.match(register_index_pattern, statement)
        if match is None:
            exception_string = f"Invalid register initialization statement: {statement}."
            raise AssemblyException(exception_string)
        try:
            register_index_string = match.group(1)
        except IndexError:
            exception_string = f"Invalid register initialization statement: {statement}."
            raise AssemblyException(exception_string)
        try:
            register_index = int(register_index_string)
        except ValueError:
            exception_string = f"Invalid register index in initialization statement: {statement}."
            raise AssemblyException(exception_string)

        # Extract the register data.
        register_data_pattern = r"init\s*%r\d+\s*,\s*\$(-*\d*|-*0x\d*);"
        match = re.match(register_data_pattern, statement)
        if match is None:
            exception_string = f"Invalid register initialization statement: {statement}."
            raise AssemblyException(exception_string)
        try:
            register_data_string = match.group(1)
        except IndexError:
            exception_string = f"Invalid register initialization statement: {statement}."
            raise AssemblyException(exception_string)
        if "0x" in register_data_string:
            base = 16
        else:
            base = 10
        try:
            register_data = int(register_data_string, base=base)
        except ValueError:
            exception_string = f"Invalid register data in initialization statement: {statement}."
            raise AssemblyException(exception_string)

        # Return the extracted information.
        return register_index, register_data

    @staticmethod
    def convert_register_initialization_statements_to_register_values(cp, register_string):
        """
        Convert the register initialization statements into an array of initial register values that are Python integers.
        Encoding into sized integers is to be done by a simulator or machine code generator further down the pipeline, so
        for now the integer values are abstract.

        :param cp: a CoreParameters instance
        :param register_string: string of register initialization statements
        :return: a list of register values as Python integers
        """

        # Outer loop around individual statements to build the initial register file state.
        register_values = [0] * cp.num_registers
        for statement in register_string.split('\n'):
            if statement.strip() != "":
                register_index, register_value = \
                    ProcessingElementProgram.extract_register_initialization_data_from_statement(statement)
                register_values[register_index] = register_value
        return register_values

    @staticmethod
    def convert_processing_element_instructions_string_to_instructions(processing_element_instructions_string):
        """
        Process an assembly string for an individual PE into a set of instructions.

        :param processing_element_instructions_string: multiline string containing an assembly program (instructions only)
        :return: the corresponding list of instructions
        """

        # Remove comments (MIPS-style comments).
        processing_element_instructions_string = re.sub(r"#.*", "", processing_element_instructions_string)

        # Break the program into instruction strings.
        program_string_lines = processing_element_instructions_string.split('\n')
        instruction_strings = []
        i = 0
        while i < len(program_string_lines):
            line = program_string_lines[i].strip()
            if line == "":
                i += 1
            elif line.endswith(':'):
                instruction_strings.append(program_string_lines[i] + program_string_lines[i + 1])
                i += 2
            elif ':' in line:
                instruction_strings.append(program_string_lines[i])
                i += 1
            else:
                exception_string = f"Unexpected statement: {line} on source line {i}."
                raise AssemblyException(exception_string)

        # Build the list of instructions.
        instructions = []
        for i, instruction_string in enumerate(instruction_strings):
            try:
                instruction = Instruction.from_string(instruction_string)
                instruction.number = i
                instructions.append(instruction)
            except Exception as e:
                instruction_string = " ".join(instruction_string.split()).strip()
                exception_string = f"Error encountered in assembling instruction {i}: {instruction_string} --> {str(e)}"
                raise AssemblyException(exception_string)

        # Return the completed list of instructions.
        return instructions

    # --- Validation Method ---

    def validate(self):
        """
        Validate the register file values and instructions in a program against architectural parameters.
        """

        # Validate register values.
        for i, register_value in enumerate(self.register_values):
            if register_value < 0:
                effective_bit_length = register_value.bit_length() + 1
            else:
                effective_bit_length = register_value.bit_length()
            if effective_bit_length > self.cp.device_word_width:
                exception_string = f"In program {self.label}, register {i} initialized to too wide of a value for " \
                                   + f"this architecture: {register_value}"
                raise AssemblyException(exception_string)

        # Will raise an exception if needed.
        for instruction in self.instructions:
            instruction.validate(self.cp)
