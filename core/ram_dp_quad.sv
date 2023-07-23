/*
--------------------------------------------------------------------------------

Module: ram_dp_quad.sv

Function: 
- Infers four parameterized dual port synchronous RAMs.

Instantiates: 
- Nothing (block RAM should be synthesized).

Notes:
- All ports are in the same clock domain.
- Writes accept data after the address & write enable on the clock.
- Reads present data after the address on the clock.
- Configurable read-during-write mode (for the same port).
- Optional output data registering (likely an internal BRAM resource).
- This module is kind of stupid but necessary due to the limited
  memory initialization options in SV.

--------------------------------------------------------------------------------
*/

module ram_dp_quad
	#(
	parameter										DATA_W			= 8,
	parameter										ADDR_W			= 13,
	parameter										A_REG				= 1,  // 1=enable A output registering
	parameter										B_REG				= 1,  // 1=enable B output registering
	parameter										A_MODE 			= "RAW",  // options here are "RAW" and "WAR"
	parameter										B_MODE 			= "WAR"  // options here are "RAW" and "WAR"
	)
	(
	// clock
	input			logic								clk_i,				// clock
	// port A
	input			logic	[ADDR_W-1:0]			a3_addr_i,			// addresses
	input			logic	[ADDR_W-1:0]			a2_addr_i,
	input			logic	[ADDR_W-1:0]			a1_addr_i,
	input			logic	[ADDR_W-1:0]			a0_addr_i,
	input			logic								a3_wr_i,				// write enables, active high
	input			logic								a2_wr_i,
	input			logic								a1_wr_i,
	input			logic								a0_wr_i,
	input			logic	[DATA_W-1:0]			a3_i,					// write data
	input			logic	[DATA_W-1:0]			a2_i,
	input			logic	[DATA_W-1:0]			a1_i,
	input			logic	[DATA_W-1:0]			a0_i,
	output		logic	[DATA_W-1:0]			a3_o,					// read data
	output		logic	[DATA_W-1:0]			a2_o,
	output		logic	[DATA_W-1:0]			a1_o,
	output		logic	[DATA_W-1:0]			a0_o,
	// port B
	input			logic	[ADDR_W-1:0]			b3_addr_i,			// addresses
	input			logic	[ADDR_W-1:0]			b2_addr_i,
	input			logic	[ADDR_W-1:0]			b1_addr_i,
	input			logic	[ADDR_W-1:0]			b0_addr_i,
	input			logic								b3_wr_i,				// write enables, active high
	input			logic								b2_wr_i,
	input			logic								b1_wr_i,
	input			logic								b0_wr_i,
	input			logic	[DATA_W-1:0]			b3_i,					// write data
	input			logic	[DATA_W-1:0]			b2_i,
	input			logic	[DATA_W-1:0]			b1_i,
	input			logic	[DATA_W-1:0]			b0_i,
	output		logic	[DATA_W-1:0]			b3_o,					// read data
	output		logic	[DATA_W-1:0]			b2_o,
	output		logic	[DATA_W-1:0]			b1_o,
	output		logic	[DATA_W-1:0]			b0_o
	);

	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	localparam										DEPTH		= 1<<ADDR_W;	// per memory storage
	(* ram_init_file = "hive_3.mif" *)		logic		[DATA_W-1:0]			ram3[0:DEPTH-1];
	(* ram_init_file = "hive_2.mif" *)		logic		[DATA_W-1:0]			ram2[0:DEPTH-1];
	(* ram_init_file = "hive_1.mif" *)		logic		[DATA_W-1:0]			ram1[0:DEPTH-1];
	(* ram_init_file = "hive_0.mif" *)		logic		[DATA_W-1:0]			ram0[0:DEPTH-1];
	logic					[DATA_W-1:0]			a0_rd, a1_rd, a2_rd, a3_rd;
	logic					[DATA_W-1:0]			b0_rd, b1_rd, b2_rd, b3_rd;


	/*
	================
	== code start ==
	================
	*/


	// write
	always_ff @ ( posedge clk_i ) begin
		if ( a3_wr_i ) begin
			ram3[a3_addr_i] <= a3_i;
		end
		if ( a2_wr_i ) begin
			ram2[a2_addr_i] <= a2_i;
		end
		if ( a1_wr_i ) begin
			ram1[a1_addr_i] <= a1_i;
		end
		if ( a0_wr_i ) begin
			ram0[a0_addr_i] <= a0_i;
		end
	end
	
	always_ff @ ( posedge clk_i ) begin
		if ( b3_wr_i ) begin
			ram3[b3_addr_i] <= b3_i;
		end
		if ( b2_wr_i ) begin
			ram2[b2_addr_i] <= b2_i;
		end
		if ( b1_wr_i ) begin
			ram1[b1_addr_i] <= b1_i;
		end
		if ( b0_wr_i ) begin
			ram0[b0_addr_i] <= b0_i;
		end
	end


	// read
	always_ff @ ( posedge clk_i ) begin
		a3_rd <= ( a3_wr_i & A_MODE == "WAR" ) ? a3_i : ram3[a3_addr_i];
		a2_rd <= ( a2_wr_i & A_MODE == "WAR" ) ? a2_i : ram2[a2_addr_i];
		a1_rd <= ( a1_wr_i & A_MODE == "WAR" ) ? a1_i : ram1[a1_addr_i];
		a0_rd <= ( a0_wr_i & A_MODE == "WAR" ) ? a0_i : ram0[a0_addr_i];
		//
		b3_rd <= ( b3_wr_i & B_MODE == "WAR" ) ? b3_i : ram3[b3_addr_i];
		b2_rd <= ( b2_wr_i & B_MODE == "WAR" ) ? b2_i : ram2[b2_addr_i];
		b1_rd <= ( b1_wr_i & B_MODE == "WAR" ) ? b1_i : ram1[b1_addr_i];
		b0_rd <= ( b0_wr_i & B_MODE == "WAR" ) ? b0_i : ram0[b0_addr_i];
	end


	// optional output reg
	generate
		if ( A_REG ) begin
			always_ff @ ( posedge clk_i ) begin
				a3_o <= a3_rd;
				a2_o <= a2_rd;
				a1_o <= a1_rd;
				a0_o <= a0_rd;
			end
		end else begin
			always_comb a3_o = a3_rd;
			always_comb a2_o = a2_rd;
			always_comb a1_o = a1_rd;
			always_comb a0_o = a0_rd;
		end
		//
		if ( B_REG ) begin
			always_ff @ ( posedge clk_i ) begin
				b3_o <= b3_rd;
				b2_o <= b2_rd;
				b1_o <= b1_rd;
				b0_o <= b0_rd;
			end
		end else begin
			always_comb b3_o = b3_rd;
			always_comb b2_o = b2_rd;
			always_comb b1_o = b1_rd;
			always_comb b0_o = b0_rd;
		end
	endgenerate


endmodule
