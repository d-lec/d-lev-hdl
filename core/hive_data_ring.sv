/*
--------------------------------------------------------------------------------

Module : hive_data_ring.sv

--------------------------------------------------------------------------------

Function:
- Processor data path & data stacks.

Instantiates (at this level):
- (1x) hive_op_data.sv
- (1x) hive_alu_top.sv
- (1x) hive_stack.sv
- (1x) hive_rbus.sv
- (1x) hive_reg_error.sv
- (1x) hive_reg_gpio.sv

Dependencies:
- hive_pkg.sv

Notes:
- 8 stage data pipeline beginning and ending on 8*8 BRAM based LIFOs.

--------------------------------------------------------------------------------
*/

module hive_data_ring
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// control I/O
	input			logic								clt_i,						// clear thread, active high
	input			logic								irq_i,						// irq, active high
	input			logic	[THREADS-1:0]			irq_er_i,					// irq while in service, active high
	input			logic	[ALU_W-1:0]				oc_i,							// opcode
	input			ID_T								id_i,							// id
	// data I/O
	output		logic	[ALU_W-1:0]				a_o,							// a
	output		logic	[ALU_W-1:0]				b_o,							// b 
	input			logic	[PC_W-1:0]				pc_2_i,						// program counter
	input			logic	[ALU_W-1:0]				mem_4_i,						// mem read data
	// mem I/O
	output		logic	[PC_W-1:0]				im_mem_o,					// mem immediate
	output		MEM_CTL_T						mem_ctl_o,					// mem ctl
	// GPIO
	input			logic	[ALU_W-1:0]				gpio_i,						// gpio
	output		logic	[ALU_W-1:0]				gpio_o,
	// rbus interface
	output		logic	[RBUS_ADDR_W-1:0]		rbus_addr_o,				// address
	output		logic								rbus_wr_o,					// data write enable, active high
	output		logic								rbus_rd_o,					// data read enable, active high
	output		logic	[ALU_W-1:0]				rbus_wr_data_o,			// write data
	input			logic	[ALU_W-1:0]				rbus_rd_data_i				// read data
	);


	
	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	import hive_types::*;
	//
	logic					[ALU_W-1:0]				data_6;
	logic					[FLG_W-1:0]				flg_6, a_flg, b_flg;
	ALU_CTL_T										alu_ctl;
	logic												mem_rd;
	logic					[STACKS-1:0]			cls, pop;
	logic					[STK_W-1:0]				a_sel, b_sel, sa, sb;
	logic												pa, pb, psh;
	logic												imda;
	logic					[ALU_W-1:0]				im_alu;
	logic												reg_rd, reg_wr;
	logic					[ALU_W-1:0]				rbus_rd_data_2, rbus_rd_data_3;
	logic					[ALU_W-1:0]				error_rd_data, gpio_rd_data;
	logic												op_er;
	logic												pop_er, psh_er;


	/*
	================
	== code start ==
	================
	*/


	// opcode decoding
	hive_op_data	hive_op_data
	(
	.*,
	.op_er_o				( op_er ),
	.im_alu_o			( im_alu ),
	.mem_rd_o			( mem_rd ),
	.reg_rd_o			( reg_rd ),
	.reg_wr_o			( reg_wr ),
	.a_sel_o				( a_sel ),
	.b_sel_o				( b_sel ),
	.cls_o				( cls ),
	.pop_o				( pop ),
	.sa_o					( sa ),
	.sb_o					( sb ),
	.pa_o					( pa ),
	.pb_o					( pb ),
	.psh_o				( psh ),
	.imda_o				( imda ),
	.alu_ctl_o			( alu_ctl )
	);


	// ALU
	hive_alu_top		hive_alu_top
	(
	.*,
	.imda_i				( imda ),
	.alu_ctl_i			( alu_ctl ),
	.a_i					( a_o ),
	.b_i					( b_o ),
	.b_flg_i				( b_flg ),
	.im_alu_i			( im_alu ),
	.mem_rd_i			( mem_rd ),
	.reg_rd_i			( reg_rd ),
	.rbus_rd_data_i	( rbus_rd_data_3 ),
	.result_6_o			( data_6 ),
	.flg_6_o				( flg_6 )
	);


	// stacks
	hive_stacks	hive_stacks
	(
	.*,
	.cls_i				( cls ),
	.pop_i				( pop ),
	.sa_i					( sa ),
	.sb_i					( sb ),
	.pa_i					( pa ),
	.pb_i					( pb ),
	.psh_i				( psh ),
	.data_6_i			( { flg_6, data_6 } ),
	.a_sel_i				( a_sel ),
	.b_sel_i				( b_sel ),
	.a_o					( { a_flg, a_o } ),
	.b_o					( { b_flg, b_o } ),
	.pop_er_o			( pop_er ),
	.psh_er_o			( psh_er )
	);


	hive_rbus  hive_rbus
	(
	.*,
	.imda_i				( imda ),
	.im_alu_i			( im_alu ),
	.a_i					( a_o ),
	.b_i					( b_o ),
	.reg_rd_i			( reg_rd ),
	.reg_wr_i			( reg_wr ),
	.rbus_rd_data_i	( rbus_rd_data_2 ),
	.rbus_rd_data_o	( rbus_rd_data_3 )
	);


	// OR rbus read data
	always_comb rbus_rd_data_2 = 
		error_rd_data |
		gpio_rd_data |
		rbus_rd_data_i;


	// error reg
	hive_reg_error  hive_reg_error
	(
	.*,
	.rbus_addr_i		( rbus_addr_o ),
	.rbus_wr_i			( rbus_wr_o ),
	.rbus_rd_i			( rbus_rd_o ),
	.rbus_wr_data_i	( rbus_wr_data_o ),
	.rbus_rd_data_o	( error_rd_data ),
	.op_er_i				( op_er ),
	.psh_er_i			( psh_er ),
	.pop_er_i			( pop_er ),
	.id_i					( id_i )
	);


	// gpio reg
	hive_reg_gpio  hive_reg_gpio
	(
	.*,
	.rbus_addr_i		( rbus_addr_o ),
	.rbus_wr_i			( rbus_wr_o ),
	.rbus_rd_i			( rbus_rd_o ),
	.rbus_wr_data_i	( rbus_wr_data_o ),
	.rbus_rd_data_o	( gpio_rd_data )
	);


endmodule
