/*
--------------------------------------------------------------------------------

Module: hive_reg_midi

Function: 
- TX DATA_W,n,1 RS232 UART.

Instantiates:
- (1x) hive_base_reg.sv
  - (1x) in_cond.sv
- (1x) uart_tx.sv
  - (1x) ddfs.sv
- (1x) fifo.sv
if (FIFO_ADDR_W != 0):
- (1x) fifo.sv
  - (2x) bin_gray_bin.sv
  - (2x) pipe.sv
  - (1x) ram_dp.sv
else:
- (1x) ss_buf.sv

Notes:
- See individual components for details.

--------------------------------------------------------------------------------
*/

module hive_reg_midi
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
	output	logic							midi_tx_o						// serial data
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/	
	import hive_params::*; 
	import hive_defines::*; 
	//
	logic										reg_wr;
	logic			[ALU_W-1:0]				reg_wr_data, reg_rd_data;
	logic										wr_rdy;
	logic			[UART_W-1:0]			rd_data;
	logic										rd, rd_rdy;

	
	/*
	================
	== code start ==
	================
	*/


	// tx rbus register
	hive_reg_base
	#(
	.DATA_W			( ALU_W ),
	.ADDR_W			( RBUS_ADDR_W ),
	.ADDR				( `RBUS_MIDI ),
	.WR_MODE			( "THRU" ),
	.RD_MODE			( "THRU" )
	)
	reg_midi
	(
	.*,
	.reg_wr_o		( reg_wr ),
	.reg_rd_o		(  ),  // unused
	.reg_data_o		( reg_wr_data ),
	.reg_data_i		( reg_rd_data )
	);

	// combine read data
	always_comb reg_rd_data = { rd_rdy, {(ALU_W-1){1'b0}} };


	// tx fifo / buf
	fifo_buf
	#(
	.DATA_W				( MIDI_W ),
	.ADDR_W				( MIDI_TX_FIFO_ADDR_W ),
	.SYNC_W				( 0 ),
	.PROT_WR				( 0 ),
	.PROT_RD				( 0 ),
	.REG_OUT				( 1 )  // for speed-up
	)
	midi_tx_fifo_buf_inst
	(
	.*,
	.wr_clk_i			( clk_i ),
	.wr_data_i			( reg_wr_data[MIDI_W-1:0] ),
	.wr_i					( reg_wr ),
	.wr_rdy_o			( wr_rdy ),
	.rd_clk_i			( clk_i ),
	.rd_data_o			( rd_data ),
	.rd_i					( rd ),
	.rd_rdy_o			( rd_rdy )
	);
			

	// midi_tx
	uart_tx
	#(
	.DATA_W				( MIDI_W ),
	.STOP_BITS 			( MIDI_TX_STOP_BITS ),
	.CLK_HZ				( CORE_HZ ),
	.BAUD_HZ				( MIDI_BAUD_HZ )
	)
	midi_tx_inst
	(
	.*,
	.rd_rdy_i			( rd_rdy ),
	.rd_o					( rd ),
	.data_i				( rd_data ),
	.tx_o					( midi_tx_o )
	);

	
endmodule
