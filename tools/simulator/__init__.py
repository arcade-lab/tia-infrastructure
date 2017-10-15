"""
A collection of classes representing the objects that make up a simulated TIA system:
    - channel.py: contains buffered channels (with single-cycle latency for enqueueing and dequeueing and a
      parametrizable FIFO depth.
    - me.py: contains "memory elements" which are generic synchronous memories with read and write port FSMs that can be
      accessed and updated at word granularity.
    - pe.py: contains a processing element which can execute the entire instruction set (currently only single-cycle).
    - system.py: a wrapper for an entire simulated system that has an event loop and optional REPL.
"""
