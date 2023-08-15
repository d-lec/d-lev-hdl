/*
--------------------------------------------------------------------------------

Module : hive_alu_mult_shift.sv

--------------------------------------------------------------------------------

Function:
- Multiply & shift unit for a processor ALU.

Instantiates (at this level):
- (1x) hive_alu_multiply.sv

Dependencies:
- hive_pkg.sv

Notes:
- 5 stage pipeline, unreg output.
- (pow=0 & shl=0) gives unsigned (sgn=0) and signed (sgn=1) A*B.
- (pow=0 & shl=1) gives A unsigned (sgn=0) and A signed (sgn=1) A<<B.
- (pow=1 & shl=x) gives 1<<B.

--------------------------------------------------------------------------------
*/

module hive_alu_mul_shl
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// control I/O
	input			ALU_CTL_T						alu_ctl_i,					// alu control
	// data I/O
	input			logic	[ALU_W-1:0]				a_i,							// operand
	input			logic	[ALU_W-1:0]				b_i,							// operand
	output		logic	[ALU_W-1:0]				result_o,					// result
	output		logic	[FLG_W-1:0]				flg_o							// flags
	);

	
	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	import hive_types::*;
	//
	logic					[ALU_W-1:0]				a_1, b_1;
	logic												a_sgn_1, b_sgn_1, rol_1, shl_1, pow_1, ext_1, lim_1;
	logic												b_msb_1;
	logic					[ALU_W-1:0]				b_pow_1;
	logic					[ZSX_W-1:0]				a_zsx_1, b_zsx_1;
	logic					[ZSX_W-1:0]				a_mux_1, b_mux_1;
	logic												r_1, x_1;
	logic												b_bro_2, b_bra_2, lim_2, z_2;
	logic					[5:2]						x_sr, r_sr;
	logic					[5:3]						z_sr;
	logic					[MUL_W-1:0]				res_mul_5;


	/*
	================
	== code start ==
	================
	*/


	// decode & register inputs
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			pow_1 <= 0;
			rol_1 <= 0;
			lim_1 <= 0;
			shl_1 <= 0;
			ext_1 <= 0;
			a_sgn_1 <= 0;
			b_sgn_1 <= 0;
			a_1 <= '0;
			b_1 <= '0;
		end else begin
			a_1 <= a_i;
			b_1 <= b_i;
			ext_1 <= alu_ctl_i.ext;
			unique case ( alu_ctl_i.ms_op )
				ms_mul_u : begin
					pow_1 <= 0;
					rol_1 <= 0;
					lim_1 <= 0;
					shl_1 <= 0;
					ext_1 <= alu_ctl_i.ext;
					a_sgn_1 <= 0;
					b_sgn_1 <= 0;
				end
				ms_mul_us : begin
					pow_1 <= 0;
					rol_1 <= 0;
					lim_1 <= 0;
					shl_1 <= 0;
					ext_1 <= alu_ctl_i.ext;
					a_sgn_1 <= 0;
					b_sgn_1 <= '1;
				end
				ms_mul_su : begin
					pow_1 <= 0;
					rol_1 <= 0;
					lim_1 <= 0;
					shl_1 <= 0;
					ext_1 <= alu_ctl_i.ext;
					a_sgn_1 <= '1;
					b_sgn_1 <= 0;
				end
				ms_mul_s : begin
					pow_1 <= 0;
					rol_1 <= 0;
					lim_1 <= 0;
					shl_1 <= 0;
					ext_1 <= alu_ctl_i.ext;
					a_sgn_1 <= '1;
					b_sgn_1 <= '1;
				end
				ms_shl_u : begin
					pow_1 <= 0;
					rol_1 <= 0;
					lim_1 <= '1;
					shl_1 <= '1;
					ext_1 <= 0;
					a_sgn_1 <= 0;
					b_sgn_1 <= 0;
				end
				ms_shl_s : begin
					pow_1 <= 0;
					rol_1 <= 0;
					lim_1 <= '1;
					shl_1 <= '1;
					ext_1 <= 0;
					a_sgn_1 <= '1;
					b_sgn_1 <= 0;
				end
				ms_rol : begin
					pow_1 <= 0;
					rol_1 <= '1;
					lim_1 <= 0;
					shl_1 <= '1;
					ext_1 <= 0;
					a_sgn_1 <= 0;
					b_sgn_1 <= 0;
				end
				ms_pow : begin
					pow_1 <= '1;
					rol_1 <= 0;
					lim_1 <= '1;
					shl_1 <= 0;
					ext_1 <= 0;
					a_sgn_1 <= 0;
					b_sgn_1 <= 0;
				end
				default : begin
					pow_1 <= 'x;
					rol_1 <= 'x;
					lim_1 <= 'x;
					shl_1 <= 'x;
					ext_1 <= 'x;
					a_sgn_1 <= 'x;
					b_sgn_1 <= 'x;
				end
			endcase
		end
	end

	// some results pre-mux
	always_comb a_zsx_1 = { ( a_sgn_1 & a_1[ALU_W-1] ), a_1 };
	always_comb b_zsx_1 = { ( b_sgn_1 & b_1[ALU_W-1] ), b_1 };
	always_comb b_pow_1 = 1'b1 << b_1[SEL_W-1:0];
	always_comb b_msb_1 = b_1[ALU_W-1];

	// mux inputs and extended result selector
	always_comb begin
		unique casex ( { pow_1, shl_1 } )
			'b00 : begin  // multiply
				a_mux_1 <= a_zsx_1;
				b_mux_1 <= b_zsx_1;
				r_1 <= 0;
				x_1 <= ext_1;
			end
			'b01 : begin  // shift, rotate
				a_mux_1 <= a_zsx_1;
				b_mux_1 <= b_pow_1;
				r_1 <= rol_1;
				x_1 <= b_msb_1;
			end
			'b1x : begin  // power
				a_mux_1 <= 'b1;
				b_mux_1 <= b_pow_1;
				r_1 <= 0;
				x_1 <= 0;
			end
		endcase
	end

	// decode & register flags, register lim to match
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			b_bro_2 <= 0;
			b_bra_2 <= 0;
			lim_2 <= 0;
		end else begin
			b_bro_2 <= |b_1[ALU_W-1:SEL_W];
			b_bra_2 <= &b_1[ALU_W-1:SEL_W];
			lim_2 <= lim_1;
		end
	end

	// decode flag
	always_comb z_2 = lim_2 & ( b_bro_2 ^ b_bra_2 );

	// reg to match multiply
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			z_sr <= 0;
			x_sr <= 0;
			r_sr <= 0;
		end else begin
			z_sr <= 3'( { z_sr, z_2 } );
			x_sr <= 4'( { x_sr, x_1 } );
			r_sr <= 4'( { r_sr, r_1 } );
		end
	end


	// signed multiplier (4 registers deep)
	hive_alu_multiply
	#(
	.DEBUG_MODE		( 0 )
	)
	hive_alu_multiply
	(
	.*,
	.a_i				( a_mux_1 ),
	.b_i				( b_mux_1 ),
	.result_o		( res_mul_5 ),
	.debug_o			(  )  // no connect
	);


	// multiplex
	always_comb begin
		unique casex ( { z_sr[5], r_sr[5], x_sr[5] } )
			'b1xx    : result_o <= '0;
			'b01x    : result_o <= res_mul_5[DBL_W-1:ALU_W] | res_mul_5[ALU_W-1:0];
			'b001    : result_o <= res_mul_5[DBL_W-1:ALU_W];
			default  : result_o <= res_mul_5[ALU_W-1:0];
		endcase
	end


	// decode & reg flags
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			flg_o <= 0;
		end else begin
			flg_o[3] <=  res_mul_5[MUL_W-1];  		// [64]
			flg_o[2] <= |res_mul_5[DBL_W-1:ALU_W];	// |[63:32]
			flg_o[1] <= &res_mul_5[DBL_W-1:ALU_W];	// &[63:32]
			flg_o[0] <=  res_mul_5[ALU_W-1];			// [31]
		end
	end


endmodule
