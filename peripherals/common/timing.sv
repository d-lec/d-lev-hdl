/*
--------------------------------------------------------------------------------

Module: timing

Function: 
- Forms the master timing source for SPDIF, IRQs, and LC_DPLL dither.

Instantiates:
- Nothing.

Notes:
- sq_48k_o[3:0] are offset 45 degrees.
- tri_48_o is a signed triangle wave.
- Enable pulse pulse s/b Fs * 128:
  - 48kHz * 128   = 6.144MHz
  - 44.1kHz * 128 = 5.6448MHz
- For reference: 
  - 48k   = (2^7)*(3^1)*(5^3)
  - 44.1k = (2^2)*(3^2)*(5^2)*(7^2)
- sq_48k_o[3:0] are offset 45 degrees.
- lpf_ltch_o = ~sq_48k_o[0].

--------------------------------------------------------------------------------
*/

module timing
	#(
	parameter								PRE_W					= 5,		// prescale clock divider width (bits)
	parameter								TRI_W					= PRE_W+6	// tri width (don't change!)
	)
	(
	// clocks & resets
	input		logic							clk_i,							// clock
	input		logic							rst_i,							// async. reset, active hi
	// parallel interface	
	output	logic							spdif_en_o,						// SPDIF enable, active hi one clock
	input		logic							pcm_rd_i,						// pcm read, active hi one clock,
	output	logic	[1:0]					lpf_en_o,						// lpf (ping pong) enables out
	output	logic							lpf_ltch_o,						// lpf latch out
	output	logic	[3:0]					sq_48k_o,						// square 48kHz out
	output	logic	[TRI_W-1:0]			tri_48k_o						// triangle 48kHz out (signed)
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	localparam										DIV_W			= TRI_W+1;
	logic					[PRE_W-1:0]				pre_c;
	logic					[DIV_W:0]				div_c;



	/*
	================
	== code start ==
	================
	*/


	// prescale up counter
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			pre_c <= 0;
		end else begin
			pre_c <= pre_c + 1'b1;
		end
	end

	// output enable
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			spdif_en_o <= 0;
		end else begin
			spdif_en_o <= ( pre_c ) ? '0 : '1;
		end
	end

	// divider up counter
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			div_c <= 0;
		end else begin
			if ( pcm_rd_i ) begin  // sync
				div_c <= 0;
			end else begin
				div_c <= div_c + 1'b1;
			end
		end
	end

	// decode & register outputs
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			lpf_ltch_o <= 0;
			lpf_en_o <= 0;
			sq_48k_o <= 0;
			tri_48k_o <= 0;
		end else begin
			lpf_ltch_o <= ~div_c[DIV_W-1];
			//
			lpf_en_o <= { div_c[0], ~div_c[0] };
			//
			sq_48k_o[0] <= div_c[DIV_W-1];
			sq_48k_o[1] <= 1'( ( div_c[DIV_W-1:DIV_W-3] + 1 ) >> 2 );
			sq_48k_o[2] <= 1'( ( div_c[DIV_W-1:DIV_W-3] + 2 ) >> 2 );
			sq_48k_o[3] <= 1'( ( div_c[DIV_W-1:DIV_W-3] + 3 ) >> 2 );
			//
			tri_48k_o <= ( div_c[DIV_W-1] ^ div_c[DIV_W-2] ) ? ~div_c[DIV_W-2:0] : div_c[DIV_W-2:0];
		end
	end
			
endmodule
