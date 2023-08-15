/*
--------------------------------------------------------------------------------

Module: nco.sv

Function: 
- Forms a numerically controlled oscillator (NCO).

Instantiates:
- (1x) ddr_out_altera.sv (if O_DDR=1)

Notes:
- Output frequency = clk_i * freq_i / (2^NCO_W).
- Triangle wave dithering of frequency.
- LSV sets freq_i LSbs to one for better SFDR.

--------------------------------------------------------------------------------
*/

module nco
	#(
	parameter										NCO_W					= 32,	// nco accum width (bits)
	parameter										FREQ_W				= 25,	// frequency width (bits)
	parameter										TRI_W					= 11,	// tri width (bits)
	parameter										D_SHL_W				= 3,	// dither right shift width (bits)
	parameter										D_SHL					= 6,	// dither left shift (bits)
	parameter										LSV					= 1,	// LSb's constant value, 0 to disable
	parameter										O_DDR					= 1	// 1=use ddr at output; 0=no ddr
	)
	(
	// clocks & resets
	input		logic									clk_i,						// clock
	input		logic									rst_i,						// async reset, active high
	// I/O
	input		logic			[FREQ_W-1:0]		freq_i,						// frequency
	input		logic			[TRI_W-1:0]			tri_i,						// triangle in (sgn)
	input		logic			[D_SHL_W-1:0]		d_shl_i,						// dither left shift (gain)
	output	logic									sq_o							// dithered square output
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	logic		signed		[FREQ_W-1:0]		tri_s, tri_shl;
	logic		signed		[FREQ_W-1:0]		dith, freq_dith, freq_lsv;
	logic						[NCO_W-1:0]			accum;
	logic												sq_0;


	/*
	================
	== code start ==
	================
	*/

	// sign exend input
	always_comb tri_s = $signed( tri_i );

	// shift & register
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			tri_shl <= 0;
		end else begin
			tri_shl <= tri_s <<< d_shl_i;
		end
	end

	// left shift dither
	always_comb dith = tri_shl <<< D_SHL;

	// do dither
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			freq_dith <= 0;
		end else begin
			freq_dith <= FREQ_W'( $signed( freq_i ) + dith );
		end
	end
	
	// optional LSb's constant value
	always_comb freq_lsv = FREQ_W'( freq_dith | LSV );

	// modulo unsigned accumulate, reg msb
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			accum <= 0;
			sq_0 <= 0;
		end else begin
			accum <= accum + $unsigned( freq_lsv );
			sq_0 <= accum[NCO_W-1];
		end
	end

	
	// DDR option
	generate
		if ( O_DDR ) begin  // DDR @ output

			// declare stuff
			logic							[FREQ_W-1:0]	freq_lsv_1;
			logic							[NCO_W-1:0]		accum_1;
			logic												sq_1;

			// register
			always_ff @ ( posedge clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					freq_lsv_1 <= 0;
					sq_1 <= 0;
				end else begin
					freq_lsv_1 <= $unsigned( freq_lsv ) >> 1;
					sq_1 <= accum_1[NCO_W-1];
				end
			end

			// add 1/2 freq
			always_comb accum_1 = NCO_W'( accum + freq_lsv_1 );

			// ddr processing
			// note: 
			// - ddr_i[0] goes out first on rising clk
			// - ddr_i[1] goes out second on falling clk
			ddr_out_altera ddr_out
			(
			.*,
			.ddr_i		( { sq_1, sq_0 } ),
			.ddr_o		( sq_o )
			);

		end else begin  // no DDR @ output
		
			always_comb sq_o = sq_0;

		end
	endgenerate

	
endmodule 