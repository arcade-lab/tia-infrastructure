# Columbia TIA Infrastructure

CS@CU ARCADE Lab

Thomas J. Repetti, Martha A. Kim

Background
==========

This is repository provides infrastructure for designing and programming locally autonomous spatial accelerator architectures.
Specifically, it provides a general purpose spatial accelerator architecture using the [triggered instruction control paradigm](https://dl.acm.org/citation.cfm?id=2485935).
To support research in this field, it includes a draft ISA specification, assembler, functional simulation infrastructure, synthesizable RTL implementation, and Linux and userspace drivers for running small scale spatial arrays on Zynq SoC-FPGAs.

Structure
=========

```
documentation/
    Preliminary ISA specification.
drivers/
    Linux driver and userspace executables.
hardware/
    SystemVerilog RTL implementations and testbenches.
linux_image/
    Utilities for generating bootable Linux images for Zynq SoC-FPGAs.
tests/
    Self-test routines and microbenchmark workloads.
tools/
    Functional simulation and assembler utilities.
yocto/
    Docker-based Yocto toolchain.
```

This preliminary release is structured around test systems for small scale spatial arrays including a single PE test system (`pets`), a 2 x 2 "quartet" array (`qts`) and a 4 x 4 "block" array (`bts`).

* Processing element test system (`pets`)
  - functional simulator: `petfs`
  - bitstreams: `pets_*_.bit`
  - FPGA test manager: `petm`
* Quartet test system (`qts`)
  - functional simulator: `qtfs`
  - bitstreams: `qts_*_.bit`
  - FPGA test manager: `qtm`
* Block test system (`bts')
  - functional simulator: `btfs`
  - bitstreams: `bts_*_.bit`
  - FPGA test manager: `btm`

We also include a general assembler to convert triggered instruction assembly programs into machine code binaries.
To use this assembler, `tia_as`, please run `tia_as -h` for detailed usage instructions.

Requirements
============

* Xilinx Vivado 2017.2 (may support other versions but currently tested with this version)
* Docker
* Python 3.6 or higher
* the following Python packages available to the system Python interpreter:
  - docopt
  - numpy
  - pandas
  - PyYAML
  - paramiko
  - scp (based on paramiko)
  - tqdm

Getting Started
===============

To begin, make sure the various submodules (external libraries, primarily) we will be using are set up:

```
git submodule update --init --recursive
```

Next, make sure the following environment variables are set:

```
export TIA_ROOT_DIR=/path/to/cloned/repository
export TIA_LINUX_IMAGE_DIR=$TIA_ROOT_DIR/linux_image
export TIA_DRIVERS_DIR=$TIA_ROOT_DIR/drivers
export TIA_HARDWARE_DIR=$TIA_ROOT_DIR/hardware
export TIA_TESTS_DIR=$TIA_ROOT_DIR/tests
export TIA_TOOLS_DIR=$TIA_ROOT_DIR/tools
export TIA_FPGA_PLATFORM=zedboard
```

The system also requires that the tools directory is added to our `$PATH`.

At this point all of the functional simulation and assembler infrastructure within the tools directory should be functional.
For all of the utilities in the `tools` subdirectory, it is possible to view a detailed description of functionality by running the CLI utility in question with the `-h` or `--help` flags.

To build Linux images, device drivers and executables, we will be using the Yocto build system.
Since Yocto has very particular requirements about the system's C compiler and libraries, we have opted for performing Yocto builds from within a Docker container.
To get the Docker image ready, navigate to the `yocto` subdirectory and run:

```
./build_docker_image.sh
```

With the Docker image in hand, we can now use Yocto to set up a bootable SD card image for a Zynq system.
To do this, navigate to the `linux_image` subdirectory and run:

```
./build_image.sh
```

After the raw `image.direct` image file has been created, we can then finalize the image (performing some tweaks to the U-Boot and root file system) with:

```
sudo ./finalize_image.sh image.direct zedboard
```

We can then flash the image to a SD card block device using:

```
sudo ./flash_image.sh image.direct /dev/SD_CARD_BLOCK_DEVICE
```

Next we need to set up the SDK Yocto generated for our system.
From the `linux_image` directory running the `install_sdk.sh` script as root will set up the "Poky" SDK for us.

With the SDK installed we must again update the following environment variable (assuming the SDK was installed in `/opt/poky`):

```
export TIA_POKY_SDK_ENVIRONMENT_SCRIPT='/opt/poky/2.3.2/environment-setup-cortexa9hf-neon-poky-linux-gnueabi'
```

It is now possible to build drivers and userspace executables manually from their `drivers` subdirectories using their respective `build.sh` scripts.
These scripts invoke the `Makefile`s from within the Yocto SDK environment.
Later, we will discuss how these builds can be automated using the `petm`, `qtm` and `btm` test management utilites for testing on real hardware.
The experimental Linux driver `tia_ctrl_uio` can be loaded from a kernel module, however, the userspace executables are also, for now, compatible with the `generic-uio` kernel module already included in the main kernel tree, so it is not strictly necessary to use `tia_ctrl_uio.ko`.

Now that the toolchain has been set up, we can start exploring the RTL and testbench infrastructure in the `hardware` subdirectory.
From within the `hardware` directory, the `parameters.yaml` file can be used to set the architectural parameters of the target system.
Once the `parameters.yaml` file has been modified `make reparametrize` will reparametrize the RTL and produce a `platform.json` file that describes the hardware target and serves as an input to the assembler, functional simulator and userspace executables.

Using this `platform.json` file, we can now run tests from the functional simulator.
For example, navigating to the `tests` subdirectory we could run the merge sort quartet workload on the `qtfs` functional simulator as follows:

```
qtfs ../hardware/platform.json quartet_tests/merge/merge.tia null quartet_tests/merge/input_data.csv quartet_tests/merge/expected_output_data.csv
```

The third "channels" argument is `null`, because in this release we have not included support for our programmable circuit-switched interconnect routers, and therfore the connectivity between processing elements is fixed instead of dynamically defined by channels.
Input and output channels 0, 1, 2, and 3 correspond to the cardinal directions N, E, S, and W, respectively.
In this model, which we refer to as "software" routing, routing is performed by dedicated instructions within each PE's program.

Back in the `hardware` directory, to run test binaries on the RTL testbench infrastructure, use one of the targets of the form `make [benchmark]_vcd`.
For example, `make bst_vcd` will assemble the `bst.tia` assembly file from the tests directory and prepare the input data for the single processing element testbench to run.
The output will be a cycle-accurate VCD trace of the entire system running the assembled binary.

To begin FPGA prototyping, we can generate bitstreams with the following set of make commands:

```
make [test_system]_functionality_bitstream
make [test_system]_performance_bitstream
```

The test systems can be `pets`, `qts` or `bts` corresponding to PE, quartet and block test systems, respectively.
Functionality targets are meant for quick synthesis to verify the functionality of the test array and disable all implementation optimizations and target 20 MHz.
Performance targets use our automatic timing closure system to synthesis at as high a clock speed as possible.
These targets use aggressive implementation optimization on the FPGA and close in the range of 50 - 120 MHz.

With a bitstream ready, we can now set up our FPGA infrastructure.
Our test utilities assume that the Zynq FPGA is on its own NIC on the test workstation at 192.168.0.2.
Once the Zynq system is booted using the SD card image we built previously, it should be possible to SSH using the `root` password `root` (hence the need for the private subnet) and use the modest userspace Yocto provides to us to verify everything is working.

From the test workstation, we can now invoke our test managers to run tests and (optionally extract performance counter data).
The test mangers (`petm`, `qtm`, and `btm`) all take the bitstream file, clock frquency, platform file and a tests JSON manifest file as arguments.
For example to run the tests from the MICRO paper on a quartet from the main infrastructure directrory.

```
./qtm hardware/qts_functionality.bit 20 hardware/platform.json tests/quartet_tests/microbenchmarks.json
```

This will run the quartet tests from the MICRO publication on the FPGA and, if performance counters are enabled, report pipeline behavior back to the user.
As mentioned above, this utility will also build and transfer the corresponding userspace executable automatically using subprocesses.

While we did not include the implementation scripts specific to the proprietary standard cell PDK we used in our MICRO paper, the RTL is synthesizable in Design Compiler 2013.1 and above.
In particular, the `processing_element_top`, `quartet_top` and `block_top` modules are all Verilog-compatible top-level synthesis targets.
Their corresponding `*_wrapper` modules allow for post-synthesis validation using the standard SystemVerilog testbenchs.

Questions/Comments
==================

Please direct any questions or comments to the maintainer, trepetti@cs.columbia.edu.

Citing
======

If you find our work useful or use this or a future iteration of this infrastructure, please consider citing the publication in which it appeared:

```
@inproceedings{Repetti:2017:PTP:3123939.3124551,
 author = {Repetti, Thomas J. and Cerqueira, Jo\~{a}o P. and Kim, Martha A. and Seok, Mingoo},
 title = {Pipelining a Triggered Processing Element},
 booktitle = {Proceedings of the 50th Annual IEEE/ACM International Symposium on Microarchitecture},
 series = {MICRO-50 '17},
 year = {2017},
 isbn = {978-1-4503-4952-9},
 location = {Cambridge, Massachusetts},
 pages = {96--108},
 numpages = {13},
 url = {http://doi.acm.org/10.1145/3123939.3124551},
 doi = {10.1145/3123939.3124551},
 acmid = {3124551},
 publisher = {ACM},
 address = {New York, NY, USA},
 keywords = {design-space exploration, low-power design, microarchitecture, pipeline hazards, spatial architectures},
}
```

Acknowledgements
================

The authors gratefully acknowledge support from C-FAR, one of the six SRC STARnet Centers sponsored by MARCO and DARPA and a grant from the National Science Foundation under CCF-1065338.
