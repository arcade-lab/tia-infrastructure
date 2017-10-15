.PHONY: all clean reparametrize asic_package

all: pets_functionality.bit

#####################
# Reparametrization #
#####################

# Use the YAML parameters file to generate hardware parameters.
reparametrize:
	yaml_to_json parameters.yaml platform.json
	scripts/python/generate_knob_parameters platform.json scripts/res/knob_parameters.svh.template src/knob_parameters.svh

#######################################
# Zynq FPGA Bitstreams and Deployment #
#######################################

# --- Processing Element Test System (pets) ---

# Make sure the environment variable for the underlying FPGA platform is defined.
check_fpga_platform:
ifndef TIA_FPGA_PLATFORM
	$(error TIA_FPGA_PLATFORM must be defined.)
endif

# pets functionality.
pets_functionality.bit: | reparametrize check_fpga_platform
	scripts/sh/build_pets_functionality_bitstream.sh $(TIA_FPGA_PLATFORM)
deploy_pets_functionality_bitstream: pets_functionality.bit
	scripts/sh/deploy_pets_functionality_bitstream.sh

# pets performance.
pets_performance.bit: | reparametrize
	scripts/sh/build_pets_performance_bitstream.sh $(TIA_FPGA_PLATFORM)
deploy_pets_performance_bitstream: pets_performance.bit
	scripts/sh/deploy_pets_performance_bitstream.sh

# Outer loops for pets (multiple targets defined in the configurations directory).
configurations_pets_functionality:
	scripts/sh/build_configurations_pets_functionality.sh
configurations_pets_performance:
	scripts/sh/build_configurations_pets_performance.sh

# --- Quartet Test System (qts) ---

# qts functionality.
qts_functionality.bit: | reparametrize check_fpga_platform
	scripts/sh/build_qts_functionality_bitstream.sh $(TIA_FPGA_PLATFORM)
deploy_qts_functionality_bitstream: qts_functionality.bit
	scripts/sh/deploy_qts_functionality_bitstream.sh

# qts performance.
qts_performance.bit: | reparametrize check_fpga_platform
	scripts/sh/build_qts_performance_bitstream.sh $(TIA_FPGA_PLATFORM)
deploy_qts_performance_bitstream: qts_performance.bit
	scripts/sh/deploy_qts_performance_bitstream.sh

# Outer loops for qts (multiple targets defined in the configurations directory).
configurations_qts_functionality:
	scripts/sh/build_configurations_qts_functionality.sh
configurations_qts_performance:
	scripts/sh/build_configurations_qts_performance.sh

# --- Block Test System (bts) ---

# bts functionality.
bts_functionality.bit: | reparametrize check_fpga_platform
	scripts/sh/build_bts_functionality_bitstream.sh $(TIA_FPGA_PLATFORM)
deploy_bts_functionality_bitstream: bts_functionality.bit
	scripts/sh/deploy_bts_functionality_bitstream.sh

# bts performance.
bts_performance.bit: | reparametrize check_fpga_platform
	scripts/sh/build_bts_performance_bitstream.sh $(TIA_FPGA_PLATFORM)
deploy_bts_performance_bitstream: bts_performance.bit
	scripts/sh/deploy_bts_performance_bitstream.sh

# Outer loops for bts (multiple targets defined in the configurations directory).
configurations_bts_functionality:
	scripts/sh/build_configurations_bts_functionality.sh
configurations_bts_performance:
	scripts/sh/build_configurations_bts_performance.sh


###############
# Testbenches #
###############

# Xilinx compiler toolchain.
COMPILER = xvlog
SIMULATOR = xelab

# Set the compiler to handle SystemVerilog and have verbose output.
COMPILER_FLAGS = -sv -v 2 -d SIMULATION

# Enable verbose simulator output.
SIMULATOR_FLAGS = -v 2

# --- Testbenches ---

