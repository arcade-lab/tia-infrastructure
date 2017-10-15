"""
Top-level system wrapper.
"""

import re
import sys

import pandas as pd

from simulator.exception import SimulatorException


class System:
    """
    A system class to wrap a collection of processing and memory elements as well as the channels through which they
    communicate.
    """

    def __init__(self):
        """
        Empty system.
        """

        # Start at the zeroth cycle, and initialize system elements as empty lists to allow for appends.
        self.cycle = 0
        self.processing_elements = []
        self.memories = []
        self.buffers = []

        # Add hierarchical elements for easier access.
        self.quartets = []
        self.blocks = []
        self.arrays = []

    # --- Time-stepping Method ---

    def iterate(self, interactive, show_processing_elements, show_memories, show_buffers, keep_execution_trace):
        """
        Move ahead one clock cycle, period or whatever you want to call it (this is a functional simulator).

        :param interactive: waiting on the user at each cycle
        :param show_processing_elements: showing processing element information
        :param show_memories: showing memory element information
        :param show_buffers: showing channel information
        :return: whether the system has halted
        """

        # Initially, assume the system is halting this cycle.
        halt = True

        # Print out a debug header, if requested.
        if interactive or show_processing_elements or show_memories or show_buffers:
            print(f"\n--- Cycle: {self.cycle} ---\n")

        # Perform local processing element operations.
        if show_processing_elements:
            print("Processing Elements\n")
        for processing_element in self.processing_elements:
            processing_element.iterate(show_processing_elements, keep_execution_trace)
        for processing_element in self.processing_elements:
            halt &= processing_element.core.halt_register  # Only halt if all processing elements have halted.

        # Perform memory operations.
        if show_memories:
            print("Memories\n")
        for memory in self.memories:
            memory.iterate(show_memories)

        # Commit all pending buffer transactions.
        if show_buffers:
            print("Buffers\n")
        for buffer in self.buffers:
            buffer.commit(show_buffers)
            halt &= buffer.empty  # Only halt the system if all buffers are empty.

        # Move time forward assuming we are not halting.
        if not halt:
            self.cycle += 1

        # Return whether we should halt.
        return halt

    # --- Display Methods ---

    def halt_message(self):
        """
        Print a message showing the state of the system upon halting.
        """

        # Formatted message.
        print(f"\n--- System halted after {self.cycle} cycles. ---\n")
        print("Final Memory Layout\n")
        for memory in self.memories:
            print(f"name: {memory.name}")
            print("contents:")
            i = 0
            while i < 10:
                if i < len(memory.contents):
                    print(f"0x{memory.contents[i]:08x}")
                else:
                    break
                i += 1
            if len(memory.contents) > 10:
                print("...\n")
            else:
                print("bound\n")

    def interrupted_message(self):
        """
        Print a message showing the state of the system upon being interrupted by the user in a simulation.

        :param self: system wrapper
        """

        # Formatted message.
        print(f"\n--- System interrupted after {self.cycle} cycles. ---\n")
        print("Final Memory Layout\n")
        for memory in self.memories:
            print(f"name: {memory.name}")
            print("contents:")
            i = 0
            while i < 10:
                if i < len(memory.contents):
                    print(f"0x{memory.contents[i]:08x}")
                else:
                    break
                i += 1
            if len(memory.contents) > 10:
                print("...\n")
            else:
                print("bound\n")

    # --- Top-level Methods ---

    def register(self, element):
        """
        Register a functional unit (processing element, memory, etc.) with the event loop.
        
        :param element: functional unit 
        """

        # Make sure the functional unit has a special registration method.
        registration_operation = getattr(element, "_register")
        if not callable(registration_operation):
            exception_string = f"The functional unit of type {type(element)} does not have internal system " \
                               + f"registration method."
            raise SimulatorException(exception_string)

        # Call the functional unit's internal method.
        element._register(self)

    def finalize(self):
        """
        Alphabetize components in the event loop for clean debug output and make sure all processing elements are
        indexed.
        """

        # The numerical strings are the ones we care about.
        def natural_number_sort_key(entity):
            name = entity.name
            key_string_list = re.findall(r"(\d+)", name)
            if len(key_string_list) > 0:
                return [int(key_string) for key_string in key_string_list]
            else:
                return []

        # Sort all the entities.
        self.processing_elements = sorted(self.processing_elements, key=natural_number_sort_key)
        for i, processing_element in enumerate(self.processing_elements):
            if processing_element.name != f"processing_element_{i}":
                exception_string = f"Missing processing element {i}."
                raise SimulatorException(exception_string)
        self.memories = sorted(self.memories, key=natural_number_sort_key)
        self.buffers = sorted(self.buffers, key=natural_number_sort_key)

    def run(self, interactive, show_processing_elements, show_memories, show_buffers, keep_execution_trace):
        """
        Execute until the system halts or a user issues an interrupt or writes an EOF.

        :param interactive: whether to wait for user input on each cycle
        :param show_processing_elements: whether to show processing element status each cycle
        :param show_memories: whether to show a summary of the memory contents each cycle
        :param show_buffers: whether to show channel state each cycle
        :param keep_execution_trace: whether to keep a running log of executed instructions on each processing element
        :return: whether the system has halted and whether it was interrupted
        """

        # Simple event/read-evaluate loop.
        halt = False
        interrupted = False
        while True:
            try:
                if interactive:
                    if self.cycle > 0:
                        user_input = input("Press [Enter] to continue. Type \"exit\", or use [Ctrl-C] o [Ctrl-D] to "
                                           + "exit.\n").strip()
                        if user_input == "exit":
                            break
                        elif user_input != "":
                            print(f"Unrecognized command: {user_input}.", file=sys.stderr)
                halt = self.iterate(interactive,
                                    show_processing_elements,
                                    show_memories,
                                    show_buffers,
                                    keep_execution_trace)
                if halt:
                    self.halt_message()
                    break
            except (KeyboardInterrupt, EOFError):
                interrupted = True
                self.interrupted_message()
                break

        # Return the status flags.
        return halt, interrupted

    def reset_processing_elements(self):
        """
        Reset all the processing elements in a system.
        """

        # Use the reset() methods built in to the processing elements.
        for processing_element in self.processing_elements:
            processing_element.reset()

    def reset_memories(self):
        """
        Reset all the memories in a system.
        """

        # Use the reset() methods built in to the memories.
        for memory in self.memories:
            memory.reset()

    def reset_buffers(self):
        """
        Reset all the buffers in a system.
        """

        # Use the buffers' own reset() methods.
        for buffer in self.buffers:
            buffer.reset()

    def reset(self):
        """
        Reset all the processing elements, memories and buffers.
        """

        # Just wrap our own methods.
        self.reset_processing_elements()
        self.reset_memories()
        self.reset_buffers()

    @property
    def processing_element_traces(self):
        # Return a dictionary of execution traces.
        return {processing_element.name: processing_element.core.execution_trace
                for processing_element in self.processing_elements}

    @property
    def processing_element_traces_as_data_frame(self):
        # For convenient CSV output and analysis.
        return pd.DataFrame(self.processing_element_traces)
