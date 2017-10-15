"""
Blocks and related utilities.
"""

from constants.direction import Direction
from simulator.quartet import Quartet, connect_quartets


class Block:
    """
    A group of four quartets (sixteen processing elements) that in hardware share the same clock and reset tree and the same configuration
    logic, MMIO access port, and eventually a load-store queue.
    """

    def __init__(self, name, row_base_index, column_base_index, num_columns, cp, ip):
        """
        Initialize a block.
        
        :param name: the quartet name 
        :param row_base_index: base index for row iteration
        :param column_base_index: base index for column iteration
        :param num_columns: number of columns of processing elements in the entire array
        :param cp: a CoreParameters instance
        :param ip: an InterconnectParameters instance
        """

        # Fill in name, and instantiate underlying quartets.
        self.name = name
        quartet_names = []
        quartet_base_indices = []
        quartet_row_base_index = int(row_base_index / 2)
        quartet_column_base_index = int(column_base_index / 2)
        quartet_num_columns = int(num_columns / 2)
        for i in range(quartet_row_base_index, quartet_column_base_index + 2):
            for j in range(quartet_column_base_index, quartet_column_base_index + 2):
                quartet_index = i * quartet_num_columns + j
                quartet_names.append(f"quartet_{quartet_index}")
                quartet_base_indices.append((i * 2, j * 2))
        self.quartets = []
        for quartet_name, quartet_base_index_tuple in zip(quartet_names, quartet_base_indices):
            self.quartets.append(Quartet(name=quartet_name,
                                         row_base_index=quartet_base_index_tuple[0],
                                         column_base_index=quartet_base_index_tuple[1],
                                         num_columns=num_columns,
                                         cp=cp,
                                         ip=ip))

        # Wire up the quartets.
        for i in range(2):
            for j in range(2):
                if j < 2 - 1:
                    connect_quartets(self.quartets[i * 2 + j],
                                     self.quartets[i * 2 + j + 1],
                                     Direction.east)
                if i < 2 - 1:
                    connect_quartets(self.quartets[i * 2 + j],
                                     self.quartets[(i + 1) * 2 + j],
                                     Direction.south)

    # --- System Registration Method ---

    def _register(self, system):
        """
        Register the block with the system event loop.
        
        :param system: the rest of the system
        """

        # Add ourselves as a hierarchical element.
        system.blocks.append(self)

        # Call the underlying quartet registration functions.
        for quartet in self.quartets:
            quartet._register(system)


def connect_blocks(block_a, block_b, direction_a_to_b):
    """
    Use the quartet connection function to conveniently connect two quartets along an axis defined by
    direction_a_to_b.

    :param direction_a_to_b: the cardinal direction between processing elements a and b
    :param block_a: the first block
    :param block_b: the second block
    """

    # Possibly something to refactor at some point.
    if direction_a_to_b == Direction.north:
        for j in range(2):
            connect_quartets(block_a.quartets[0 * 2 + j],
                             block_b.quartets[1 * 2 + j],
                             Direction.north)
    elif direction_a_to_b == Direction.east:
        for i in range(2):
            connect_quartets(block_a.quartets[i * 2 + 1],
                             block_b.quartets[i * 2 + 0],
                             Direction.east)
    elif direction_a_to_b == Direction.south:
        for j in range(2):
            connect_quartets(block_a.quartets[1 * 2 + j],
                             block_b.quartets[0 * 2 + j],
                             Direction.south)
    elif direction_a_to_b == Direction.west:
        for i in range(2):
            connect_quartets(block_a.quartets[i * 2 + 0],
                             block_b.quartets[i * 2 + 1],
                             Direction.west)
    else:
        raise RuntimeError("Invalid direction to connect two blocks.")
