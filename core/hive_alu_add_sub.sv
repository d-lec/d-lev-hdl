/*
--------------------------------------------------------------------------------

Module : hive_alu_add_sub.sv

--------------------------------------------------------------------------------

Function:
- Add & subtract unit for a processor ALU.

Instantiates:
- Nothing.

Dependencies:
- hive_pkg.sv

Notes:
- IN/MID/OUT registered.

--------------------------------------------------------------------------------
*/

module hive_alu_add_sub
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// control I/O
	input			ALU_CTL_T						alu_ctl_i,					// alu control
	// data I/O
	input			logic	[ALU_W-1:0]				a_i,							// operand
	input			logic	[ALU_W-1:0]				b_i,							// operand
	output		logic	[ALU_W-1:0]				result_o,					// = ( a +/- b )
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
	logic												a_sgn_1, b_sgn_1;
	logic												sub_1, sub_2;
	logic												sbr_1, sbr_2;
	logic												ext_1, ext_2;
	logic	signed		[ALU_W-1:0]				a_1, b_1;
	logic	signed		[ZSX_W-1:0]				a_zsx_1, b_zsx_1;
	logic	signed		[ADD_W-1:0]				ab_add_1, ab_add_2;
	logic	signed		[ADD_W-1:0]				ab_sub_1, ab_sub_2;
	logic	signed		[ADD_W-1:0]				ab_sbr_1, ab_sbr_2;
	logic	signed		[DBL_W-1:0]				res_dbl_2;


	/*
	================
	== code start ==
	================
	*/

	// decode & register inputs
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			a_1 <= 0;
			b_1 <= 0;
			sub_1   <= 0;
			sbr_1   <= 0;
			ext_1   <= 0;
			a_sgn_1 <= 0;
			b_sgn_1 <= 0;
		end else begin
			a_1 <= a_i;
			b_1 <= b_i;
			sub_1 <= 0;
			sbr_1 <= 0;
			a_sgn_1 <= 0;
			b_sgn_1 <= 0;
			ext_1 <= alu_ctl_i.ext;
			unique case ( alu_ctl_i.as_op )
				as_add_u : begin
					// do defaut
				end
				as_add_us : begin
					b_sgn_1 <= '1;
				end
				as_add_su : begin
					a_sgn_1 <= '1;
				end
				as_add_s : begin
					a_sgn_1 <= '1;
					b_sgn_1 <= '1;
				end
				as_sub_u : begin
					sub_1   <= '1;
				end
				as_sub_us : begin
					sub_1   <= '1;
					b_sgn_1 <= '1;
				end
				as_sub_su : begin
					sub_1   <= '1;
					a_sgn_1 <= '1;
				end
				as_sub_s : begin
					sub_1   <= '1;
					a_sgn_1 <= '1;
					b_sgn_1 <= '1;
				end
				as_sbr_u : begin
					sbr_1   <= '1;
				end
				as_sbr_us : begin
					sbr_1   <= '1;
					a_sgn_1 <= '1;
				end
				as_sbr_su : begin
					sbr_1   <= '1;
					b_sgn_1 <= '1;
				end
				as_sbr_s : begin
					sbr_1   <= '1;
					a_sgn_1 <= '1;
					b_sgn_1 <= '1;
				end
				default : begin
					// do defaut
				end
			endcase
		end
	end
	
	// zero|sign extend results
	always_comb a_zsx_1 = { ( a_sgn_1 & a_1[ALU_W-1] ), a_1 };
	always_comb b_zsx_1 = { ( b_sgn_1 & b_1[ALU_W-1] ), b_1 };

	// arithmetic results (signed)
	always_comb ab_add_1 = a_zsx_1 + b_zsx_1;
	always_comb ab_sub_1 = a_zsx_1 - b_zsx_1;
	always_comb ab_sbr_1 = b_zsx_1 - a_zsx_1;
	
	// decode & reg mid results
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			sub_2 <= 0;
			sbr_2 <= 0;
			ext_2 <= 0;
			ab_add_2 <= 0;
			ab_sub_2 <= 0;
			ab_sbr_2 <= 0;
		end else begin
			sub_2 <= sub_1;
			sbr_2 <= sbr_1;
			ext_2 <= ext_1;
			ab_add_2 <= ab_add_1;
			ab_sub_2 <= ab_sub_1;
			ab_sbr_2 <= ab_sbr_1;
		end
	end

	// multiplex
	always_comb begin
		unique casex ( { sbr_2, sub_2 } )
			'b00 : res_dbl_2 <= ab_add_2;
			'b01 : res_dbl_2 <= ab_sub_2;
			'b1x : res_dbl_2 <= ab_sbr_2;
		endcase
	end

	// multiplex & reg output results
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			flg_o <= 0;
			result_o <= 0;
		end else begin
			flg_o[3] <= res_dbl_2[ADD_W-1];  // [33]
			flg_o[2] <= res_dbl_2[ADD_W-2];  // [32]
			flg_o[1] <= res_dbl_2[ADD_W-2];  // [32]
			flg_o[0] <= res_dbl_2[ADD_W-3];  // [31]
			result_o <= ( ext_2 ) ? res_dbl_2[DBL_W-1:ALU_W] : res_dbl_2[ALU_W-1:0];
		end
	end

endmodule
