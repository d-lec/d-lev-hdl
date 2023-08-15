/*
--------------------------------------------------------------------------------

Module: ddfs.sv

Function: 
- Generates fixed output frequency via phase accumulation.

Instantiates: 
- Nothing.

Notes:
- Output frequency must be <= 1/2 clock frequency.
- Enable input resets accum when low.
- No dithering option.
    
--------------------------------------------------------------------------------
*/

module ddfs
	#(
	parameter			int						INC_W				= 8,	// sets the precision
	parameter			real						CLK_FREQ			= 199,	// clock frequency
	parameter			real						OUT_FREQ			= 13	// output frequency
	)
	(
	// clocks & resets
	input		logic									clk_i,					// in clock
	input		logic									rst_i,					// async reset, active hi
	// I/O
	input		logic									en_i,						// accumulate enable, active hi
	output	logic									sq_o,						// out "clock"
	output	logic									rise_o,					// out pulse
	output	logic									fall_o					// out pulse
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	localparam			real						DIV				= CLK_FREQ/OUT_FREQ;
	localparam			int						ACCUM_W			= $clog2(int'(DIV+0.5))+INC_W-1;
	localparam			int						INC				= (2**ACCUM_W)/DIV;
	//
	logic					[ACCUM_W-1:0]			accum;
	logic												sq_r;


	/*
	================
	== code start ==
	================
	*/


	// accumulate / sync / enable
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			accum <= 0;
			sq_r <= 0;
		end else begin
			if ( en_i ) begin
				accum <= accum + ACCUM_W'( INC );
				sq_r <= sq_o;
			end else begin
				accum <= 0;
				sq_r <= 0;
			end
		end
	end
	
	// outputs
	always_comb sq_o = accum[ACCUM_W-1];
	always_comb rise_o = ( sq_o && !sq_r );
	always_comb fall_o = ( !sq_o && sq_r );

endmodule
