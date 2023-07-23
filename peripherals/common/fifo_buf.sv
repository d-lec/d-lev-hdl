/*
--------------------------------------------------------------------------------

Module: fifo_buf.sv

Function: 
- Implements either a FIFO or a simple buffer with handshake.

Instantiates: 
if (ADDR_W > 0):
- fifo.sv (1x)
  - bin_gray_bin.sv (x2)
    - pipe.sv (x1)
  - ram_dp.sv (x1)
else:
- ss_buf.sv (1x)

Notes:
- See individual components for details.
- ADDR_W=0 gives ss_buf; ADDR_W>0 gives fifo.
- SYNC_W=0 gives sync fifo/buffer; SYNC_W=2 (typ) gives async fifo/buffer.
- For an async fifo, you must constrain flight time (launch to latch) variance 
  or skew among the individual pointer bits from one clock domain to the other
  to be less than one launch clock interval!

--------------------------------------------------------------------------------
*/
module fifo_buf
	#(
	parameter									DATA_W			= 9,
	parameter									ADDR_W			= 0,		// 0=bufffer; else fifo
	parameter									SYNC_W			= 0,		// 0=sync mode; else async re-register depth
	parameter									PROT_WR			= 0,		// 1=write error protection; 0=none
	parameter									PROT_RD			= 0,		// 1=read error protection; 0=none
	parameter									REG_OUT			= 0  		// 1=enable output registering; 0=none
	)
	(
	// reset
	input		logic								rst_i,						// async. reset, active high
	// write side
	input		logic								wr_clk_i,					// write clock
	input		logic	[DATA_W-1:0]			wr_data_i,					// write data
	input		logic								wr_i,							// write, active high
	output	logic								wr_rdy_o,					// write ready, active high
	// read side
	input		logic								rd_clk_i,					// read clock
	output	logic	[DATA_W-1:0]			rd_data_o,					// read data
	input		logic								rd_i,							// read, active high
	output	logic								rd_rdy_o						// read ready, active high
	);



	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	// None.


	/*
	================
	== code start ==
	================
	*/

	generate
		if ( ADDR_W ) begin  // FIFO

			fifo
			#(
			.DATA_W				( DATA_W ),
			.ADDR_W				( ADDR_W ),
			.SYNC_W				( SYNC_W ),
			.PROT_WR				( PROT_WR ),
			.PROT_RD				( PROT_RD ),
			.REG_OUT				( REG_OUT )
			)
			fifo_inst
			(
			.*
			);
			
		end else begin  // buffer
		
			ss_buf
			#(
			.DATA_W				( DATA_W ),
			.SYNC_W				( SYNC_W ),
			.PROT_WR				( PROT_WR ),
			.PROT_RD				( PROT_RD ),
			.REG_OUT				( REG_OUT )
			)
			ss_buf_inst
			(
			.*
			);

		end
	endgenerate

endmodule
