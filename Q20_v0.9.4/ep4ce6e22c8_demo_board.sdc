## Generated SDC file "ep4ce6e22c8_demo_board.out.sdc"

## Copyright (C) 1991-2011 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 10.1 Build 197 01/19/2011 Service Pack 1 SJ Web Edition"

## DATE    "Thu Sep 01 10:26:09 2016"

##
## DEVICE  "EP4CE6E22C8"
##


#**************************************************************
# Time Information
#**************************************************************
set_time_format -unit ns -decimal_places 3


#**************************************************************
# Create Clock
#**************************************************************
create_clock -name {clk_50m_i} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk_50m_i}]


#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks

#**************************************************************
# Set Clock Latency
#**************************************************************


#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************
set_false_path -from  [get_clocks {clk_50m_i}] -to  [get_clocks {pll_core|altpll_component|auto_generated|pll1|clk[0]}]
set_false_path -from  [get_clocks {clk_50m_i}] -to  [get_clocks {pll_spdif|altpll_component|auto_generated|pll1|clk[0]}]

set_false_path -from [get_clocks {pll_core|altpll_component|auto_generated|pll1|clk[0]}] -to [get_clocks {pll_spdif|altpll_component|auto_generated|pll1|clk[0]}]
set_false_path -from [get_clocks {pll_spdif|altpll_component|auto_generated|pll1|clk[0]}] -to [get_clocks {pll_core|altpll_component|auto_generated|pll1|clk[0]}] 

set_false_path -from * -to [get_ports { *_o* }]
set_false_path -from [get_ports { *_i* }] -to *


#**************************************************************
# Set Multicycle Path
#**************************************************************
set_multicycle_path -setup 2 -to [get_fanouts [get_registers {*timing:*|lpf_en*}] -through [get_pins -hierarchical *|*en*]] -end
set_multicycle_path -hold 1 -to [get_fanouts [get_registers {*timing:*|lpf_en*}] -through [get_pins -hierarchical *|*en*]] -end


#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

