/*
--------------------------------------------------------------------------------

Module: hive_main_mem.sv

Function: 
- Main memory.

Instantiates: 
- (1x) ram_dp_quad.sv
- (2x) pipe.sv

Dependencies:
- hive_pkg.sv

Notes:
- Address indexes bytes.
- Inputs registered.
- Size ADDR_W for desired memory depth.
- Reads & writes aligned / unaligned 32 bit, 16 bit, and 8 bit I/O.
- Reads signed, unsigned.

--------------------------------------------------------------------------------
*/

module hive_main_mem
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// data port
	input			MEM_CTL_T						mem_ctl_i,					// selector
	input			logic	[PC_W-1:0]				pc_1_i,						// program counter
	input			logic	[PC_W-1:0]				im_i,							// immediate address offset
	input			logic	[MEM_ADDR_W-1:0]		b_i,							// address
	input			logic	[ALU_W-1:0]				a_i,							// write data
	output		logic	[ALU_W-1:0]				mem_4_o,						// read data
	// opcode port
	input			logic	[PC_W-1:0]				pc_4_i,						// program counter
	output		logic	[ALU_W-1:0]				oc_7_o						// opcode
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	import hive_types::*;
	localparam										WR_W = 4;
	//
	logic												lit_1;
	logic												wr_1;
	logic												byt_1, byt_2, byt_4;
	logic												sgn_1, sgn_2, sgn_4;
	logic												hlf_1, hlf_2, hlf_4;
	logic					[WR_W-2:0]				inc_2;
	logic					[WR_W-1:0]				wr_rol_2, wr_en_2;
	logic					[MEM_ADDR_W-1:0]		b_1, b_sel_1, b_sel_2;
	logic					[MEM_ADDR_W-3:0]		b_2;
	logic					[1:0]						b_sel_4;
	logic					[PC_W-1:0]				im_1;
	logic					[BYT_W-1:0]				a_1[WR_W], a_2[WR_W];
	logic					[BYT_W-1:0]				mem_4[WR_W];
	logic					[ALU_W-1:0]				mem_ror_4;
	logic					[BYT_W-1:0]				oc_6[WR_W];
	logic					[PC_W-1:0]				pc_4[WR_W];
	logic					[1:0]						pc_6;

	/*
	================
	== code start ==
	================
	*/

	// in to 1 regs
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			{ a_1[3], a_1[2], a_1[1], a_1[0] } <= 0;
			b_1 <= 0;
			im_1 <= 0;
			wr_1 <= 0;
			byt_1 <= 0;
			hlf_1 <= 0;
			sgn_1 <= 0;
			lit_1 <= 0;
		end else begin
			{ a_1[3], a_1[2], a_1[1], a_1[0] } <= a_i;
			b_1 <= b_i;
			im_1 <= im_i;
			wr_1 <= mem_ctl_i.wr;
			byt_1 <= mem_ctl_i.byt;
			hlf_1 <= mem_ctl_i.hlf;
			sgn_1 <= mem_ctl_i.sgn;
			lit_1 <= mem_ctl_i.lit;
		end
	end

	// select pc or offset address
	always_comb b_sel_1 = ( lit_1 ) ? MEM_ADDR_W'( pc_1_i + im_1 ) : MEM_ADDR_W'( b_1 + im_1 );

	// 1 to 2 decode & regs
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			b_sel_2 <= 0;
			byt_2 <= 0;
			hlf_2 <= 0;
			sgn_2 <= 0;
			{ a_2[3], a_2[2], a_2[1], a_2[0] } <= 0;
			inc_2 <= 0;
			wr_rol_2 <= 0;
		end else begin
			b_sel_2 <= b_sel_1;
			byt_2 <= byt_1;
			hlf_2 <= hlf_1;
			sgn_2 <= sgn_1;
			// input byte barrel shifter
			unique case ( b_sel_1[1:0] )
				'b00 : { a_2[3], a_2[2], a_2[1], a_2[0] } <= { a_1[3], a_1[2], a_1[1], a_1[0] };
				'b01 : { a_2[3], a_2[2], a_2[1], a_2[0] } <= { a_1[2], a_1[1], a_1[0], a_1[3] };
				'b10 : { a_2[3], a_2[2], a_2[1], a_2[0] } <= { a_1[1], a_1[0], a_1[3], a_1[2] };
				'b11 : { a_2[3], a_2[2], a_2[1], a_2[0] } <= { a_1[0], a_1[3], a_1[2], a_1[1] };
			endcase
			// inc decode
			unique casex ( b_sel_1[1:0] )
				'b00 : inc_2 <= 'b000;
				'b01 : inc_2 <= 'b001;
				'b10 : inc_2 <= 'b011;
				'b11 : inc_2 <= 'b111;
			endcase
			// input write barrel shifter
			unique casex ( { wr_1, hlf_1, byt_1, b_sel_1[1:0] } )
				'b0xxxx : wr_rol_2 <= '0;
				'b100xx : wr_rol_2 <= '1;
				'b101xx : wr_rol_2 <= 1'b1 << b_sel_1[1:0];
				'b11x00 : wr_rol_2 <= 'b0011;
				'b11x01 : wr_rol_2 <= 'b0110;
				'b11x10 : wr_rol_2 <= 'b1100;
				'b11x11 : wr_rol_2 <= 'b1001;
			endcase
		end
	end

	// drop 2 LSb's
	always_comb b_2 = b_sel_2[MEM_ADDR_W-1:2];


	// instruction and data memory
	ram_dp_quad
	#(
	.DATA_W				( BYT_W ),  // byte
	.ADDR_W				( MEM_ADDR_W-2 ),  // quad
	.A_REG				( 1 ),
	.B_REG				( 1 ),
	.A_MODE 				( "RAW" ),  // functional don't care
	.B_MODE 				( "RAW" )  // functional don't care
	)
	mem
	(
	.*,
	// data port
	.a3_addr_i			( b_2 ),
	.a2_addr_i			( b_2 + inc_2[2] ),
	.a1_addr_i			( b_2 + inc_2[1] ),
	.a0_addr_i			( b_2 + inc_2[0]),
	.a3_wr_i				( wr_rol_2[3] ),
	.a2_wr_i				( wr_rol_2[2] ),
	.a1_wr_i				( wr_rol_2[1] ),
	.a0_wr_i				( wr_rol_2[0] ),
	.a3_i					( a_2[3] ),
	.a2_i					( a_2[2] ),
	.a1_i					( a_2[1] ),
	.a0_i					( a_2[0] ),
	.a3_o					( mem_4[3] ),
	.a2_o					( mem_4[2] ),
	.a1_o					( mem_4[1] ),
	.a0_o					( mem_4[0] ),
	// opcode port
	.b3_addr_i			( pc_4[3][MEM_ADDR_W-1:2] ),
	.b2_addr_i			( pc_4[2][MEM_ADDR_W-1:2] ),
	.b1_addr_i			( pc_4[1][MEM_ADDR_W-1:2] ),
	.b0_addr_i			( pc_4[0][MEM_ADDR_W-1:2] ),
	.b3_wr_i				( 1'b0 ),  // unused
	.b2_wr_i				( 1'b0 ),  // unused
	.b1_wr_i				( 1'b0 ),  // unused
	.b0_wr_i				( 1'b0 ),  // unused
	.b3_i					(  ),  // unused
	.b2_i					(  ),  // unused
	.b1_i					(  ),  // unused
	.b0_i					(  ),  // unused
	.b3_o					( oc_6[3] ),
	.b2_o					( oc_6[2] ),
	.b1_o					( oc_6[1] ),
	.b0_o					( oc_6[0] )
	);


	// 2 to 4 regs
	pipe
	#(
	.DEPTH		( 2 ),
	.WIDTH		( 5 ),
	.RESET_VAL	( 0 )
	)
	regs_2_4
	(
	.*,
	.data_i		( { sgn_2, hlf_2, byt_2, b_sel_2[1:0] } ),
	.data_o		( { sgn_4, hlf_4, byt_4, b_sel_4 } )
	);


	// output byte barrel shifter
	always_comb begin
		unique case ( b_sel_4 )
			'b00 : mem_ror_4 = { mem_4[3], mem_4[2], mem_4[1], mem_4[0] };
			'b01 : mem_ror_4 = { mem_4[0], mem_4[3], mem_4[2], mem_4[1] };
			'b10 : mem_ror_4 = { mem_4[1], mem_4[0], mem_4[3], mem_4[2] };
			'b11 : mem_ror_4 = { mem_4[2], mem_4[1], mem_4[0], mem_4[3] };
		endcase
	end

	// zero and sign extend
	always_comb begin
		unique casex ( { sgn_4, hlf_4, byt_4 } )
			'b0x1   : mem_4_o = mem_ror_4[BYT_W-1:0];  // byte zero extend
			'b1x1   : mem_4_o = $signed( mem_ror_4[BYT_W-1:0] );  // byte sign extend
			'b010   : mem_4_o = mem_ror_4[HLF_W-1:0];  // hlf zero extend
			'b110   : mem_4_o = $signed( mem_ror_4[HLF_W-1:0] );  // hlf sign extend
			default : mem_4_o = mem_ror_4;  // default is pass-thru
		endcase
	end

	// inc addresses
	always_comb pc_4[3] = pc_4_i;
	always_comb pc_4[2] = pc_4_i + 2'd1;
	always_comb pc_4[1] = pc_4_i + 2'd2;
	always_comb pc_4[0] = pc_4_i + 2'd3;


	// 4 to 6 regs
	pipe
	#(
	.DEPTH		( 2 ),
	.WIDTH		( 2 ),
	.RESET_VAL	( 0 )
	)
	regs_4_6
	(
	.*,
	.data_i		( pc_4_i[1:0] ),
	.data_o		( pc_6 )
	);


	// 6 to 7 barrel shift & output reg
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			oc_7_o <= 0;
		end else begin
			unique case ( pc_6 )
				'b00 : oc_7_o <= { oc_6[3], oc_6[2], oc_6[1], oc_6[0] };
				'b01 : oc_7_o <= { oc_6[0], oc_6[3], oc_6[2], oc_6[1] };
				'b10 : oc_7_o <= { oc_6[1], oc_6[0], oc_6[3], oc_6[2] };
				'b11 : oc_7_o <= { oc_6[2], oc_6[1], oc_6[0], oc_6[3] };
			endcase
		end
	end


endmodule
