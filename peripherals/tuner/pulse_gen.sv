/*
--------------------------------------------------------------------------------

Module: pulse_gen.sv

Function: 
- Forms a jittered pulse source.

Instantiates:
- (1x) lfsr.sv

Notes:
- Configurable noise vector width and offset.

--------------------------------------------------------------------------------
*/

module pulse_gen
	#(
	parameter										LOAD_MIN				= 8,	// minimum load value
	parameter										NOISE_W				= 3,	// noise vector width (bits)
	parameter										LFSR_W				= 10	// LFSR shift register width, 3 to 168
	)
	(
	// clocks & resets
	input		logic									clk_i,						// clock
	input		logic									rst_i,						// async reset, active high
	// I/O
	input		logic									en_i,							// enable, active high
	output	logic									pulse_o						// pulse
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	localparam								TIMER_W 				= NOISE_W+$clog2(LOAD_MIN);
	//
	logic				[NOISE_W-1:0]		noise_c;
	logic				[TIMER_W-1:0]		timer_c;
	logic				[TIMER_W-1:0]		timer_init;
	logic				[NOISE_W-1:0]		noise;
	logic										load_f, run_f;



	/*
	================
	== code start ==
	================
	*/


	// noise down counter
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			noise_c <= 0;  // idle
		end else begin
			if ( en_i ) begin
				if ( load_f ) begin
					noise_c <= '1;
				end else if ( run_f ) begin
					noise_c <= noise_c - 1'b1;
				end
			end
		end
	end
	
	// decode flag
	always_comb run_f = |noise_c;
	
	// instantiate lfsr
	lfsr
	#(
	.LFSR_W			( LFSR_W ),
	.FULL_SEQ		( 0 )
	)
	lfsr_inst
	(
	.*,
	.en_i				( run_f ),
	.vect_o			( noise ),
	.bit_o			(  )  // unused
	);


	// combine
	always_comb timer_init = TIMER_W'( LOAD_MIN + noise );

	// timer down counter
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			timer_c <= 0;  // idle
		end else begin
			if ( en_i ) begin
				if ( load_f ) begin
					timer_c <= timer_init;
				end else begin
					timer_c <= timer_c - 1'b1;
				end
			end
		end
	end

	// decode flag
	always_comb load_f = ( !timer_c );

	// output pulse
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			pulse_o <= 0;
		end else begin
			pulse_o <= load_f && en_i;
		end
	end

endmodule 