# Thanks @true_xark for code review and implementation of Lattice / yosys port
#
# Requirements: yosys, sv2v. both packages need to manually be added to PATH
#
# yosys: 
#   https://github.com/YosysHQ/oss-cad-suite-build/releases
# sv2v:
#   https://github.com/zachjs/sv2v/releases
#
# resources:
#   https://tomverbeure.github.io/2021/01/22/The-Colorlight-i5-as-FPGA-development-board.html
#   https://tomverbeure.github.io/2021/01/18/SPDIF-Output-PMOD.html
#   https://github.com/wuxx/Colorlight-FPGA-Projects
#
# edit pinout in .lpf file

CWD=$(shell pwd)
TARGET=hive
TOP=colorlight_i5_top

SV_SOURCE= \
  ${TOP}.sv \
  ddr_lattice.sv \
  ../Q20_v0.9.4/hive_pkg.sv \
$(filter-out \
  ../peripherals/spdif/spdif_tx_x1.sv \
  ../peripherals/common/ddr_in_altera.sv \
  ../peripherals/common/ddr_out_altera.sv \
, \
  $(wildcard ../top/*.sv) \
  $(wildcard ../core/*.sv) \
  $(wildcard ../peripherals/**/*.sv))

YOSYS_SCRIPT= \
  read_verilog pll_core.v; \
  read_verilog pll_spdif.v; \
  read_verilog -sv out.v; \
  hierarchy -top ${TOP}; \
  synth_ecp5 -abc2 -dff -json ${TARGET}.json

all: out.v pll_core.v pll_spdif.v ${TARGET}.bit 

$(TARGET).json: out.v pll_core.v pll_spdif.v $(MAKEFILE_LIST)
	yosys -l $(TOP).log -p "${YOSYS_SCRIPT}"

$(TARGET)_out.config: $(TARGET).json
	nextpnr-ecp5 --25k --package CABGA381 --speed 6 --json $< --textcfg $@ --lpf $(TOP).lpf --freq 65 --lpf-allow-unconstrained

# Hive Core PLL runs at 180 MHz off a 50MHz core clock.
# Hive SP/DIF PLL runs at 196(?) MHz off a 50MHz core clock.

# These fail in synthesis with the --highres option enabled. Related to 
# https://github.com/YosysHQ/prjtrellis/issues/160 ?

pll_core.v: $(MAKEFILE_LIST)
	ecppll -n pll_core --clkin_name inclk0 --clkout0_name c0 -i 25 --clkout0 180 -f pll_core.v

pll_spdif.v: $(MAKEFILE_LIST)
	ecppll -n pll_spdif --clkin_name inclk0 --clkout0_name c0 -i 25 --clkout0 196.7 -f pll_spdif.v
	
out.v: $(SV_SOURCE) $(MAKEFILE_LIST)
	sv2v -v --top=${TOP} $(SV_SOURCE) -w ${CWD}/$@
	
$(TARGET).bit: $(TARGET)_out.config
	ecppack --compress --svf ${TARGET}.svf $< $@

${TARGET}.svf: ${TARGET}.bit

flash: ${TARGET}.bit
	ecpdap flash write $(TARGET).bit

run: ${TARGET}.bit
	ecpdap program $(TARGET).bit

clean:
	rm -f out.v pll_*.v *.svf *.bit *.config *.json *.log

.PHONY: all prog clean flash
