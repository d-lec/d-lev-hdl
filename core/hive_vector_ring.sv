/*
--------------------------------------------------------------------------------

Module: hive_vector_sm.sv

Function: 
- Vector (clear & interrupt) state machines for processor threads.

Instantiates: 
- (1x) in_cond.sv

Dependencies:
- None.

Notes:
- Clear / IRQ latched until output.
- Automatic thread clearing @ async reset.
- Interrupts automatically disarmed with associated thread clear.
- Interrupt arm / disarm requests behave like set / reset FF.
- Interrupt service history tracked, no new IRQ issued until the 
  current one is done.  History cleared @ thread clear.

--------------------------------------------------------------------------------
*/
module hive_vector_sm
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// external interface
	input			logic								cla_i,						// clear all, active high
	input			logic	[THREADS-1:0]			xsr_i,						// external interrupts, active high
	output		logic	[THREADS-1:0]			irq_er_o,					// irq while in service, active high
	// request interface
	input			logic								wr_i,							// write, active high
	input			logic	[THREADS-1:0]			wr_arm_i,					// write arm, active high
	input			logic	[THREADS-1:0]			wr_dis_i,					// write dis, active high
	input			logic	[THREADS-1:0]			wr_isr_i,					// write isr, active high
	input			logic	[THREADS-1:0]			wr_clt_i,					// write clt, active high
	output		logic	[THREADS-1:0]			armed_o,						// armed status, active high
	output		logic	[THREADS-1:0]			insvc_o,						// in service status, active high
	// serial interface
	input			ID_T								id_i,							// thread ID
	input			logic								clt_i,						// clear thread, active high
	input			logic								irt_i,						// isr return, active high
	output		logic								clt_o,						// clear thread, active high
	output		logic								irq_o							// interrupt, active high
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	import hive_types::*; 
	import hive_defines::*;
	//
	logic					[THREADS-1:0]			xsr;
	logic					[THREADS-1:0]			en_1, en_2;
	logic					[THREADS-1:0]			irq_pend, clt_pend;


	/*
	================
	== code start ==
	================
	*/


	// input conditioning
	in_cond
	#(
	.DATA_W			( THREADS ),
	.SYNC_W			( SYNC_W ),
	.LIVE_MASK		( XSR_LIVE_MASK ),
	.SYNC_MASK		( XSR_SYNC_MASK ),
	.RISE_MASK		( XSR_RISE_MASK ),
	.FALL_MASK		( XSR_FALL_MASK )
	)
	xsr_in_cond
	(
	.*,
	.data_i			( xsr_i ),
	.data_o			( xsr )
	);


	// one-hot enables
	always_comb en_1 = 1'b1 << id_i[1];
	always_comb en_2 = 1'b1 << id_i[2];
	
	// set & reset state
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			armed_o <= 0;
			insvc_o <= 0;
			irq_pend <= 0;
			clt_pend <= '1;  // note: assert @ async reset!
			irq_er_o <= 0;
		end else begin
			irq_er_o <= 0;  // clear errors
			// loop thru bits:
			for ( int g = 0; g < THREADS; g = g + 1 ) begin
				/////////////////////////
				// do 1st (precedence) //
				/////////////////////////
				// set arm @ arm write
				if ( wr_i & wr_arm_i[g] ) 
					armed_o[g] <= '1;
				// set service state @ isr write or armed xsr
				if ( ( wr_i & wr_isr_i[g] ) | ( xsr[g] & armed_o[g] ) ) 
					insvc_o[g] <= '1;
				// clear pendings @ issue
				if ( en_2[g] ) begin
					irq_pend[g] <= 0;
					clt_pend[g] <= 0;
				end
				/////////////////////////
				// do 2nd (precedence) //
				/////////////////////////
				// set irq error @ inservice & (isr write or armed xsr)
				if ( insvc_o[g] & ( ( wr_i & wr_isr_i[g] ) | ( xsr[g] & armed_o[g] ) ) ) 
					irq_er_o[g] <= '1;
				// clear arm @ dis write or clt
				if ( ( wr_i & wr_dis_i[g] ) | ( en_1[g] & clt_i ) ) 
					armed_o[g] <= 0;
				// clear service state @ clt or irt
				if ( en_1[g] & ( clt_i | irt_i ) ) 
					insvc_o[g] <= 0;
				// set pending irq
				if ( !insvc_o[g] & ( ( wr_i & wr_isr_i[g] ) | ( xsr[g] & armed_o[g] ) ) ) 
					irq_pend[g] <= '1;
				// set pending clt @ core clear or clt
				if ( cla_i | ( wr_i & wr_clt_i[g] ) ) 
					clt_pend[g] <= '1;
			end  // bit loop end
		end
	end

	// decode outputs
	always_comb clt_o = clt_pend[id_i[2]];
	always_comb irq_o = irq_pend[id_i[2]];


