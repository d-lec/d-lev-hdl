/*
--------------------------------------------------------------------------------

Module : hive_stacks_ring.sv

--------------------------------------------------------------------------------

Function:
- Processor stacks.

Instantiates:
- (1x) pipe.sv
- (8x) hive_stack_ring.sv

Dependencies:
- hive_pkg.sv

Notes:
- 8x8 stage pipelined BRAM based LIFOs.

--------------------------------------------------------------------------------
*/
module hive_stacks
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// stack control
	input			logic	[STACKS-1:0]			cls_i,						// per stack clear
	input			logic	[STACKS-1:0]			pop_i,						// per stack pop
	input			logic	[STK_W-1:0]				sa_i,							// stack a selector
	input			logic	[STK_W-1:0]				sb_i,							// stack b selector
	input			logic								pa_i,							// stack a pop (from sa_i)
	input			logic								pb_i,							// stack b pop (from sb_i)
	input			logic								psh_i,						// stack push (to sa_i)
	input			ID_T								id_i,							// id
	// data
	input			logic	[FLG_W+ALU_W-1:0]		data_6_i,					// push data
	input			logic	[STK_W-1:0]				a_sel_i,						// stack a selector
	input			logic	[STK_W-1:0]				b_sel_i,						// stack b selector
	output		logic	[FLG_W+ALU_W-1:0]		a_o,							// selected a data
	output		logic	[FLG_W+ALU_W-1:0]		b_o,							// selected b data
	// diag
	output		logic								pop_er_o,					// pop when empty, active high 
	output		logic								psh_er_o						// push when full, active high
	);

	
	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	import hive_types::*;
	//
	logic					[FLG_W+ALU_W-1:0]		data[STACKS];				// stacks data
	logic					[STACKS-1:0]			pop_a, pop_b;				// per stack pop
	logic					[STACKS-1:0]			pop_1;						// combined pops
	logic					[STACKS-1:0]			pop_er_2;					// pop when empty, active high 
	logic					[7:3]						pop_er_sr; 
	//
	logic												psh_4;						// stack push
	logic					[STK_W-1:0]				sa_4;							// stack selector
	logic					[STACKS-1:0]			psh_5;						// per stack push
	logic					[STACKS-1:0]			psh_er_6;					// push when full, active high
	logic												psh_er_sr;
	//
	genvar											g;


	/*
	================
	== code start ==
	================
	*/


	// pop decode
	always_comb pop_a  = pa_i << sa_i;
	always_comb pop_b  = pb_i << sb_i;

	// decode & register
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			pop_1 <= 0;
		end else begin
			pop_1 <= pop_a | pop_b | pop_i;
		end
	end


	// 0:4 pipe
	pipe
	#(
	.DEPTH		( 4 ),
	.WIDTH		( 1+STK_W ),
	.RESET_VAL	( 0 )
	)
	pipe_0_4
	(
	.*,
	.data_i		( { psh_i, sa_i } ),
	.data_o		( { psh_4, sa_4 } )
	);


	// decode & register
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			psh_5 <= 0;
		end else begin
			psh_5 <= psh_4 << sa_4;
		end
	end


	// per stack rings
	generate
		for ( g=0; g<STACKS; g=g+1 ) begin : stack_loop
			hive_stack_ring  hive_stack_ring
			(
			.*,
			.cls_i			( cls_i[g] ),
			.pop_1_i			( pop_1[g] ),
			.psh_5_i			( psh_5[g] ),
			.id_6_i			( id_i[6] ),
			.data_o			( data[g] ),
			.pop_er_2_o		( pop_er_2[g] ),
			.psh_er_6_o		( psh_er_6[g] )
			);
		end  // endfor
	endgenerate


	// data muxes
	always_comb a_o = data[a_sel_i];
	always_comb b_o = data[b_sel_i];

	// combine / pipeline / output errors
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			{ pop_er_o, pop_er_sr } <= 0;
			{ psh_er_o, psh_er_sr } <= 0;
		end else begin
			{ pop_er_o, pop_er_sr } <= { pop_er_sr, |pop_er_2 };
			{ psh_er_o, psh_er_sr } <= { psh_er_sr, |psh_er_6 };
		end
	end


endmodule
