/*
--------------------------------------------------------------------------------

Module: bin_gray_bin.sv

Function: 
- Binary => Gray => Binary (for FIFO pointers crossing clock domains).
- Parameterized vector width & mode.

Instantiates: 
- (1x) pipe.sv

Notes:
- For an async fifo, you must constrain flight time (launch to latch) variance 
  or skew among the individual pointer bits from one clock domain to the other
  to be less than one launch clock interval!
- SYNC_W=0 produces a simple register (to match external memory delay).
Functionality:
 1. Binary => Gray of input vector a.
 2. Register (1) in input clock domain a.
 3. Multiple register (2) in output clock domain b (for metastability),
 4. Gray => Binary of (3),
 5. Register (4) in output clock domain b (for speed).
 6. Output (5).

--------------------------------------------------------------------------------
*/
module bin_gray_bin
	#(
	parameter									VECT_W			= 8,
	parameter									SYNC_W			= 2		// 0=simple register
	)
	(
	// reset
	input		logic								rst_i,					// async. reset, active high
	// in vector & clock
	input		logic								a_clk_i,					// clock a
	input		logic	[VECT_W-1:0]			a_i,						// input vector a
	// out vector & clock
	input		logic								b_clk_i,					// clock b
	output	logic	[VECT_W-1:0]			b_o						// output vector b
	);

	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	// None here.


	/*
	================
	== code start ==
	================
	*/

	// implement parameterized options
	generate
		if ( SYNC_W ) begin  // enabled, give it the works

			// signals
			logic [VECT_W-1:0] a_gray, b_gray, b_bin;

			// convert input binary to Gray-code, register to deglitch
			always_ff @ ( posedge a_clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					a_gray <= 0;
				end else begin
					a_gray <= a_i ^ a_i[VECT_W-1:1];
				end
			end

			// register in output clock domain to eliminate metastability
			pipe
			#(
			.DEPTH				( SYNC_W ),
			.WIDTH				( VECT_W ),
			.RESET_VAL			( 0 )
			)
			pipe_inst
			(
			.*,
			.clk_i				( b_clk_i ),
			.data_i				( a_gray ),
			.data_o				( b_gray )
			);
			
			// convert input Gray-code to binary
			always_comb b_bin = b_gray ^ b_bin[VECT_W-1:1];

			// register output in output clock domain
			always_ff @ ( posedge b_clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					b_o <= 0;
				end else begin
					b_o <= b_bin;
				end
			end

		end else begin  // disabled, just register

			// register
			always_ff @ ( posedge a_clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					b_o <= 0;
				end else begin
					b_o <= a_i;
				end
			end

		end
	endgenerate

endmodule
