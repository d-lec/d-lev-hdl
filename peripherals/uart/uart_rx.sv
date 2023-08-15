/*
--------------------------------------------------------------------------------

Module: uart_rx

Function: 
- Forms the RX side of a DATA_W,n,1 RS232 UART.

Instantiates:
- (1x) ddfs.sv

Notes:
- Serial data is non-inverted; quiescent serial state is high (assumes 
  external inverting buffer).
- Bits are in this order (@ serial port of this module, line s/b inverted): 
  - 1 start bit (low), 
  - DATA_W data bits (LSb first, MSb last), 
  - 1 or more stop bits (high).
- Errors are presented simultaneously with the data.
- Start & stop errors are an indication of noise on the line / wrong baud rate.
- Buffer error happens when external data sink doesn't take RX data
  before another byte arrives (data loss).
- Parallel bus master interface requires a FIFO type slave.
- Parameterized data width.
- Parameterized input resync depth.
- Parameterized system clock and baud rate.

--------------------------------------------------------------------------------
*/

module uart_rx
	#(
	parameter								DATA_W				= 8,		// parallel data width (bits)
	parameter								SYNC_W 				= 2,		// number of resync regs (1 or larger)
	parameter	real						CLK_HZ				= 160000000,	// system clock rate (Hz)
	parameter	real						BAUD_HZ				= 115200	// baud rate (Hz)
	)
	(
	// clocks & resets
	input		logic							clk_i,							// clock
	input		logic							rst_i,							// async. reset, active hi
	// fifo (bus master) handshake
	input		logic							wr_rdy_i,						// data ready, active hi
	output	logic							wr_o,								// data write, active hi
	// data interfaces	
	output	logic	[DATA_W-1:0]		data_o,							// data
	input		logic							rx_i,								// serial data
	// debug
	output	logic							line_err_o,						// bad start|stop, active hi
	output	logic							wr_err_o							// write error, active hi
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	localparam								BIT_MAX 				= 1+DATA_W+1;
	localparam								BIT_W 				= $clog2( BIT_MAX+1 );
	localparam								SR_W 					= BIT_MAX;
	//
	logic				[SYNC_W-1:0]		rx_sr;
	//
	logic				[BIT_W-1:0]			bit_dc;
	//
	logic				[SR_W-1:0]			data_sr;
	logic										baud_f;
	logic										idle_f, idle_r;
	logic										start_f;
	logic										done_f;


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
	.rise_o				( baud_f ),
	.fall_o				(  )  // unused
	);


	// resync input
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			rx_sr <= '1;
		end else begin
			rx_sr <= SYNC_W'( { rx_sr, rx_i } );
		end
	end

	// form the bit_dc down-counter, serial => parallel conversion
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			bit_dc <= 0;
			data_sr <= 0;
		end else begin
			if ( start_f ) begin
				bit_dc <= BIT_W'( BIT_MAX );
			end else if ( baud_f ) begin
				bit_dc <= bit_dc - 1'b1;
				data_sr <= { rx_sr[SYNC_W-1], data_sr[SR_W-1:1] };
			end
		end
	end

	// decode flags
	always_comb idle_f = ( !bit_dc );
	always_comb start_f = ( idle_f && !rx_sr[SYNC_W-1] );

	// detect rising edge
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			idle_r <= '1;
		end else begin
			idle_r <= idle_f;
		end
	end

	// decode flag
	always_comb done_f = ( idle_f && !idle_r );

	// output strobes
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			wr_o <= 0;
			wr_err_o <= 0;
			line_err_o <= 0;
		end else begin
			wr_o <= ( done_f && wr_rdy_i );
			wr_err_o <= ( done_f && !wr_rdy_i );
			line_err_o <= ( done_f && ( !data_sr[SR_W-1] || data_sr[0] ) );
		end
	end

	// output data
	always_comb data_o = data_sr[DATA_W:1];

endmodule