endmodule



/*
--------------------------------------------------------------------------------

Module: hive_vector_ring.sv

Function: 
- Vector (clear & interrupt) control for multiple processor threads.

Instantiates: 
- (1x) hive_vector_sm.sv
  - (1x) in_cond.sv
- (2x) pipe.sv
- (1x) hive_reg_base.sv

Dependencies:
- hive_pkg.sv

Notes:
- See hive_vector_sm.sv for details.
- Internally pipelined from opcode decoder output to input.

--------------------------------------------------------------------------------
*/
module hive_vector_ring
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// external interface
	input			logic								cla_i,						// clear all, active high
	input			logic	[THREADS-1:0]			xsr_i,						// external interrupts, active high
	output		logic	[THREADS-1:0]			irq_er_o,					// irq while in service, active high
	// rbus interface
	input			logic	[RBUS_ADDR_W-1:0]		rbus_addr_i,				// address
	input			logic								rbus_wr_i,					// data write enable, active high
	input			logic								rbus_rd_i,					// data read enable, active high
	input			logic	[ALU_W-1:0]				rbus_wr_data_i,			// write data
	output		logic	[ALU_W-1:0]				rbus_rd_data_o,			// read data
	// multiplexed serial interface
	input			ID_T								id_i,							// thread ID
	input			logic								clt_i,						// clear thread, active high
	input			logic								irt_i,						// irq return, active high
	output		logic								clt_7_o,						// clear thread, active high
	output		logic								irq_7_o						// irq, active high
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	import hive_types::*; 
	import hive_defines::*;
	//
	logic												clt_1, irt_1;
	logic												clt_2, irq_2;
	logic												reg_wr;
	logic						[THREADS-1:0]		wr_arm_1, wr_dis_1, wr_isr_1, wr_clt_1;
	logic						[THREADS-1:0]		armed_2, insvc_2;


	/*
	================
	== code start ==
	================
	*/


	// 0:1 pipe
	pipe
	#(
	.DEPTH		( 1 ),
	.WIDTH		( 1+1 ),
	.RESET_VAL	( 0 )
	)
	pipe_0_1
	(
	.*,
	.data_i		( { irt_i, clt_i } ),
	.data_o		( { irt_1, clt_1 } )
	);


	// state machines
	hive_vector_sm  hive_vector_sm
	(
	.*,
	.wr_i				( reg_wr ),
	.wr_arm_i		( wr_arm_1 ),
	.wr_dis_i		( wr_dis_1 ),
	.wr_isr_i		( wr_isr_1 ),
	.wr_clt_i		( wr_clt_1 ),
	.armed_o			( armed_2 ),
	.insvc_o			( insvc_2 ),
	.clt_i			( clt_1 ),
	.irt_i			( irt_1 ),
	.clt_o			( clt_2 ),
	.irq_o			( irq_2 )
	);



	// 2:7 pipe
	pipe
	#(
	.DEPTH		( 5 ),
	.WIDTH		( 1+1 ),
	.RESET_VAL	( 2'b01 )  // note: assert clear @ async reset!
	)
	pipe_2_7
	(
	.*,
	.data_i		( { irq_2,     clt_2 } ),
	.data_o		( { irq_7_o, clt_7_o } )
	);


	// rbus register
	hive_reg_base
	#(
	.DATA_W			( ALU_W ),
	.ADDR_W			( RBUS_ADDR_W ),
	.ADDR				( `RBUS_VECT ),
	.WR_MODE			( "THRU" ),
	.RD_MODE			( "THRU" )
	)
	vect_reg
	(
	.*,
	.reg_wr_o		( reg_wr ),
	.reg_rd_o		(  ),
	.reg_data_o		( { wr_clt_1, wr_isr_1, wr_dis_1, wr_arm_1 } ),
	.reg_data_i		( { HLF_W'( CORE_VER ),  insvc_2,  armed_2 } )
	);


endmodule
