/*
--------------------------------------------------------------------------------

Module: lpf.sv

Function: 
- First-order, unsigned, integer-based "fast" low pass IIR filter.
- Parameterized cutoff point is a fixed power of 2.

Instantiates: 
- Nothing.

Notes:
- Closely approximates a simple IIR filter for larger SHR values.
- Gain is ~1 when SHR > ~4, below this it gets peaky near cutoff.
- For large SHR: Fc / Fs ~= 1 / ( 2 * pi * (2^SHR) )
- For all SHR: Fc / Fs = -ln(1 - (1 / (2^SHR))) / (2 * pi)
- Set LSb = 1 to prevent underflow.
- Adjust SHR for enable duty cycle!

--------------------------------------------------------------------------------
*/

module lpf
	#(
	parameter										DATA_W			= 8,	// I/O data width
	parameter										SHR				= 4	// time constant, see notes
	)
	(
	// clocks & resets
	input		logic									clk_i,					// clock
	input		logic									rst_i,					// async reset, active high
	// data interface
	input		logic									en_i,						// enable, active high
	input		logic		[DATA_W-1:0]			data_i,					// data in
	output	logic		[DATA_W-1:0]			lp_o						// low pass out
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	logic		signed	[DATA_W:0]				hp, hp_shr, hp_reg;  // extra bit for headroom
	logic					[DATA_W-1:0]			lp, lp_reg;


	/*
	================
	== code start ==
	================
	*/


	// hp & lp
	always_comb hp = data_i - lp_reg;
	always_comb hp_shr = hp >>> SHR;
	always_comb lp = DATA_W'( lp_reg + hp_reg );
		
	// reg
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			hp_reg <= 0;
			lp_reg <= 0;
		end else begin
			if ( en_i ) begin
				hp_reg <= hp_shr;
				lp_reg <= lp;
			end
		end
	end

	// output
	always_comb lp_o = lp_reg;
	
	
endmodule
