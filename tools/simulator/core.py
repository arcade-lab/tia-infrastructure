"""
Processing element cores and related utilities.
"""

import numpy as np

from assembly.instruction import Op, op_implementation_map, SourceType, DestinationType
from simulator.exception import SimulatorException
from simulator.interconnect import Packet, SenderChannelBuffer, ReceiverChannelBuffer


class Core:
    """
    Processing element core for functional simulation.
    """

    def __init__(self, name, cp):
        """
        Initialize a processing element core.

        :param name: an English name
        :param cp: a CoreParameters instance.
        """

        # Set to values expected default upon reset.
        self.name = name
        self.instructions = []
        self.predicates = [False] * cp.num_predicates
        self.registers = np.zeros(cp.num_registers, dtype=np.uint32)
        if cp.num_scratchpad_words != 0:
            self.scratchpad = np.zeros(cp.num_scratchpad_words, dtype=np.uint32)
        else:
            self.scratchpad = None
        self.input_channel_buffers = []
        for i in range(cp.num_input_channels):
            self.input_channel_buffers.append(ReceiverChannelBuffer(f"{name}: Input Channel Buffer {i}",
                                                                    cp.channel_buffer_depth))
        self.output_channel_buffers = []
        for i in range(cp.num_output_channels):
            self.output_channel_buffers.append(SenderChannelBuffer(f"{name}: Output Channel Buffer {i}",
                                                                   cp.channel_buffer_depth))
        self.halt_register = False
        self.instructions_retired = 0
        self.untriggered_cycles = 0
        self.execution_trace = []

    # --- Programming Routines ---

    def initialize_registers(self, register_values):
        """
        Initialize registers.

        :param register_values: abstract Python integer representations of data register contents
        """

        # Check usage an perform explicit datatype conversion.
        if len(register_values) != len(self.registers):
            raise SimulatorException("Register initialization data length and register file size do not match.")
        for i, register_value in enumerate(register_values):
            self.registers[i] = np.uint32(register_value)

    def program(self, program):
        """
        Program a processing element with instructions and possibly initial register values.

        :param program: a ProcessingElementProgram instance
        """

        # Overwrite instructions.
        self.initialize_registers(program.register_values)
        self.instructions = program.instructions

    # --- Trigger Checking Method ---

    def check_trigger(self, trigger):
        """
        Check a processing element's architectural state to see if a trigger is valid.

        :param trigger: the the trigger field to check
        :return: whether the trigger is valid
        """

        # Return false if any condition specified in the instruction is not met, but default to true.
        for i in trigger.true_predicates:
            if not self.predicates[i]:
                return False
        for i in trigger.false_predicates:
            if self.predicates[i]:
                return False
        for i in trigger.input_channels:
            if self.input_channel_buffers[i].empty:
                return False
        for i, tag, boolean in zip(trigger.input_channels, trigger.input_channel_tags, trigger.input_channel_tag_booleans):
            if boolean:
                if self.input_channel_buffers[i].peek().tag != tag:
                    return False
            else:
                if self.input_channel_buffers[i].peek().tag == tag:
                    return False
        for index in trigger.output_channel_indices:
            if self.output_channel_buffers[index].full:
                return False

        # Default to true.
        return True

    # --- System Registration Method ---

    def _register(self, system):
        """
        Register the processing element core with the system event loop.
        
        :param system: the rest of the system
        """

        # Register the channel buffers with the event loop.
        for input_channel_buffer in self.input_channel_buffers:
            system.buffers.append(input_channel_buffer)
        for output_channel_buffer in self.output_channel_buffers:
            system.buffers.append(output_channel_buffer)

    # --- Time-stepping Method ---

    def iterate(self, debug, keep_execution_trace):
        """
        Perform a single cycle of execution.

        :param debug: whether to print out information about internal state
        :param keep_execution_trace: whether to maintain a running log of indices of fired instructions
        """

        # Show PE state for debugging purposes if necessary.
        if debug:
            print(f"name: {self.name}")
            predicate_string_list = []
            for predicate in self.predicates:
                if predicate:
                    predicate_string_list.append("1")
                else:
                    predicate_string_list.append("0")
            predicate_string = "".join(predicate_string_list)
            predicate_string = predicate_string[::-1]
            print(f"predicates: {predicate_string}")
            print("registers:")
            register_strings = [f"{i:02d}: 0x{register:08x}" for i, register in enumerate(self.registers)]
            print("\n".join(register_strings))
            print(f"number of instructions: {len(self.instructions)}")
            i = None
            valid_instruction = None
            for i, instruction in enumerate(self.instructions):
                if self.check_trigger(instruction.trigger):
                    valid_instruction = instruction
                    break
            if i is not None and valid_instruction is not None:
                print(f"valid instruction: {i}")
                print(f"triggered instruction: {valid_instruction.op.name}")
            else:
                print("valid instruction: None")
                print("triggered instruction: nop")
            print(f"halt register: {self.halt_register}")
            print(f"instructions retired: {self.instructions_retired}")
            print(f"untriggered cycles: {self.untriggered_cycles}\n")

        # Check for an halt condition.
        valid_instruction = None
        if not self.halt_register:
            # Find a valid instruction if one exists, searching the list of instructions in priority order.
            for instruction in self.instructions:
                if self.check_trigger(instruction.trigger):
                    valid_instruction = instruction
                    break

            # Execute any valid instruction.
            if valid_instruction is not None:
                # Increment the performance counter.
                self.instructions_retired += 1

                # Set the halt register if required.
                if valid_instruction.op == Op.halt:
                    self.halt_register = True

                # Get operands from their sources and perform any source actions.
                a_type, b_type, c_type = valid_instruction.source_types
                a_index, b_index, c_index = valid_instruction.source_indices
                if a_type == SourceType.immediate:
                    a = valid_instruction.immediate
                elif a_type == SourceType.channel:
                    a = self.input_channel_buffers[a_index].peek().value
                elif a_type == SourceType.register:
                    a = self.registers[a_index]
                elif a_type == SourceType.null:
                    a = 0
                else:
                    raise SimulatorException("Unknown source type for operand a.")
                if b_type == SourceType.immediate:
                    b = valid_instruction.immediate
                elif b_type == SourceType.channel:
                    b = self.input_channel_buffers[b_index].peek().value
                elif b_type == SourceType.register:
                    b = self.registers[b_index]
                elif b_type == SourceType.null:
                    b = 0
                else:
                    raise SimulatorException("Unknown source type for operand b.")
                if c_type == SourceType.immediate:
                    c = valid_instruction.immediate
                elif c_type == SourceType.channel:
                    c = self.input_channel_buffers[c_index].peek().value
                elif c_type == SourceType.register:
                    c = self.registers[c_index]
                elif c_type == SourceType.null:
                    c = 0
                else:
                    raise SimulatorException("Unknown source type for operand b.")

                # Perform operation.
                if valid_instruction.op == Op.lsw:
                    if self.scratchpad is None:
                        raise SimulatorException("Attempting to load a word in a core that has no scratchpad.")
                    result = self.scratchpad[a]
                elif valid_instruction.op == Op.ssw:
                    if self.scratchpad is None:
                        raise SimulatorException("Attempting to store a word in a core that has no scratchpad.")
                    self.scratchpad[b] = a
                    result = 0
                else:
                    result = op_implementation_map[valid_instruction.op](a, b, c)

                # Store results in the destination.
                destination_type = valid_instruction.destination_type
                destination_index = valid_instruction.destination_index
                if destination_type == DestinationType.channel:
                    result_packet = Packet(valid_instruction.output_channel_tag, result)
                    for i in valid_instruction.output_channel_indices:
                        self.output_channel_buffers[i].enqueue(result_packet)
                elif destination_type == DestinationType.register:
                    self.registers[destination_index] = result
                elif destination_type == DestinationType.predicate:
                    self.predicates[destination_index] = bool(result)
                elif destination_type == DestinationType.null:
                    pass
                else:
                    raise SimulatorException("Unknown destination type.")

                # Dequeue any required input channels.
                for i in valid_instruction.input_channels_to_dequeue:
                    self.input_channel_buffers[i].dequeue()

                # Perform any PE updates necessary.
                for i, index in enumerate(valid_instruction.predicate_update_indices):
                    self.predicates[index] = valid_instruction.predicate_update_values[i]
            else:
                # No valid instruction this cycle.
                self.untriggered_cycles += 1

        # Internal execution trace.
        if keep_execution_trace:
            self.execution_trace.append(valid_instruction.number if valid_instruction is not None else -1)

    # --- Reset Method ---

    def reset(self):
        """
        Assuming the persistence of instructions, reset all other architectural state.
        """

        # Reset the buffers, predicates, registers and halt status, but save the instructions.
        for i in range(len(self.predicates)):
            self.predicates[i] = False
        for i in range(len(self.registers)):
            self.registers[i] = 0
        self.halt_register = False
        self.instructions_retired = 0
        self.untriggered_cycles = 0
        self.execution_trace = []
        for input_channel_buffer in self.input_channel_buffers:
            input_channel_buffer.reset()
        for output_channel_buffer in self.output_channel_buffers:
            output_channel_buffer.reset()
