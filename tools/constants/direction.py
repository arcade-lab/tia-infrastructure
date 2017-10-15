"""
Direction standard and binary representation.
"""

from enum import IntEnum


class Direction(IntEnum):
    """
    Cardinal directions used in routers and software-routed programs.
    """

    # For binary encoding in routing tables.
    north = 0
    east = 1
    south = 2
    west = 3


# Directions iterable.
directions = [Direction.north,
              Direction.east,
              Direction.south,
              Direction.west]


# Direction vectors.
direction_vector_map = {Direction.north: (-1, 0),
                        Direction.east: (0, 1),
                        Direction.south: (1, 0),
                        Direction.west: (0, -1)}
vector_direction_map = {(-1, 0): Direction.north,
                        (0, 1): Direction.east,
                        (1, 0): Direction.south,
                        (0, -1): Direction.west}

# Map of reverse directions.
reverse_direction_map = {Direction.north: Direction.south,
                         Direction.east: Direction.west,
                         Direction.south: Direction.north,
                         Direction.west: Direction.east}

# For printing.
direction_name_map = {Direction.north: "north",
                      Direction.east: "east",
                      Direction.south: "south",
                      Direction.west: "west"}
