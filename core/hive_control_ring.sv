/*
--------------------------------------------------------------------------------

Module : hive_control_ring.sv

--------------------------------------------------------------------------------

Function:
- Processor control path.

Instantiates (at this level):
- (1x) hive_op_control.sv
- (1x) hive_id_ring.sv
- (1x) hive_tst_decode.sv
- (1x) hive_pc_ring.sv
- (1x) hive_vect_ring.sv

Dependencies:
- hive_pkg.sv

Notes:
- 8 stage pipeline consisting of several storage rings.

--------------------------------------------------------------------------------
*/

module hive_control_ring
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// control I/O
	input			logic								cla_i,						// clear all threads, active high
	input			logic	[THREADS-1:0]			xsr_i,						// external IRQ request
	output		logic								clt_o,						// clear thread, active high
	output		logic								irq_o,						// irq, active high
	output		logic	[THREADS-1:0]			irq_er_o,					// irq while in service, active high
	input			logic	[ALU_W-1:0]				oc_i,							// opcode
	output		ID_T								id_o,
	output		PC_T								pc_o,
	// alu I/O
	input			logic	[ALU_W-1:0]				a_i,							// operand
	input			logic	[ALU_W-1:0]				b_i,							// operand
	// rbus interface
	input			logic	[RBUS_ADDR_W-1:0]		rbus_addr_i,				// address
	input			logic								rbus_wr_i,					// data write enable, active high
	input			logic								rbus_rd_i,					// data read enable, active high
	input			logic	[ALU_W-1:0]				rbus_wr_data_i,			// write data
	output		logic	[ALU_W-1:0]				rbus_rd_data_o				// read data
	);


	
	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	import hive_types::*;
	//
	logic												cnd, jmp, gto, tst_res_3, imad;
	logic					[LEN_W-1:0]				len;
	TST_T												tst;
	logic					[PC_W-1:0]				im_pc;
	logic												clt, irq, irt;
	logic					[ALU_W-1:0]				vect_rd_data, time_rd_data;


	/*
	================
	== code start ==
	================
	*/


	// establish thread IDs
	hive_id_ring	hive_id_ring
	(
	.*,
	.rbus_rd_data_o	( time_rd_data )
	);


	// conditional jump etc. testing
	hive_tst_decode	hive_tst_decode
	(
	.*,
	.cnd_i				( cnd ),
	.tst_i				( tst ),
	.res_3_o				( tst_res_3 )
	);


	// opcode decoding
	hive_op_control	hive_op_control
	(
	.*,
	.clt_i				( clt_o ),
	.clt_o				( clt ),
	.irq_i				( irq_o ),
	.irq_o				( irq ),
	.irt_o				( irt ),
	.im_pc_o				( im_pc ),
	.cnd_o				( cnd ),
	.jmp_o				( jmp ),
	.gto_o				( gto ),
	.len_o				( len ),
	.tst_o				( tst ),
	.imad_o				( imad )
	);


	// pc generation & storage
	hive_pc_ring	hive_pc_ring
	(
	.*,
	.id_i					( id_o ),
	.clt_i				( clt ),
	.irq_i				( irq ),
	.jmp_i				( jmp ),
	.gto_i				( gto ),
	.len_i				( len ),
	.tst_res_3_i		( tst_res_3 ),
	.imad_i				( imad ),
	.b_i					( b_i ),
	.im_pc_i				( im_pc )
	);


	// vector handling
	hive_vector_ring  hive_vector_ring
	(
	.*,
	.rbus_rd_data_o	( vect_rd_data ),
	.id_i					( id_o ),
	.clt_i				( clt ),
	.irt_i				( irt ),
	.clt_7_o				( clt_o ),
	.irq_7_o				( irq_o )
	);


	// OR rbus read data
	always_comb rbus_rd_data_o = vect_rd_data | time_rd_data;


endmodule
