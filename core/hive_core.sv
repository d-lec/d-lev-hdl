/*
--------------------------------------------------------------------------------

Module : hive_core.sv

--------------------------------------------------------------------------------

Function:
- General purpose barrel processor FPGA core with:
  - 8 threads & 8 stage pipeline
  - 8 indexed LIFO stacks per thread w/ pop control
  - 32 bit data
  - 1 to 4 byte opcode
  - 4 basic control registers

Instantiates (at this level):
- hive_control_ring.sv
- hive_data_ring.sv
- hive_main_mem.sv

Dependencies:
- hive_pkg.sv

--------------------------------------------------------------------------------
*/

module hive_core
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	//
	input			logic								cla_i,						// clear all threads, active high
	input			logic	[THREADS-1:0]			xsr_i,						// external IRQ request
	//
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
	logic					[ALU_W-1:0]				oc_7;
	logic												clt_7, irq_7;
	ID_T												id;
	PC_T												pc;
	logic					[PC_W-1:0]				im_mem;
	MEM_CTL_T										mem_ctl;
	logic					[ALU_W-1:0]				a, b;
	logic					[ALU_W-1:0]				mem_4;
	logic												op_er;
	logic					[ALU_W-1:0]				rbus_rd_data, ctrl_rd_data;
	logic												pop_er, psh_er;
	logic					[THREADS-1:0]			irq_er;



	/*
	================
	== code start ==
	================
	*/


	// control ring
	hive_control_ring  hive_control_ring
	(
	.*,
	.clt_o				( clt_7 ),
	.irq_o				( irq_7 ),
	.irq_er_o			( irq_er ),
	.oc_i					( oc_7 ),
	.id_o					( id ),
	.pc_o					( pc ),
	.a_i					( a ),
	.b_i					( b ),
	.rbus_addr_i		( rbus_addr_o ),
	.rbus_wr_i			( rbus_wr_o ),
	.rbus_rd_i			( rbus_rd_o ),
	.rbus_wr_data_i	( rbus_wr_data_o ),
	.rbus_rd_data_o	( ctrl_rd_data )
	);


	// OR rbus read data
	always_comb rbus_rd_data = 
		ctrl_rd_data | 
		rbus_rd_data_i;


	// data ring
	hive_data_ring  hive_data_ring
	(
	.*,
	.clt_i				( clt_7 ),
	.irq_i				( irq_7 ),
	.irq_er_i			( irq_er ),
	.oc_i					( oc_7 ),
	.id_i					( id ),
	.a_o					( a ),
	.b_o					( b ),
	.pc_2_i				( pc[2] ),
	.mem_4_i				( mem_4 ),
	.im_mem_o			( im_mem ),
	.mem_ctl_o			( mem_ctl ),
	.rbus_rd_data_i	( rbus_rd_data )
	);


	// instruction and data memory
	hive_main_mem  hive_main_mem
	(
	.*,
	.mem_ctl_i			( mem_ctl ),
	.pc_1_i				( pc[1] ),
	.im_i					( im_mem ),
	.b_i					( b ),
	.a_i					( a ),
	.mem_4_o				( mem_4 ),
	.pc_4_i				( pc[4] ),
	.oc_7_o				( oc_7 )
	);


endmodule
