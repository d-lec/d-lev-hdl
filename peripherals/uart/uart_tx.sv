/*
--------------------------------------------------------------------------------

Module: uart_tx

Function: 
- Forms the TX side of a DATA_W,n,STOP_BITS RS232 UART.

Instantiates:
- (1x) ddfs.sv

Notes:
- Serial data is non-inverted; quiescent serial state is high (assumes 
  external inverting buffer).
- Bits are in this order (@ serial port of this module, line s/b inverted): 
  - 1 start bit (low), 
  - DATA_W data bits (LSb first, MSb last), 
  - 1 or more stop bits (high).
- Parallel bus master interface requires a FIFO type slave.
- Parameterized data width.
- Parameterized stop bits.
- Parameterized system clock and baud rate.

--------------------------------------------------------------------------------
*/

module uart_tx
	#(
	parameter								DATA_W				= 8,		// parallel data width (bits)
	parameter								STOP_BITS 			= 1,		// number of stop bits
	parameter	real						CLK_HZ				= 160000000,	// system clock rate (Hz)
	parameter	real						BAUD_HZ				= 115200	// baud rate (Hz)
	)
	(
	// clocks & resets
	input		logic							clk_i,							// clock
	input		logic							rst_i,							// async. reset, active hi
	// fifo (bus master) handshake
	input		logic							rd_rdy_i,						// read ready, active hi
	output	logic							rd_o,								// read, active hi
	// data interfaces
	input		logic	[DATA_W-1:0]		data_i,							// data
	output	logic							tx_o								// serial data
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	localparam								BIT_MAX 				= STOP_BITS+DATA_W+1;
	localparam								BIT_W 				= $clog2( BIT_MAX+1 );
	localparam								SR_W 					= DATA_W+1;
	//
	logic				[BIT_W-1:0]			bit_dc;
	//
	logic				[SR_W-1:0]			data_sr;
	logic										baud_f;
	logic										idle_f;
	logic										rd_f;


	/*
	================
	== code start ==
	================
	*/


	// ddfs baud generator
	ddfs
	#(
	.INC_W				( 8 ),  // 8 here gives ~1% timing
	.CLK_FREQ			( CLK_HZ ),
	.OUT_FREQ			( BAUD_HZ )
	)
	ddfs_inst
	(
	.*,
	.en_i					( !idle_f ),
	.sq_o					(  ),  // unused
	.rise_o				(  ),  // unused
	.fall_o				( baud_f )
	);


	// decode flag
	always_comb rd_f = ( idle_f && rd_rdy_i );

	// output strobe
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			rd_o <= 0;
		end else begin
			rd_o <= rd_f;
		end
	end

	// form the bit_dc down-counter, do parallel => serial conversion
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			bit_dc <= 0;
			data_sr <= '1;
		end else begin
			if ( rd_f ) begin
				bit_dc <= BIT_W'( BIT_MAX );
				data_sr <= { data_i, 1'b0 };
			end else if ( baud_f ) begin
				bit_dc <= bit_dc - 1'b1;
				data_sr <= { 1'b1, data_sr[SR_W-1:1] };
			end
		end
	end

	// decode flag, output serial data
	always_comb idle_f = ( !bit_dc );
	always_comb tx_o = data_sr[0];

endmodule
