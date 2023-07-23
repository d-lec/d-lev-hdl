/*
--------------------------------------------------------------------------------

Module: fifo.sv

Function: 
- Implements a FIFO with parameterizable data width, address width (depth), 
  sync/async mode, pointer protections, and output registering.

Instantiates: 
- bin_gray_bin.sv (x2)
  - pipe.sv (x1)
- ram_dp.sv (x1)

Notes:
- Due to pointer delays, simultaneously writing & reading the same RAM 
  address should never happen, therefore the read-during-write behavior of 
  the synthesized RAM is moot.  Also, configurable read-during-write 
  behavior only applies to a given BRAM port and not to the separate ports
  of dual port BRAM.
- Read when not ready doesn't hurt pointers if PROT_RD=1.
- Write when not ready doesn't hurt pointers if PROT_WR=1.
- One extra bit is used for the pointers to simplify level calculations.
- For an async fifo, you must constrain flight time (launch to latch) variance 
  or skew among the individual pointer bits from one clock domain to the other
  to be less than one launch clock interval!

--------------------------------------------------------------------------------
*/
module fifo
	#(
	parameter									DATA_W			= 9,
	parameter									ADDR_W			= 10,
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
	localparam									PTR_W				= ADDR_W+1;	// extra bit to accomodate pointer calcs
	localparam									CAPACITY			= 2**ADDR_W;	// total words possible to store
	logic											wr_en, rd_en;
	logic											wr_rdy, rd_rdy;
	logic				[PTR_W-1:0]				wr_ptr, rd_ptr;
	logic				[PTR_W-1:0]				wr_level, rd_level;
	logic				[ADDR_W-1:0]			wr_addr, rd_addr;
	logic				[PTR_W-1:0]				wr_ptr_xover, rd_ptr_next, rd_ptr_xover;


	/*
	================
	== code start ==
	================
	*/


	/*
	----------------
	-- write side --
	----------------
	*/

	// prohibit pointer changes @ errors if configured to do so
	always_comb wr_en = ( PROT_WR ) ? ( wr_i && wr_rdy ) : wr_i;

	// form the local pointer up-counter
	always_ff @ ( posedge wr_clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			wr_ptr <= 0;
		end else begin
			if ( wr_en ) begin
				wr_ptr <= wr_ptr + 1'b1;
			end
		end
	end

	// memory address - note: address doesn't use msb
	always_comb wr_addr = ADDR_W'( wr_ptr );

	// fullness calcs
	always_comb wr_level  = wr_ptr - rd_ptr_xover;
	always_comb wr_rdy = ( wr_level != CAPACITY );

	// optional output registering
	generate
		if ( REG_OUT ) begin  // w/ regs
			always_ff @ ( posedge wr_clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					wr_rdy_o <= 0;
				end else begin
					wr_rdy_o <= wr_rdy;
				end
			end
		end else begin  // w/o regs
			always_comb wr_rdy_o = wr_rdy;
		end
	endgenerate
		

	/*
	---------------
	-- read side --
	---------------
	*/

	// prohibit pointer changes @ errors if configured to do so
	always_comb rd_en = ( PROT_RD ) ? ( rd_i && rd_rdy ) : rd_i;

	// form the local pointer up-counter - note: deconstructed counter
	always_comb rd_ptr_next = ( rd_en ) ? rd_ptr + 1'b1 : rd_ptr;
	//
	always_ff @ ( posedge rd_clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			rd_ptr <= 0;
		end else begin
			rd_ptr <= rd_ptr_next;
		end
	end

	// memory read - note: address doesn't use msb
	always_comb rd_addr = ADDR_W'( rd_ptr_next );

	// fullness calcs
	always_comb rd_level = wr_ptr_xover - rd_ptr;
	always_comb rd_rdy = |rd_level;

	// optional output registering
	generate
		if ( REG_OUT ) begin  // w/ regs
			always_ff @ ( posedge rd_clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					rd_rdy_o <= 0;
				end else begin
					rd_rdy_o <= rd_rdy;
				end
			end
		end else begin  // w/o regs
			always_comb rd_rdy_o = rd_rdy;
		end
	endgenerate


	/*
	------------
	-- common --
	------------
	*/

	// write & read pointer crossover
	bin_gray_bin
	#(
	.VECT_W			( PTR_W ),
	.SYNC_W			( SYNC_W )
	)
	wr2rd_inst
	(
	.rst_i			( rst_i ),
	.a_clk_i			( wr_clk_i ),
	.a_i				( wr_ptr ),
	.b_clk_i			( rd_clk_i ),
	.b_o				( wr_ptr_xover )
	);

	bin_gray_bin  
	#(
	.VECT_W			( PTR_W ),
	.SYNC_W			( SYNC_W )
	)
	rd2wr_inst
	(
	.rst_i			( rst_i ),
	.a_clk_i			( rd_clk_i ),
	.a_i				( rd_ptr ),
	.b_clk_i			( wr_clk_i ),
	.b_o				( rd_ptr_xover )
	);
			

	// dp memory
	ram_dp
	#(
	.DATA_W			( DATA_W ),
	.ADDR_W			( ADDR_W ),
	.REG_OUT			( REG_OUT )
	)
	ram_dp_inst
	(
	.*,
	.wr_addr_i		( wr_addr ),
	.wr_en_i			( wr_en ),
	.rd_addr_i		( rd_addr )
	);


endmodule
