/*
--------------------------------------------------------------------------------

Module : hive_alu_logical

--------------------------------------------------------------------------------

Function:
- Logic unit for a processor ALU.

Instantiates:
- Nothing.

Dependencies:
- hive_pkg.sv

Notes:
- IN/MID/OUT registers.
- Default path through is don't care.

--------------------------------------------------------------------------------
*/

module hive_alu_logical
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// control I/O
	input			LG_OP_T							lg_op_i,						// logic operation
	// data I/O
	input			logic	[ALU_W-1:0]				a_i,							// operand
	input			logic	[ALU_W-1:0]				b_i,							// operand
	input			logic	[FLG_W-1:0]				b_flg_i,						// flags
	output		logic	[ALU_W-1:0]				result_o,					// logical result
	output		logic	[FLG_W-1:0]				flg_o							// flags
	);

	
	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	import hive_types::*;
	import hive_funcs::*;
	//
	localparam			[ALU_W-1:0]				UFL				= 1'b1 << (ALU_W-1);
	localparam			[ALU_W-1:0]				OFL				= ~UFL;
	//
	LG_OP_T											lg_op_1, lg_op_2;
	logic					[ALU_W-1:0]				a_1, b_1;
	logic					[FLG_W-1:0]				b_flg_1, b_flg_2;
	logic					[ALU_W-1:0]				res_b_2, res_bb_2, res_ab_2;
	logic					[LZC_W-1:0]				lzc_2;
	logic												olm_1, ulm_1, ofl_1, ufl_1;
	logic												sgn_2, brx_2;


	/*
	================
	== code start ==
	================
	*/


	// register inputs
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			lg_op_1 <= LG_OP_T'('x);
			a_1 <= 0;
			b_1 <= 0;
			b_flg_1 <= 0;
		end else begin
			lg_op_1 <= lg_op_i;
			a_1 <= a_i;
			b_1 <= b_i;
			b_flg_1 <= b_flg_i;
		end
	end

	// decode flags
	always_comb olm_1 = ~b_flg_1[3] & b_flg_1[2];
	always_comb ulm_1 =  b_flg_1[3];
	always_comb ofl_1 = ~b_flg_1[3] &  ( b_flg_1[2] | b_flg_1[0] );
	always_comb ufl_1 =  b_flg_1[3] & ~( b_flg_1[1] & b_flg_1[0] );


	// multiplex & reg intermediate results
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			lg_op_2 <= LG_OP_T'('x);
			b_flg_2 <= 0;
			sgn_2 <= 0;
			brx_2 <= 0;
			lzc_2 <= 0;
			res_b_2 <= 'x;
			res_bb_2 <= 'x;
			res_ab_2 <= 'x;
		end else begin
			lg_op_2 <= lg_op_1;
			b_flg_2 <= b_flg_1;
			sgn_2 <= b_1[ALU_W-1];
			brx_2 <= ^b_1;
			lzc_2 <= lzc(b_1);
			unique case ( lg_op_1 )
				lg_cpy  : res_b_2 <= b_1;
				lg_nsb  : res_b_2 <= { ~b_1[ALU_W-1], b_1[ALU_W-2:0] };
				lg_lim  : res_b_2 <= olm_1 ? '1  : ulm_1 ? '0  : b_1;
				lg_sat  : res_b_2 <= ofl_1 ? OFL : ufl_1 ? UFL : b_1;
				default : res_b_2 <= 'x; // default is don't care
			endcase
			unique case ( lg_op_1 )
				lg_flp  : res_bb_2 <= flip(b_1);
				lg_swp  : res_bb_2 <= { b_1[7:0], b_1[15:8], b_1[23:16], b_1[31:24] };
				lg_not  : res_bb_2 <= ~b_1;
				default : res_bb_2 <= 'x; // default is don't care
			endcase
			unique case ( lg_op_1 )
				lg_and  : res_ab_2 <= a_1 & b_1;
				lg_orr  : res_ab_2 <= a_1 | b_1;
				lg_xor  : res_ab_2 <= a_1 ^ b_1;
				default : res_ab_2 <= 'x; // default is don't care
			endcase
		end
	end


	// multiplex & reg output results
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			flg_o <= 0;
			result_o <= 'x;
		end else begin
			flg_o <= b_flg_2;
			unique case ( lg_op_2 )
				lg_cpy  : result_o <= res_b_2;
				lg_nsb  : result_o <= res_b_2;
				lg_lim  : result_o <= res_b_2;
				lg_sat  : result_o <= res_b_2;
				lg_flp  : result_o <= res_bb_2;
				lg_swp  : result_o <= res_bb_2;
				lg_not  : result_o <= res_bb_2;
				lg_brx  : result_o <= brx_2 ? '1 : '0;
				lg_sgn  : result_o <= sgn_2 ? '1 : 1'b1;
				lg_lzc  : result_o <= lzc_2;
				lg_and  : result_o <= res_ab_2;
				lg_orr  : result_o <= res_ab_2;
				lg_xor  : result_o <= res_ab_2;
				default : result_o <= 'x; // default is don't care
			endcase
		end
	end


endmodule
