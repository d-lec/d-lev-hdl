/*
--------------------------------------------------------------------------------

Module: hive_reg_spi

Function: 
- Forms a SPI bus master interface.

Instantiates:
- (1x) spi_master.sv
- (1x) hive_reg_base.sv

Notes:
- See individual components for details.
- Serial loopback does not disconnect serial TX interface.

--------------------------------------------------------------------------------
*/

module hive_reg_spi
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
	output	logic							scs_o,							// serial chip select, active low
	output	logic							sdo_o,							// serial data
	input		logic							sdi_i,							// serial data
	// debug
	input		logic							loop_i							// serial loopback enable, active hi
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/	
	import hive_params::*; 
	import hive_defines::*; 
	//
	logic										wr, rd, busy, csn;
	logic		[ALU_W-1:0]					rd_data, wr_data;

	
	/*
	================
	== code start ==
	================
	*/


	// spi master
	spi_master
	#(
	.DATA_W				( SPI_W ),
	.PHASE_CLKS			( SPI_PHASE_CLKS )
	)
	spi_master_inst
	(
	.*,
	.wr_i					( wr ),
	.busy_o				( rd_data[ALU_W-1] ),
	.csn_i				( wr_data[SPI_W] ),
	.data_i				( wr_data[SPI_W-1:0] ),
	.data_o				( rd_data[SPI_W-1:0] ),
	.sdi_i				( loop_i ? sdo_o : sdi_i )
	);

	// default drive to remove synthesis warning
	always_comb rd_data[ALU_W-2:SPI_W] = 0;

	// rbus register
	hive_reg_base
	#(
	.DATA_W			( ALU_W ),
	.ADDR_W			( RBUS_ADDR_W ),
	.ADDR				( `RBUS_SPI ),
	.WR_MODE			( "THRU" ),
	.RD_MODE			( "THRU" )
	)
	reg_spi
	(
	.*,
	.reg_rd_o		(  ),  // unused
	.reg_wr_o		( wr ),
	.reg_data_o		( wr_data ),
	.reg_data_i		( rd_data )
	);

	
endmodule
