/*
--------------------------------------------------------------------------------

Module: hive_reg_uart_rx

Function: 
- RX DATA_W,n,1 RS232 UART.

Instantiates:
- (1x) hive_base_reg.sv
  - (1x) in_cond.sv
- (1x) uart_rx.sv
  - (1x) ddfs.sv
- (1x) fifo_buf.sv
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

module hive_reg_uart_rx
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
	input		logic							uart_rx_i,						// serial data
	// debug
	output	logic							line_err_o,						// bad start|stop, active hi
	output	logic							wr_err_o							// write error, active hi
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/	
	import hive_params::*; 
	import hive_defines::*; 
	//
	logic										reg_rd;
	logic			[ALU_W-1:0]				reg_rd_data;
	logic										rd_rdy;
	logic			[UART_W-1:0]			rd_data, wr_data;
	logic										wr, wr_rdy;
	logic										rd_rdy_r;

	
	/*
	================
	== code start ==
	================
	*/


	// uart_rx
	uart_rx
	#(
	.DATA_W				( UART_W ),
	.SYNC_W 				( SYNC_W ),
	.CLK_HZ				( CORE_HZ ),
	.BAUD_HZ				( UART_BAUD_HZ )
	)
	uart_rx_inst
	(
	.*,
	.wr_rdy_i			( wr_rdy ),
	.wr_o					( wr ),
	.data_o				( wr_data ),
	.rx_i					( uart_rx_i )
	);
			

	// rx fifo / buf
	fifo_buf
	#(
	.DATA_W				( UART_W ),
	.ADDR_W				( UART_RX_FIFO_ADDR_W ),
	.SYNC_W				( 0 ),
	.PROT_WR				( 0 ),
	.PROT_RD				( 0 ),
	.REG_OUT				( 1 )  // for speed-up
	)
	uart_rx_fifo_buf_inst
	(
	.*,
	.wr_clk_i			( clk_i ),
	.wr_data_i			( wr_data ),
	.wr_i					( wr ),
	.wr_rdy_o			( wr_rdy ),
	.rd_clk_i			( clk_i ),
	.rd_data_o			( rd_data ),
	.rd_i					( reg_rd && rd_rdy ),  // protect state
	.rd_rdy_o			( rd_rdy )
	);

	
	// delay one clock to match register pipeline
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			rd_rdy_r <= 0;
		end else begin
			rd_rdy_r <= rd_rdy;
		end
	end


	// rx rbus register
	hive_reg_base
	#(
	.DATA_W			( ALU_W ),
	.ADDR_W			( RBUS_ADDR_W ),
	.ADDR				( `RBUS_UART_RX ),
	.WR_MODE			( "THRU" ),
	.RD_MODE			( "THRU" )
	)
	reg_uart_rx
	(
	.*,
	.reg_wr_o		(  ),  // unused
	.reg_rd_o		( reg_rd ),
	.reg_data_o		(  ),  // unused
	.reg_data_i		( reg_rd_data )
	);


	// combine read data
	always_comb reg_rd_data = { !rd_rdy_r, {(ALU_W-UART_W-1){1'b0}}, rd_data };

	
endmodule
