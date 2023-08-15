/*
--------------------------------------------------------------------------------

Module: hive_reg_lcd

Function: 
- LCD module interface.

Instantiates:
- (1x) hive_reg_base.sv
  - (1x) in_cond.sv
- (1x) lcd.sv
  - (1x) ddfs.sv
if (FIFO_ADDR_W != 0):
- (1x) fifo.sv
  - (2x) bin_gray_bin.sv
  - (1x) ram_dp.sv
else:
- (1x) ss_buf.sv

Notes:
- See individual components for details.

--------------------------------------------------------------------------------
*/

module hive_reg_lcd
	(
	// clocks & resets
	input		logic								clk_i,							// clock
	input		logic								rst_i,							// async. reset, active hi
	// rbus interface
	input		logic	[RBUS_ADDR_W-1:0]		rbus_addr_i,					// address
	input		logic								rbus_wr_i,						// data write enable, active high
	input		logic								rbus_rd_i,						// data read enable, active high
	input		logic	[ALU_W-1:0]				rbus_wr_data_i,				// write data
	output	logic	[ALU_W-1:0]				rbus_rd_data_o,				// read data
	// LCD interface
	output	logic								lcd_rs_o,						// 0=command; 1=data/addr
	output	logic	[LCD_W-1:0]				lcd_data_o,						// parallel data out
	output	logic								lcd_e_o							// enable strobe, active high
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/	
	import hive_params::*; 
	import hive_defines::*; 
	//
	localparam								FIFO_W				= 1+(LCD_W*2);
	//
	logic										reg_wr;
	logic		[ALU_W-1:0]					reg_rd_data, reg_wr_data;
	logic										wr_rdy;
	logic		[FIFO_W-1:0]				rd_data;
	logic										rd, rd_rdy;

	
	/*
	================
	== code start ==
	================
	*/


	// rbus register
	hive_reg_base
	#(
	.DATA_W			( ALU_W ),
	.ADDR_W			( RBUS_ADDR_W ),
	.ADDR				( `RBUS_LCD ),
	.WR_MODE			( "THRU" ),
	.RD_MODE			( "THRU" )
	)
	reg_lcd
	(
	.*,
	.reg_wr_o		( reg_wr ),
	.reg_rd_o		(  ),  // unused
	.reg_data_o		( reg_wr_data ),
	.reg_data_i		( reg_rd_data )
	);

	// combine read data
	always_comb reg_rd_data = { !wr_rdy, {(ALU_W-1){1'b0}} };


	// tx fifo
	fifo_buf
	#(
	.DATA_W				( FIFO_W ),
	.ADDR_W				( LCD_FIFO_ADDR_W ),
	.SYNC_W				( 0 ),
	.PROT_WR				( 0 ),
	.PROT_RD				( 0 ),
	.REG_OUT				( 1 )  // for speed-up
	)
	lcd_fifo_buf_inst
	(
	.*,
	.wr_clk_i			( clk_i ),
	.wr_data_i			( reg_wr_data[FIFO_W-1:0] ),
	.wr_i					( reg_wr ),
	.wr_rdy_o			( wr_rdy ),
	.rd_clk_i			( clk_i ),
	.rd_data_o			( rd_data ),
	.rd_i					( rd ),
	.rd_rdy_o			( rd_rdy )
	);

			
	// LCD interface
	lcd
	#(
	.LCD_W				( LCD_W ),
	.CLK_HZ				( CORE_HZ ),
	.LCD_HZ				( LCD_HZ )
	)
	lcd_inst
	(
	.*,
	.rsn_i				( rd_data[FIFO_W-1] ),
	.data_i				( rd_data[FIFO_W-2:0] ),
	.rd_rdy_i			( rd_rdy ),
	.rd_o					( rd )
	);


endmodule
