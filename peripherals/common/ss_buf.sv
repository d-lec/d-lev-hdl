/*
--------------------------------------------------------------------------------

Module: ss_buf.sv

Function: 
- Implements a FIFO-like single buffer with dual slave interfaces.

Instantiates: 
- Nothing.

Notes:
- Main use is as RBUS register glue to replace a FIFO.
- Not meant for continuous operation like a FIFO, but to transfer a single
  datum from one side to another in a cha-cha handshake fashion.
- Read when not ready doesn't hurt read state if PROT_RD=1.
- Write when not ready doesn't hurt write state if PROT_WR=1.
- Parameterizable data width, sync/async mode, state protections, 
  and output (ready) registering.
- Write data is always latched at write enable.

--------------------------------------------------------------------------------
*/
module ss_buf
	#(
	parameter									DATA_W			= 8,
	parameter									SYNC_W 			= 2,		// number of resync regs (0 to defeat)
	parameter									PROT_WR			= 1,		// 1=write state protection; 0=none
	parameter									PROT_RD			= 1,		// 1=read state protection; 0=none
	parameter									REG_OUT			= 1  		// 1=enable output (ready) registering; 0=none
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
	logic											wr_en, rd_en;
	logic											wr_rdy, rd_rdy;
	logic											wr_st, rd_st;
	logic											wr_st_xover, rd_st_xover;
	logic				[SYNC_W-1:0]			wr_st_sr, rd_st_sr;


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

	// prohibit state change errors if configured to do so
	always_comb wr_en = ( PROT_WR ) ? ( wr_i && wr_rdy ) : wr_i;

	// form the local state & latch data
	always_ff @ ( posedge wr_clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			wr_st <= 0;
			rd_data_o <= 0;
		end else begin
			if ( wr_en ) begin
				wr_st <= !wr_st;
				rd_data_o <= wr_data_i;
			end
		end
	end

	// optional resync registering
	generate
		if ( SYNC_W ) begin  // w/ regs
			always_ff @ ( posedge wr_clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					rd_st_sr <= 0;
				end else begin
					rd_st_sr <= SYNC_W'( { rd_st_sr, rd_st } );
				end
			end
			always_comb rd_st_xover = rd_st_sr[SYNC_W-1];
		end else begin  // w/o regs
			always_comb rd_st_xover = rd_st;
		end
	endgenerate

	// state calc
	always_comb wr_rdy = ( wr_st == rd_st_xover );

	// optional ready output registering
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

	// prohibit state change errors if configured to do so
	always_comb rd_en = ( PROT_RD ) ? ( rd_i && rd_rdy ) : rd_i;

	// form the local state
	always_ff @ ( posedge rd_clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			rd_st <= 0;
		end else begin
			if ( rd_en ) begin
				rd_st <= !rd_st;
			end
		end
	end

	// optional resync registering
	generate
		if ( SYNC_W ) begin  // w/ regs
			always_ff @ ( posedge rd_clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					wr_st_sr <= 0;
				end else begin
					wr_st_sr <= SYNC_W'( { wr_st_sr, wr_st } );
				end
			end
			always_comb wr_st_xover = wr_st_sr[SYNC_W-1];
		end else begin  // w/o regs
			always_comb wr_st_xover = wr_st;
		end
	endgenerate

	// state calc
	always_comb rd_rdy = ( rd_st != wr_st_xover );

	// optional ready output registering
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



endmodule
