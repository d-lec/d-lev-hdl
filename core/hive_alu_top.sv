/*
--------------------------------------------------------------------------------

Module : hive_alu_top.sv

--------------------------------------------------------------------------------

Function:
- Processor ALU top level.

Instantiates (at this level):
- (1x) hive_alu_logical.sv
- (1x) hive_alu_add_sub.sv
- (1x) hive_alu_mul_shl.sv
- (1x) hive_alu_mux.sv

Dependencies:
- hive_pkg.sv

Notes:
- I/O registered.
- Multi-stage pipeline.

--------------------------------------------------------------------------------
*/

module hive_alu_top
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// control I/O
	input			logic								imda_i,						// 1=immediate data
	input			ALU_CTL_T						alu_ctl_i,					// alu control
	// data I/O
	input			logic	[ALU_W-1:0]				a_i,							// operand
	input			logic	[ALU_W-1:0]				b_i,							// operand
	input			logic	[FLG_W-1:0]				b_flg_i,						// flags
	input			logic	[ALU_W-1:0]				im_alu_i,					// alu immediate
	input			logic								mem_rd_i,					// 1=read
	input			logic								reg_rd_i,					// 1=read
	input			logic	[PC_W-1:0]				pc_2_i,						// program counter
	input			logic	[ALU_W-1:0]				rbus_rd_data_i,			// rbus read data
	input			logic	[ALU_W-1:0]				mem_4_i,						// mem read data
	output		logic	[ALU_W-1:0]				result_6_o,					// result
	output		logic	[FLG_W-1:0]				flg_6_o						// flags out
	);

	
	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	import hive_types::*;
	//
	logic					[ALU_W-1:0]				b;
	logic					[ALU_W-1:0]				res_lg_3, res_as_3, res_ms_5;
	logic					[FLG_W-1:0]				flg_lg_3, flg_as_3, flg_ms_6;


	/*
	================
	== code start ==
	================
	*/


	// select data
	always_comb b = ( imda_i ) ? im_alu_i : b_i;


	// logical unit
	hive_alu_logical  hive_alu_logical
	(
	.*,
	.b_i					( b ),
	.lg_op_i				( alu_ctl_i.lg_op ),
	.result_o			( res_lg_3 ),
	.flg_o				( flg_lg_3 )
	);


	// add & subtract unit
	hive_alu_add_sub  hive_alu_add_sub
	(
	.*,
	.b_i					( b ),
	.result_o			( res_as_3 ),
	.flg_o				( flg_as_3 )
	);


	// multiply & shift unit
	hive_alu_mul_shl	hive_alu_mul_shl
	(
	.*,
	.b_i					( b ),
	.result_o			( res_ms_5 ),
	.flg_o				( flg_ms_6 )
	);


	// multiplexer
	hive_alu_mux	hive_alu_mux
	(
	.*,
	.res_lg_3_i			( res_lg_3 ),
	.flg_lg_3_i			( flg_lg_3 ),
	.res_as_3_i			( res_as_3 ),
	.flg_as_3_i			( flg_as_3 ),
	.res_ms_5_i			( res_ms_5 ),
	.flg_ms_6_i			( flg_ms_6 )
	);


endmodule
