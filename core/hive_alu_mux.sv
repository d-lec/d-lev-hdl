/*
--------------------------------------------------------------------------------

Module : hive_alu_mux.sv

--------------------------------------------------------------------------------

Function:
- Multiplexer for processor ALU.

Instantiates:
- (5x) pipe.sv

Dependencies:
- hive_pkg.sv

Notes:
- Inputs at stage 0, outputs at stage 6.
- Default behavior is logical pass-thru.

--------------------------------------------------------------------------------
*/

module hive_alu_mux
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// control I/O
	input			ALU_CTL_T						alu_ctl_i,					// alu op
	input			logic								mem_rd_i,					// 1=read
	input			logic								reg_rd_i,					// 1=read
	// data I/O
	input			logic	[ALU_W-1:0]				res_lg_3_i,					// logical result
	input			logic	[FLG_W-1:0]				flg_lg_3_i,					// logical flags
	input			logic	[ALU_W-1:0]				res_as_3_i,					// add/subtract result
	input			logic	[FLG_W-1:0]				flg_as_3_i,					// add/subtract flags
	input			logic	[PC_W-1:0]				pc_2_i,						// program counter
	input			logic	[ALU_W-1:0]				rbus_rd_data_i,			// rbus read data
	input			logic	[ALU_W-1:0]				mem_4_i,						// mem read data
	input			logic	[ALU_W-1:0]				res_ms_5_i,					// multiply/shift result
	input			logic	[FLG_W-1:0]				flg_ms_6_i,					// multiply/shift flags
	output		logic	[ALU_W-1:0]				result_6_o,					// result out
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
	logic												pc_sel_3;
	logic												as_sel_3, reg_rd_3;
	logic												mem_rd_4;
	logic												ms_sel_5, ms_sel_6;
	logic					[PC_W-1:0]				pc_3;
	logic					[ALU_W-1:0]				data_4, data_5;
	logic					[FLG_W-1:0]				flg_4, flg_5, flg_6;


	/*
	================
	== code start ==
	================
	*/


	// 0 to 3 regs
	pipe
	#(
	.DEPTH		( 3 ),
	.WIDTH		( 3 ),
	.RESET_VAL	( 0 )
	)
	regs_0_3
	(
	.*,
	.data_i		( { alu_ctl_i.pc_sel, alu_ctl_i.as_sel,   reg_rd_i } ),
	.data_o		( {           pc_sel_3,         as_sel_3, reg_rd_3 } )
	);

	// reg 2 => 3
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			pc_3 <= 0;
		end else begin
			pc_3 <= pc_2_i;
		end
	end

	// mux 3 => 4
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			flg_4 <= 0;
			data_4 <= 0;
		end else begin
			unique casex ( { reg_rd_3, as_sel_3, pc_sel_3 } )
				'b001   : flg_4 <= 0;  // pc
				'b01x   : flg_4 <= flg_as_3_i;  // arithmetic
				'b1xx   : flg_4 <= 0;  // register read
				default : flg_4 <= flg_lg_3_i;  // default logical
			endcase
			unique casex ( { reg_rd_3, as_sel_3, pc_sel_3 } )
				'b001   : data_4 <= pc_3;  // pc
				'b01x   : data_4 <= res_as_3_i;  // arithmetic
				'b1xx   : data_4 <= rbus_rd_data_i;  // register read
				default : data_4 <= res_lg_3_i;  // default logical
			endcase
		end
	end


	// 0 to 4 regs
	pipe
	#(
	.DEPTH		( 4 ),
	.WIDTH		( 1 ),
	.RESET_VAL	( 0 )
	)
	regs_0_4
	(
	.*,
	.data_i		( mem_rd_i ),
	.data_o		( mem_rd_4 )
	);

	// mux 4 => 5
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			flg_5 <= 0;
			data_5 <= 0;
		end else begin
			flg_5 <= ( mem_rd_4 ) ? '0 : flg_4;
			data_5 <= ( mem_rd_4 ) ? mem_4_i : data_4;
		end
	end


	// 0 to 5 regs
	pipe
	#(
	.DEPTH		( 5 ),
	.WIDTH		( 1 ),
	.RESET_VAL	( 0 )
	)
	regs_0_5
	(
	.*,
	.data_i		( { alu_ctl_i.ms_sel } ),
	.data_o		( {           ms_sel_5 } )
	);

	// mux 5 => 6 (out)
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			flg_6 <= 0;
			ms_sel_6 <= 0;
			result_6_o <= 0;
		end else begin
			flg_6 <= flg_5;
			ms_sel_6 <= ms_sel_5;
			result_6_o <= ( ms_sel_5 ) ? res_ms_5_i : data_5;
		end
	end

	// select flags
	always_comb flg_6_o = ( ms_sel_6 ) ? flg_ms_6_i : flg_6;
	
	
endmodule
