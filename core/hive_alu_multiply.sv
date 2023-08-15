/*
--------------------------------------------------------------------------------

Module : hive_alu_multiply.sv

--------------------------------------------------------------------------------

Function:
- Signed multiply unit for a processor ALU.

Instantiates:
- (1x) pipe.sv (debug mode only)

Dependencies:
- Nothing.

Notes:
- Parameterized I/O widths.
- For Hive: input width = 33, output width = 65.
- 3 stage / 4 register pipeline.
- Multiply stage I/O registers are likely free (part of multiplier block).
- Debug mode for comparison to native signed multiplication, only use for 
  simulation / verification as it consumes resources and negatively impacts 
  top speed. 

Design minutia:
I've had to come back up to speed on this module several times and it can be
fairly painful.  Here are the basics:
- The most straightforward thing to do in terms of parameterization is to 
  size the multiplication inputs, then size the multiplication results in 
  terms of the input sizing.
- Make HI_W equal to LO_W (input width even) or LO_W-1 (input width odd) as 
  this makes all multiplications as narrow as possible, and also "pushes up"
  the final add, making it narrower.  This minimizes carry logic and maximizes
  the speed.
- LZ_W = LO_W+1 to make room for input zero extension (LO inputs are unsigned).
- LL_W = LO_W*2 because the inputs are zero extended, so we don't need the upper
  two result bits.
- HL_W = HI_W+LZ_W because the upper result bits carry necessary sign info.
- HH_W = MUL_W-LL_W to constrain / minimize this intermediate result width.
- The inner sum shift = LO_W because input zero extension is ignored here.

Note that, since the inputs are zero or sign extended, large negative input 
values cannot happen.  So the output MSb calculation can be done manually by 
ORing the input sign bits, doing the multiplication DBL_W, then the output 
sign bit is the 0 if both inputs are non-negative, otherwise it is a copy of
the DBL_W MSb.  With this scheme the debug verification built-in to this module 
will fail for larger negative inputs - this isn't an error!

--------------------------------------------------------------------------------
*/

module hive_alu_multiply
	#(
	parameter										DEBUG_MODE		= 0		// 1=debug mode; 0=normal mode
	)
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// data I/O
	input			logic	[ZSX_W-1:0]				a_i,							// operand
	input			logic	[ZSX_W-1:0]				b_i,							// operand
	output		logic	[MUL_W-1:0]				result_o,					// = ( a_i * b_i )
	// debug
	output		logic								debug_o						// 1=bad match
	);

	
	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	// mul input widths
	localparam										HI_W				= HLF_W;			// 16
	localparam										LO_W				= ZSX_W-HI_W;	// 17
	localparam										LZ_W				= LO_W+1;		// 18
	// mul result widths
	localparam										LL_W				= LO_W*2;		// 34
	localparam										HL_W				= HI_W+LZ_W;	// 34
	localparam										HH_W				= MUL_W-LL_W;	// 31
	//
	logic	signed		[ZSX_W-1:0]				a, b;
	logic	signed		[HI_W-1:0]				a_h, b_h;
	logic	signed		[LZ_W-1:0]				a_l, b_l;
	logic	signed		[HH_W-1:0]				mul_hh;
	logic	signed		[HL_W-1:0]				mul_hl, mul_lh;
	logic	signed		[LL_W-1:0]				mul_ll;
	logic	signed		[MUL_W-1:0]				inner_sum, outer_cat;


	/*
	================
	== code start ==
	================
	*/


	// input registering (likely free)
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			a <= 0;
			b <= 0;
		end else begin
			a <= a_i;
			b <= b_i;
		end
	end
	
	// break out & zero extend inputs
	always_comb a_h = a[ZSX_W-1:LO_W];
	always_comb b_h = b[ZSX_W-1:LO_W];
	always_comb a_l = { 1'b0, a[LO_W-1:0] };
	always_comb b_l = { 1'b0, b[LO_W-1:0] };

	// do all multiplies & register (registers are likely free)
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			mul_hh <= 0;
			mul_hl <= 0;
			mul_lh <= 0;
			mul_ll <= 0;
		end else begin
			mul_hh <= a_h * b_h;
			mul_hl <= a_h * b_l;
			mul_lh <= a_l * b_h;
			mul_ll <= a_l * b_l;
		end
	end

	// add and shift inner terms, concatenate outer terms, register
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			inner_sum <= 0;
			outer_cat <= 0;
		end else begin
			inner_sum <= ( mul_hl + mul_lh ) << LO_W;
			outer_cat <= { mul_hh, mul_ll };
		end
	end

	// final add & register
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			result_o <= 0;
		end else begin
			result_o <= outer_cat + inner_sum;
		end
	end


	// optional debug mode
	generate
		if ( DEBUG_MODE ) begin
			logic signed [MUL_W-1:0] debug_mul;
			logic signed [MUL_W-1:0] debug_mul_r;
			logic debug;
			always_comb debug_mul = a * b;
			// delay regs
			pipe
			#(
			.DEPTH		( 3 ),
			.WIDTH		( MUL_W ),
			.RESET_VAL	( 0 )
			)
			regs_debug
			(
			.*,
			.data_i		( debug_mul ),
			.data_o		( debug_mul_r )
			);
			// compare & register
			always_ff @ ( posedge clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					debug <= 0;
				end else begin
					debug <= ( debug_mul_r != result_o );
				end
			end
			//
			always_comb debug_o = debug;
		end else begin
			always_comb debug_o = 0;
		end
	endgenerate


endmodule
