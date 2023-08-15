/*
--------------------------------------------------------------------------------

Module: ram_dp.sv

Function: 
- Infers parameterized dual port synchronous RAM.

Instantiates: 
- Nothing (block RAM should be synthesized).

Notes:
- Writes accept data after the address & write enable on the clock.
- Reads present data after the address on the clock.
- Optional output data registering (likely an internal BRAM resource).

--------------------------------------------------------------------------------
*/

module ram_dp
	#(
	parameter										DATA_W			= 16,
	parameter										ADDR_W			= 13,
	parameter										REG_OUT			= 1  // 1=enable output registering
	)
	(
	// write port
	input			logic								wr_clk_i,			// write clock
	input			logic	[ADDR_W-1:0]			wr_addr_i,			// write address
	input			logic								wr_en_i,				// wr write enable, active high
	input			logic	[DATA_W-1:0]			wr_data_i,			// write data
	// read port
	input			logic								rd_clk_i,			// read clock
	input			logic	[ADDR_W-1:0]			rd_addr_i,			// read address
	output		logic	[DATA_W-1:0]			rd_data_o			// read data
	);

	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	localparam										DEPTH		= 1<<ADDR_W;	// per memory storage
	logic			[DATA_W-1:0]					ram[0:DEPTH-1];
	logic			[DATA_W-1:0]					rd_data;


	/*
	================
	== code start ==
	================
	*/


	// write
	always_ff @ ( posedge wr_clk_i ) begin
		if ( wr_en_i ) begin
			ram[wr_addr_i] <= wr_data_i;
		end
	end


	// read
	always_ff @ ( posedge rd_clk_i ) begin
		rd_data <= ram[rd_addr_i];
	end


	// optional output regs
	generate
		if ( REG_OUT ) begin
			always_ff @ ( posedge rd_clk_i ) begin
				rd_data_o <= rd_data;
			end
		end else begin
			always_comb rd_data_o = rd_data;
		end
	endgenerate


endmodule
