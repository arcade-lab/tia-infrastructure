TIA Tools
=========

Authors: Thomas J. Repetti (trepetti@cs.columbia.edu)
         Martha A. Kim (martha@cs.columbia.edu)

Requirements
------------

  * Python 3.6 or higher
  * docopt
  * numpy
  * pandas
  * PyYAML
  * paramiko
  * scp
  * tqdm

Modules
-------

  * `assembly` - logical and physical representation of instructions
  * `parameters` - parametrization utilities
  * `simulator` - functional simulator objects
  * `test_manager` - utilities for running verification benchmarking on FPGA boards

Assembler
---------

  * `tia_as` - TIA assembler

Test Programs
-------------

  * `petfs` (processing element test functional simulator) - for validating test programs in software
  * `petm` (processing element test manager) - for running (batches of) test programs on the FPGA
  * `qtfs` (quartet test functional simulator) - for validating test programs in software
  * `qtm` (quartet test manager) - for running (batches of) test programs on the FPGA
  * `btfs` (block test functional simulator) - for validating test programs in software
  * `btm` (block test manager) - for running (batches of) test programs on the FPGA

Utility Programs
----------------

  * `csv_to_bin` - convert a numerical CSV into a little-endian array of 32-bit unsigned integers
  * `csv_to_hex` - convert a numerical CSV of values with arbitrary bit width into a Verilog HEX file
  * `yaml_to_json` - convert a YAML configuration file to JSON
