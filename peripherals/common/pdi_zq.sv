/*
--------------------------------------------------------------------------------

Module: pdi_zq.sv

Function: 
- Forms a simple quadrature phase detector & integrator for a DLL.

Instantiates:
- (2x) ddr_in_altera.sv (if I_DDR=1)

Notes:
- Normal operation is zero_i rise => quad_i rise => zero_i fall => quad_i fall.
- Noise is tolerated at the zero_i and quad_i inputs.
- Phase zero when quad_i lags zero_i by 90 degrees.
- Inc when quad_i lags zero_i by < 90 degrees (early, NCO too slow).
- Dec when quad_i lags zero_i by > 90 degrees (late, NCO too fast).
- RANGE_W sets lower limit on frequency range (bits):
  - RANGE_W=1 gives 2:1 range
  - RANGE_W=2 gives 4:1 range
  - RANGE_W=3 gives 8:1 range, etc.
  - RANGE_W=FREQ_W disables limit

--------------------------------------------------------------------------------
*/

module pdi_zq
	#(
	parameter											FREQ_W				= 8,		// phase accum width (bits)
	parameter											RANGE_W				= 4,		// phase accum range (bits)
	parameter											SYNC_W				= 2,		// resync registers, 1 min (if I_DDR=0)
	parameter											I_DDR					= 1		// 1=use ddr at input; 0=no ddr
	)
	(
	// clocks & resets
	input		logic										clk_i,							// clock
	input		logic										rst_i,							// async. reset, active hi
	// I/O
	input		logic										zero_i,							// zero async input
	input		logic										quad_i,							// quad async input
	output	logic				[FREQ_W-1:0]		freq_o							// phase accum value
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	logic							[FREQ_W-1:0]		freq_inc;
	logic													low_f;


	/*
	================
	== code start ==
	================
	*/


	generate

		if ( I_DDR ) begin  // DDR inputs

			// declare stuff
			logic							[1:0]					zero_ddr, quad_ddr, zero_r, quad_r, zq_xor;
			logic													inc_f, dec_f;
			
			// ddr processing
			ddr_in_altera zero_ddr_in
			(
			.*,
			.ddr_i		( zero_i ),
			.ddr_o		( zero_ddr )
			);

			ddr_in_altera quad_ddr_in
			(
			.*,
			.ddr_i		( quad_i ),
			.ddr_o		( quad_ddr )
			);

			// register
			always_ff @ ( posedge clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					zero_r <= 0;
					quad_r <= 0;
				end else begin
					zero_r <= zero_ddr;
					quad_r <= quad_ddr;
				end
			end

			// xor vectors
			always_comb zq_xor = zero_r ^ quad_r;

			// decode inc, dec & reg to speed up
			always_ff @ ( posedge clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					inc_f <= 0;
					dec_f <= 0;
				end else begin
					inc_f <= &( ~zq_xor );
					dec_f <= &zq_xor;
				end
			end
			
			// select inc / dec value
			always_comb begin
				unique casex ( { inc_f, dec_f, low_f } )
					3'bxx1  : freq_inc = 1;  // +1
					3'b010  : freq_inc = '1; // -1
					3'b100  : freq_inc = 1;  // +1
					default : freq_inc = 0;  // 0
				endcase
			end


		end else begin  // no DDR inputs
	
			// declare stuff
			logic							[SYNC_W-1:0]		zero_sr, quad_sr;
			logic													xor_f;

			// register to resync 
			always_ff @ ( posedge clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					zero_sr <= 0;
					quad_sr <= 0;
				end else begin
					zero_sr <= SYNC_W'( { zero_sr, zero_i } );
					quad_sr <= SYNC_W'( { quad_sr, quad_i } );
				end
			end

			// decode xor, reg to speed up
			always_ff @ ( posedge clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					xor_f <= 0;
				end else begin
					xor_f <= zero_sr[SYNC_W-1] ^ quad_sr[SYNC_W-1];
				end
			end

			// select inc / dec value
			always_comb begin
				unique casex ( { xor_f, low_f } )
					2'bx1   : freq_inc = 1;  // +1
					2'b10   : freq_inc = '1; // -1
					default : freq_inc = 1;  // +1
				endcase
			end

		end
	endgenerate


	////////////
	// common //
	////////////

	
	// decode low flag (upper bits zero)
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			low_f <= 0;
		end else begin
			low_f <= ~|freq_o[FREQ_W-1:FREQ_W-RANGE_W];
		end
	end
	
	// reg to speed up / output / accumulate
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			freq_o <= 0;
		end else begin
			freq_o <= freq_o + freq_inc;
		end
	end

endmodule
