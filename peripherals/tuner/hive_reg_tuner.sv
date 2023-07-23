/*
--------------------------------------------------------------------------------

Module: hive_reg_tuner

Function: 
- LED tuner interface.

Instantiates:
- (1x) led_tuner.sv
- (1x) hive_reg_base.sv

Notes:
- See individual components for details.

--------------------------------------------------------------------------------
*/

module hive_reg_tuner
	#(
	parameter								DATA_W				= 24,		// parallel data width (bits)
	parameter								LOAD_MIN				= 31,		// minimum load value
	parameter								NOISE_W				= 5,		// noise vector width (bits)
	parameter								LFSR_W				= 25		// LFSR shift register width, 3 to 168
	)
	(
	// clocks & resets
	input		logic							clk_i,							// clock
	input		logic							rst_i,							// async. reset, active hi
	// rbus interface
	input		logic	[RBUS_ADDR_W-1:0]	rbus_addr_i,					// address
	input		logic							rbus_wr_i,						// data write enable, active high
	input		logic							rbus_rd_i,						// data read enable, active high
	input		logic	[ALU_W-1:0]			rbus_wr_data_i,				// write data
	output	logic	[ALU_W-1:0]			rbus_rd_data_o,				// read data
	// serial interface
	output	logic							scl_o,							// serial clock
	output	logic							sda_o,							// serial data
	output	logic							le_o,								// latch enable, active high
	output	logic							oe_o								// output enable, active low
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/	
	import hive_params::*; 
	import hive_defines::*; 
	//
	logic										wr, rd, csn;
	logic										busy, pulse;
	logic		[ALU_W-1:0]					rd_data, wr_data;

	
	/*
	================
	== code start ==
	================
	*/


	// LED tuner
	led_tuner
	#(
	.DATA_W				( DATA_W )
	)
	led_tuner
	(
	.*,
	.wr_i					( wr ),
	.mode_i				( wr_data[24] ),
	.data_i				( wr_data[23:0] ),
	.en_i					( pulse ),
	.busy_o				( busy )
	);

	pulse_gen
	#(
	.LOAD_MIN			( LOAD_MIN ),
	.NOISE_W				( NOISE_W ),
	.LFSR_W				( LFSR_W )
	)
	pulse_gen
	(
	.*,
	.en_i					( busy ),
	.pulse_o				( pulse )
	);
	
	
	// combine read data
	always_comb rd_data = { busy, {(ALU_W-1){1'b0}} };

	// rbus register
	hive_reg_base
	#(
	.DATA_W			( ALU_W ),
	.ADDR_W			( RBUS_ADDR_W ),
	.ADDR				( `RBUS_TUNER ),
	.WR_MODE			( "THRU" ),
	.RD_MODE			( "THRU" )
	)
	reg_tuner
	(
	.*,
	.reg_rd_o		(  ),  // unused
	.reg_wr_o		( wr ),
	.reg_data_o		( wr_data ),
	.reg_data_i		( rd_data )
	);

	
endmodule
