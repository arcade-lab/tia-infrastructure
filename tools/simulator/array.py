"""
Arbitrary dimensional array for simulation purposes.
"""

from constants.direction import Direction
from simulator.processing_element import ProcessingElement, connect_processing_elements


class Array:
    """
    Arbitrary dimensional array for easier simulation.
    """

    def __init__(self, name, num_rows, num_columns, cp, ip):
        """
        Initialize an array.
        
        :param name: an English name 
        :param num_rows: number of rows of processing elements
        :param num_columns: number of columns of processing elements
        :param cp: a CoreParameters instance
        :param ip: an InterconnectParameters instance
        """

        # Fill in name, and instantiate underlying processing elements.
        self.name = name
        self.processing_elements = []
        for i in range(num_rows * num_columns):
            self.processing_elements.append(ProcessingElement(name=f"processing_element_{i}",
                                                              cp=cp,
                                                              ip=ip))

        # Wire up the processing elements.
        for i in range(num_rows):
            for j in range(num_columns):
                if j < num_columns - 1:
                    connect_processing_elements(self.processing_elements[i * num_columns + j],
                                                self.processing_elements[i * num_columns + j + 1],
                                                Direction.east)
                if i < num_rows - 1:
                    connect_processing_elements(self.processing_elements[i * num_columns + j],
                                                self.processing_elements[(i + 1) * num_columns + j],
                                                Direction.south)

    # --- System Registration Method ---

    def register(self, system):
        """
        Register the array with the system event loop.
        
        :param system: the rest of the system
        """

        # Add ourselves as a hierarchical element.
        system.arrays.append(self)

        # Call the underlying processing element registration functions.
        for processing_element in self.processing_elements:
            processing_element._register(system)