# Channel testbench sources.
SWITCH_ROUTER_SRC = src/interconnect/*.sv
SWITCH_ROUTER_TB_SRC = tb/switch_router_tb.sv
PROCESSING_ELEMENT_SRC = src/processing_element/*.sv src/core/*.sv src/control/*.sv src/datapath/*.sv src/instruction/*.sv src/interconnect/*.sv src/memory/*.sv src/mmio/*.sv
PROCESSING_ELEMENT_TB_SRC = tb/processing_element_tb.sv
NETLIST_TB_SRC = tb/netlist_tb.sv
QUARTET_SRC = src/quartet/*.sv src/processing_element/*.sv src/core/*.sv src/control/*.sv src/datapath/*.sv src/instruction/*.sv src/interconnect/*.sv src/memory/*.sv src/mmio/*.sv
QUARTET_TB_SRC = tb/quartet_tb.sv
BLOCK_SRC = src/block/*.sv src/quartet/*.sv src/processing_element/*.sv src/core/*.sv src/control/*.sv src/datapath/*.sv src/instruction/*.sv src/interconnect/*.sv src/memory/*.sv src/mmio/*.sv
BLOCK_TB_SRC = tb/block_tb.sv

# --- Microbenchmark Testbench Recipes ---

# Processing element.

bst_vcd: | reparametrize
	tia_as platform.json ../tests/processing_element_tests/bst/bst.tia -x program.hex
	csv_to_hex 32 32768 ../tests/processing_element_tests/bst/input_data.csv input_data.hex
	$(COMPILER) $(COMPILER_FLAGS) $(PROCESSING_ELEMENT_TB_SRC) $(PROCESSING_ELEMENT_SRC)
	$(SIMULATOR) -R processing_element_tb

gcd_vcd: | reparametrize
	tia_as platform.json ../tests/processing_element_tests/gcd/gcd.tia -x program.hex
	csv_to_hex 32 32768 ../tests/processing_element_tests/gcd/input_data.csv input_data.hex
	$(COMPILER) $(COMPILER_FLAGS) $(PROCESSING_ELEMENT_TB_SRC) $(PROCESSING_ELEMENT_SRC)
	$(SIMULATOR) -R processing_element_tb

mean_vcd: | reparametrize
	tia_as platform.json ../tests/processing_element_tests/mean/mean.tia -x program.hex
	csv_to_hex 32 32768 ../tests/processing_element_tests/mean/input_data.csv input_data.hex
	$(COMPILER) $(COMPILER_FLAGS) $(PROCESSING_ELEMENT_TB_SRC) $(PROCESSING_ELEMENT_SRC)
	$(SIMULATOR) -R processing_element_tb

multiplication_vcd: | reparametrize
	tia_as platform.json ../tests/processing_element_tests/multiplication/multiplication.tia -x program.hex
	csv_to_hex 32 32768 ../tests/processing_element_tests/multiplication/input_data.csv input_data.hex
	$(COMPILER) $(COMPILER_FLAGS) $(PROCESSING_ELEMENT_TB_SRC) $(PROCESSING_ELEMENT_SRC)
	$(SIMULATOR) -R processing_element_tb

# Quartet.

arg_max_vcd: | reparametrize
	tia_as platform.json ../tests/quartet_tests/arg_max/arg_max.tia -x program.hex
	csv_to_hex 32 32768 ../tests/quartet_tests/arg_max/input_data.csv input_data.hex
	$(COMPILER) $(COMPILER_FLAGS) $(QUARTET_TB_SRC) $(QUARTET_SRC)
	$(SIMULATOR) -R quartet_tb

dot_product_vcd: | reparametrize
	tia_as platform.json ../tests/quartet_tests/dot_product/dot_product.tia -x program.hex
	csv_to_hex 32 32768 ../tests/quartet_tests/dot_product/input_data.csv input_data.hex
	$(COMPILER) $(COMPILER_FLAGS) $(QUARTET_TB_SRC) $(QUARTET_SRC)
	$(SIMULATOR) -R quartet_tb

filter_vcd: | reparametrize
	tia_as platform.json ../tests/quartet_tests/filter/filter.tia -x program.hex
	csv_to_hex 32 32768 ../tests/quartet_tests/filter/input_data.csv input_data.hex
	$(COMPILER) $(COMPILER_FLAGS) $(QUARTET_TB_SRC) $(QUARTET_SRC)
	$(SIMULATOR) -R quartet_tb

merge_vcd: | reparametrize
	tia_as platform.json ../tests/quartet_tests/merge/merge.tia -x program.hex
	csv_to_hex 32 32768 ../tests/quartet_tests/merge/input_data.csv input_data.hex
	$(COMPILER) $(COMPILER_FLAGS) $(QUARTET_TB_SRC) $(QUARTET_SRC)
	$(SIMULATOR) -R quartet_tb

stream_vcd: | reparametrize
	tia_as platform.json ../tests/quartet_tests/stream/stream.tia -x program.hex
	csv_to_hex 32 32768 ../tests/quartet_tests/stream/input_data.csv input_data.hex
	$(COMPILER) $(COMPILER_FLAGS) $(QUARTET_TB_SRC) $(QUARTET_SRC)
	$(SIMULATOR) -R quartet_tb

string_search_vcd: | reparametrize
	tia_as platform.json ../tests/quartet_tests/string_search/string_search.tia -x program.hex
	csv_to_hex 32 32768 ../tests/quartet_tests/string_search/input_data.csv input_data.hex
	$(COMPILER) $(COMPILER_FLAGS) $(QUARTET_TB_SRC) $(QUARTET_SRC)
	$(SIMULATOR) -R quartet_tb

udiv_vcd: | reparametrize
	tia_as platform.json ../tests/quartet_tests/udiv/udiv.tia -x program.hex
	csv_to_hex 32 32768 ../tests/quartet_tests/udiv/input_data.csv input_data.hex
	$(COMPILER) $(COMPILER_FLAGS) $(QUARTET_TB_SRC) $(QUARTET_SRC)
	$(SIMULATOR) -R quartet_tb

# Block.

wide_merge_vcd: | reparametrize
	tia_as platform.json ../tests/block_tests/wide_merge/wide_merge.tia -x program.hex
	csv_to_hex 32 32768 ../tests/block_tests/wide_merge/input_data.csv input_data.hex
	$(COMPILER) $(COMPILER_FLAGS) $(BLOCK_TB_SRC) $(BLOCK_SRC)
	$(SIMULATOR) -R block_tb

###########
# Cleanup #
###########

# Cleans both FPGA work and testbenches.
clean:
	rm -fv *.log
	rm -fv *.vcd
	rm -rfv asic_package
	find . -name '.Xil' | xargs rm -frv
	find . -name 'xvlog*' | xargs rm -frv
	find . -name 'xsim*' | xargs rm -frv
	find . -name 'xelab*' | xargs rm -frv
	find . -name 'xgui*' | xargs rm -frv
	find . -name 'webtalk*' | xargs rm -frv
	find . -name 'component.xml' | xargs rm -fv
	rm -fv platform.json
	rm -frv workspace
	rm -fv *.bit
	rm -fv vivado*.log vivado*.jou
	rm -fv vivado_packaging_log.txt
	rm -fv vivado_build_log.txt
	rm -fv power_report.txt
	rm -fv timing_report.txt
	rm -fv utilization_report.txt
	rm -fv integer_frequency.txt
	rm -fv float_frequency.txt
	rm -fv *.hex *.bin
	rm -fv backup_parameters.yaml
