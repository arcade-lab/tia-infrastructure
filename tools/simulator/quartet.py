"""
Quartets and related utilities.
"""

from constants.direction import Direction
from simulator.exception import SimulatorException
from simulator.processing_element import ProcessingElement, connect_processing_elements


class Quartet:
    """
    A group of four processing elements that in hardware share the same clock and reset tree and the same configuration
    logic, MMIO access port, and eventually a load-store queue.
    """

    def __init__(self, name, row_base_index, column_base_index, num_columns, cp, ip):
        """
        Initialize a quartet.
        
        :param name: the quartet name 
        :param row_base_index: base index for row iteration
        :param column_base_index: base index for column iteration
        :param num_columns: number of columns of processing elements in the entire array
        :param cp: a CoreParameters instance
        :param ip: an InterconnectParameters instance
        """

        # Fill in name, and instantiate underlying processing elements.
        self.name = name
        processing_element_names = []
        for i in range(row_base_index, row_base_index + 2):
            for j in range(column_base_index, column_base_index + 2):
                processing_element_index = i * num_columns + j
                processing_element_names.append(f"processing_element_{processing_element_index}")
        if len(processing_element_names) != 4:
            raise SimulatorException("Every processing element must have a name.")
        self.processing_elements = []
        for processing_element_name in processing_element_names:
            self.processing_elements.append(ProcessingElement(name=processing_element_name,
                                                              cp=cp,
                                                              ip=ip))

        # Wire up the processing elements.
        for i in range(2):
            for j in range(2):
                if j < 2 - 1:
                    connect_processing_elements(self.processing_elements[i * 2 + j],
                                                self.processing_elements[i * 2 + j + 1],
                                                Direction.east)
                if i < 2 - 1:
                    connect_processing_elements(self.processing_elements[i * 2 + j],
                                                self.processing_elements[(i + 1) * 2 + j],
                                                Direction.south)

    # --- System Registration Method ---

    def _register(self, system):
        """
        Register the quartet with the system event loop.
        
        :param system: the rest of the system
        """

        # Add ourselves as a hierarchical element.
        system.quartets.append(self)

        # Call the underlying processing element registration functions.
        for processing_element in self.processing_elements:
            processing_element._register(system)


def connect_quartets(quartet_a, quartet_b, direction_a_to_b):
    """
    Use the processing element connection function to conveniently connect two quartets along an axis defined by
    direction_a_to_b.

    :param quartet_a: the first quartet
    :param quartet_b: the second quartet
    :param direction_a_to_b: the cardinal direction between processing elements a and b
    """

    # Possibly something to refactor at some point.
    if direction_a_to_b == Direction.north:
        for j in range(2):
            connect_processing_elements(quartet_a.processing_elements[0 * 2 + j],
                                        quartet_b.processing_elements[1 * 2 + j],
                                        Direction.north)
    elif direction_a_to_b == Direction.east:
        for i in range(2):
            connect_processing_elements(quartet_a.processing_elements[i * 2 + 1],
                                        quartet_b.processing_elements[i * 2 + 0],
                                        Direction.east)
    elif direction_a_to_b == Direction.south:
        for j in range(2):
            connect_processing_elements(quartet_a.processing_elements[1 * 2 + j],
                                        quartet_b.processing_elements[0 * 2 + j],
                                        Direction.south)
    elif direction_a_to_b == Direction.west:
        for i in range(2):
            connect_processing_elements(quartet_a.processing_elements[i * 2 + 0],
                                        quartet_b.processing_elements[i * 2 + 1],
                                        Direction.west)
    else:
        raise SimulatorException("Invalid direction to connect two quartets.")
