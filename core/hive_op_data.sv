/*
--------------------------------------------------------------------------------

Module : hive_op_data.sv

--------------------------------------------------------------------------------

Function:
- Opcode decoder for hive processor data ring.

Instantiates: 
- Nothing.

Dependencies:
- hive_pkg.sv

Notes:
- Outputs registered.
- Operates on the current thread in the stage (i.e. no internal state).
- Illegal opcodes are only flagged, not necessarily safely decoded as NOP.

--------------------------------------------------------------------------------
*/

module hive_op_data
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// state I/O
	input			logic								clt_i,						// clear thread, active high
	input			logic								irq_i,						// irq, active high
	input			logic	[ALU_W-1:0]				oc_i,							// opcode
	output		logic								op_er_o,						// 1=illegal operation encountered
	// data I/O
	output		logic	[ALU_W-1:0]				im_alu_o,					// alu immediate
	output		logic	[PC_W-1:0]				im_mem_o,					// mem immediate
	// mem & reg control
	output		MEM_CTL_T						mem_ctl_o,					// mem ctl
	output		logic								mem_rd_o,					// 1=mem read
	output		logic								reg_rd_o,					// 1=reg read
	output		logic								reg_wr_o,					// 1=reg write
	// stacks control
	output		logic	[STK_W-1:0]				a_sel_o,						// a data selector
	output		logic	[STK_W-1:0]				b_sel_o,						// b data selector
	output		logic	[STACKS-1:0]			cls_o,						// per stack clear
	output		logic	[STACKS-1:0]			pop_o,						// per stack pop
	output		logic	[STK_W-1:0]				sa_o,							// a stack selector
	output		logic	[STK_W-1:0]				sb_o,							// b stack selector
	output		logic								pa_o,							// a pop (from sa_o)
	output		logic								pb_o,							// b pop (from sb_o)
	output		logic								psh_o,						// a push (to sa_o)
	// immediate flags
	output		logic								imda_o,						// 1=immediate data
	// alu control
	output		ALU_CTL_T						alu_ctl_o					// alu ctl
	);



	
	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	import hive_types::*;
	//
	OC_T												oc;
	logic					[STK_W-1:0]				oc_sa, oc_sb;
	logic 											oc_pa, oc_pb;
	logic					[BYT_W-1:0]				oc_im8_lo;
	logic					[BYT_W-1:0]				oc_im8;
	logic					[HLF_W-1:0]				oc_im16;
	logic 											pa, pb;



	/*
	================
	== code start ==
	================
	*/


	// split out opcode fields
	always_comb	oc = OC_T'(oc_i[7:0]);
	always_comb	oc_sa = oc_i[10:8];
	always_comb	oc_pa = oc_i[11];
	always_comb	oc_sb = oc_i[14:12];
	always_comb	oc_pb = oc_i[15];
	always_comb	oc_im8_lo = oc_i[15:8];
	always_comb	oc_im8 = oc_i[23:16];
	always_comb	oc_im16 = oc_i[31:16];


	// register if & case: clear, interrupt, and opcode decode
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			op_er_o <= 0;
			cls_o <= 0;
			pop_o <= 0;
			pa_o <= 0;
			pb_o <= 0;
			psh_o <= 0;
			a_sel_o <= 0;
			b_sel_o <= 0;
			sa_o <= 0;
			sb_o <= 0;
			imda_o <= 0;
			im_alu_o <= 'x;
			im_mem_o <= 'x;
			mem_ctl_o.lit <= 0;
			mem_ctl_o.hlf <= 0;
			mem_ctl_o.sgn <= 0;
			mem_ctl_o.byt <= 0;
			mem_ctl_o.wr <= 0;
			mem_rd_o <= 0;
			reg_wr_o <= 0;
			reg_rd_o <= 0;
			alu_ctl_o.as_sel <= 0;
			alu_ctl_o.ms_sel <= 0;
			alu_ctl_o.pc_sel <= 0;
			alu_ctl_o.ext <= 0;
			alu_ctl_o.lg_op <= LG_OP_T'( 'x );
			alu_ctl_o.as_op <= AS_OP_T'( 'x );
			alu_ctl_o.ms_op <= MS_OP_T'( 'x );
		end else begin
			// clocked default values
			op_er_o <= 0;  // default is no error
			mem_ctl_o.lit <= 0;  // default is no lit
			cls_o <= 0;  // default is no im stack clear
			pop_o <= 0;  // default is no im pop
			a_sel_o <= oc_sa;  // default is opcode directive
			b_sel_o <= oc_sb;  // default is opcode directive
			sa_o <= oc_sa;  // default is opcode directive
			sb_o <= oc_sb;  // default is opcode directive
			pa_o <= oc_pa;  // default is opcode directive
			pb_o <= oc_pb;  // default is opcode directive
			psh_o <= 0;  // default is no push
			imda_o <= 0;  // default is not immediate data
			im_alu_o <= $signed( oc_im8 );  // default is $signed( oc_im8 )
			im_mem_o <= 0;  // default is 0
			mem_ctl_o.hlf <= 0;  // default is not hlf
			mem_ctl_o.sgn <= 0;  // default is unsigned
			mem_ctl_o.byt <= 0;  // default is not byte
			mem_ctl_o.wr <= 0;  // default is don't write
			mem_rd_o <= 0;  // default is don't read
			reg_rd_o <= 0;  // default is don't read
			reg_wr_o <= 0;  // default is don't write
			alu_ctl_o.as_sel <= 0;  // default is logical
			alu_ctl_o.ms_sel <= 0;  // default is logical
			alu_ctl_o.pc_sel <= 0;  // default is logical
			alu_ctl_o.ext <= 0;  // default is not extended
			alu_ctl_o.lg_op <= LG_OP_T'( 'x );  // default is don't care
			alu_ctl_o.as_op <= AS_OP_T'( 'x );  // default is don't care
			alu_ctl_o.ms_op <= MS_OP_T'( 'x );  // default is don't care
			if ( clt_i ) begin  // clear thread
				cls_o <= '1;  // clear stacks
				pa_o <= 0;  // no pop
				pb_o <= 0;  // no pop
			end else if ( irq_i ) begin  // interrupt thread
				psh_o <= '1;  // push
				sa_o <= STK_W'(STACKS-1);  // push to higest stack (7)
				alu_ctl_o.pc_sel <= '1;  // push pc
				pa_o <= 0;  // no pop
				pb_o <= 0;  // no pop
			end else begin
				// examine byte
				unique casex ( oc )
					op_nop : begin
						pa_o <= 0;  // no pop
						pb_o <= 0;  // no pop
					end
					op_hlt : begin
						pa_o <= 0;  // no pop
						pb_o <= 0;  // no pop
					end
					op_pop : begin
						pop_o <= oc_im8_lo;  // pop via im
						pa_o <= 0;  // no pop
						pb_o <= 0;  // no pop
					end
					op_cls : begin
						cls_o <= oc_im8_lo;  // cls via im
						pa_o <= 0;  // no pop
						pb_o <= 0;  // no pop
					end
					op_jmp_8, op_jmp_16, op_jmp_24 : begin
						pa_o <= 0;  // no pop
						pb_o <= 0;  // no pop
					end
					op_add_xu : begin
						alu_ctl_o.as_op <= as_add_u;
						alu_ctl_o.as_sel <= '1;	// add/sub
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_add_xus : begin
						alu_ctl_o.as_op <= as_add_us;
						alu_ctl_o.as_sel <= '1;	// add/sub
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_add_xsu : begin
						alu_ctl_o.as_op <= as_add_su;
						alu_ctl_o.as_sel <= '1;	// add/sub
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_add_xs : begin
						alu_ctl_o.as_op <= as_add_s;
						alu_ctl_o.as_sel <= '1;	// add/sub
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_sub_xu : begin
						alu_ctl_o.as_op <= as_sub_u;
						alu_ctl_o.as_sel <= '1;	// add/sub
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_sub_xus : begin
						alu_ctl_o.as_op <= as_sub_us;
						alu_ctl_o.as_sel <= '1;	// add/sub
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_sub_xsu : begin
						alu_ctl_o.as_op <= as_sub_su;
						alu_ctl_o.as_sel <= '1;	// add/sub
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_sub_xs : begin
						alu_ctl_o.as_op <= as_sub_s;
						alu_ctl_o.as_sel <= '1;	// add/sub
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_sbr_xu : begin
						alu_ctl_o.as_op <= as_sbr_u;
						alu_ctl_o.as_sel <= '1;	// add/sub
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_sbr_xus : begin
						alu_ctl_o.as_op <= as_sbr_us;
						alu_ctl_o.as_sel <= '1;	// add/sub
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_sbr_xsu : begin
						alu_ctl_o.as_op <= as_sbr_su;
						alu_ctl_o.as_sel <= '1;	// add/sub
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_sbr_xs : begin
						alu_ctl_o.as_op <= as_sbr_s;
						alu_ctl_o.as_sel <= '1;	// add/sub
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_mul_xu : begin
						alu_ctl_o.ms_op <= ms_mul_u;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_mul_xus : begin
						alu_ctl_o.ms_op <= ms_mul_us;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_mul_xsu : begin
						alu_ctl_o.ms_op <= ms_mul_su;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_mul_xs : begin
						alu_ctl_o.ms_op <= ms_mul_s;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						alu_ctl_o.ext <= '1; // ext
						psh_o <= '1;  // push
					end
					op_cpy : begin
						alu_ctl_o.lg_op <= lg_cpy;
						psh_o <= '1;  // push
					end
					op_nsb : begin
						alu_ctl_o.lg_op <= lg_nsb;
						psh_o <= '1;  // push
					end
					op_lim : begin
						alu_ctl_o.lg_op <= lg_lim;
						psh_o <= '1;  // push
					end
					op_sat : begin
						alu_ctl_o.lg_op <= lg_sat;
						psh_o <= '1;  // push
					end
					op_flp : begin
						alu_ctl_o.lg_op <= lg_flp;
						psh_o <= '1;  // push
					end
					op_swp : begin
						alu_ctl_o.lg_op <= lg_swp;
						psh_o <= '1;  // push
					end
					op_not : begin
						alu_ctl_o.lg_op <= lg_not;
						psh_o <= '1;  // push
					end
					op_brx : begin
						alu_ctl_o.lg_op <= lg_brx;
						psh_o <= '1;  // push
					end
					op_sgn : begin
						alu_ctl_o.lg_op <= lg_sgn;
						psh_o <= '1;  // push
					end
					op_lzc : begin
						alu_ctl_o.lg_op <= lg_lzc;
						psh_o <= '1;  // push
					end
					op_jmp_z, op_jmp_nz, op_jmp_lz, op_jmp_nlz : begin
						// legal op
					end
					op_jmp, op_gto, op_irt : begin
						// legal op
					end
					op_jsb, op_gsb, op_pcr : begin
						alu_ctl_o.pc_sel <= '1;  // psh pc
						psh_o <= '1;  // push
					end
					op_mem_r : begin  // memory read
						mem_rd_o <= '1;  // read
						psh_o <= '1;  // push
					end
					op_mem_w : begin  // memory write
						mem_ctl_o.wr <= '1;  // write
					end
					op_mem_wh : begin  // memory write hlf
						mem_ctl_o.wr <= '1;  // write
						mem_ctl_o.hlf <= '1;  // hlf
					end
					op_mem_wb : begin  // memory write byte
						mem_ctl_o.wr <= '1;  // write
						mem_ctl_o.byt <= '1;  // byte
					end
					op_mem_rhs : begin  // memory read hlf
						mem_rd_o <= '1;  // read
						mem_ctl_o.hlf <= '1;  // hlf
						mem_ctl_o.sgn <= '1;  // signed
						psh_o <= '1;  // push
					end
					op_mem_rhu : begin  // memory read hlf uns
						mem_rd_o <= '1;  // read
						mem_ctl_o.hlf <= '1;  // hlf
						psh_o <= '1;  // push
					end
					op_mem_rbs : begin  // memory read byte
						mem_rd_o <= '1;  // read
						mem_ctl_o.byt <= '1;  // byte
						mem_ctl_o.sgn <= '1;  // signed
						psh_o <= '1;  // push
					end
					op_mem_rbu : begin  // memory read byte uns
						mem_rd_o <= '1;  // read
						mem_ctl_o.byt <= '1;  // byte
						psh_o <= '1;  // push
					end
					op_lit : begin
						mem_ctl_o.lit <= '1;  // lit
						mem_rd_o <= '1;  // read
						psh_o <= '1;  // push
					end
					op_lit_hs : begin
						mem_ctl_o.lit <= '1;  // lit
						mem_rd_o <= '1;  // read
						mem_ctl_o.hlf <= '1;  // hlf
						mem_ctl_o.sgn <= '1;  // signed
						psh_o <= '1;  // push
					end
					op_lit_hu : begin
						mem_ctl_o.lit <= '1;  // lit
						mem_rd_o <= '1;  // read
						mem_ctl_o.hlf <= '1;  // hlf
						psh_o <= '1;  // push
					end
					op_lit_bs : begin
						mem_ctl_o.lit <= '1;  // lit
						mem_rd_o <= '1;  // read
						mem_ctl_o.byt <= '1;  // byte
						mem_ctl_o.sgn <= '1;  // signed
						psh_o <= '1;  // push
					end
					op_lit_bu : begin
						mem_ctl_o.lit <= '1;  // lit
						mem_rd_o <= '1;  // read
						mem_ctl_o.byt <= '1;  // byte
						psh_o <= '1;  // push
					end
					op_add_u : begin
						alu_ctl_o.as_op <= as_add_u;
						alu_ctl_o.as_sel <= '1;	// add/sub
						psh_o <= '1;  // push
					end
					op_add_us : begin
						alu_ctl_o.as_op <= as_add_us;
						alu_ctl_o.as_sel <= '1;	// add/sub
						psh_o <= '1;  // push
					end
					op_add_su : begin
						alu_ctl_o.as_op <= as_add_su;
						alu_ctl_o.as_sel <= '1;	// add/sub
						psh_o <= '1;  // push
					end
					op_add_s : begin
						alu_ctl_o.as_op <= as_add_s;
						alu_ctl_o.as_sel <= '1;	// add/sub
						psh_o <= '1;  // push
					end
					op_sub_u : begin
						alu_ctl_o.as_op <= as_sub_u;
						alu_ctl_o.as_sel <= '1;	// add/sub
						psh_o <= '1;  // push
					end
					op_sub_us : begin
						alu_ctl_o.as_op <= as_sub_us;
						alu_ctl_o.as_sel <= '1;	// add/sub
						psh_o <= '1;  // push
					end
					op_sub_su : begin
						alu_ctl_o.as_op <= as_sub_su;
						alu_ctl_o.as_sel <= '1;	// add/sub
						psh_o <= '1;  // push
					end
					op_sub_s : begin
						alu_ctl_o.as_op <= as_sub_s;
						alu_ctl_o.as_sel <= '1;	// add/sub
						psh_o <= '1;  // push
					end
					op_sbr_u : begin
						alu_ctl_o.as_op <= as_sbr_u;
						alu_ctl_o.as_sel <= '1;	// add/sub
						psh_o <= '1;  // push
					end
					op_sbr_us : begin
						alu_ctl_o.as_op <= as_sbr_us;
						alu_ctl_o.as_sel <= '1;	// add/sub
						psh_o <= '1;  // push
					end
					op_sbr_su : begin
						alu_ctl_o.as_op <= as_sbr_su;
						alu_ctl_o.as_sel <= '1;	// add/sub
						psh_o <= '1;  // push
					end
					op_sbr_s : begin
						alu_ctl_o.as_op <= as_sbr_s;
						alu_ctl_o.as_sel <= '1;	// add/sub
						psh_o <= '1;  // push
					end
					op_mul_u : begin
						alu_ctl_o.ms_op <= ms_mul_u;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						psh_o <= '1;  // push
					end
					op_mul_us : begin
						alu_ctl_o.ms_op <= ms_mul_us;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						psh_o <= '1;  // push
					end
					op_mul_su : begin
						alu_ctl_o.ms_op <= ms_mul_su;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						psh_o <= '1;  // push
					end
					op_mul_s : begin
						alu_ctl_o.ms_op <= ms_mul_s;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						psh_o <= '1;  // push
					end
					op_shl_u : begin
						alu_ctl_o.ms_op <= ms_shl_u;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						psh_o <= '1;  // push
					end
					op_shl_s : begin
						alu_ctl_o.ms_op <= ms_shl_s;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						psh_o <= '1;  // push
					end
					op_rol : begin
						alu_ctl_o.ms_op <= ms_rol;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						psh_o <= '1;  // push
					end
					op_pow : begin
						alu_ctl_o.ms_op <= ms_pow;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						psh_o <= '1;  // push
					end
					//
					op_reg_r : begin
						reg_rd_o <= '1;  // read
						psh_o <= '1;  // push
					end
					op_reg_w : begin
						reg_wr_o <= 'b1;  // write
					end
					//
					op_and : begin
						alu_ctl_o.lg_op <= lg_and;
						psh_o <= '1;  // push
					end
					op_orr : begin
						alu_ctl_o.lg_op <= lg_orr;
						psh_o <= '1;  // push
					end
					op_xor : begin
						alu_ctl_o.lg_op <= lg_xor;
						psh_o <= '1;  // push
					end
					// im8
					op_jmp_8z, op_jmp_8nz, op_jmp_8lz, op_jmp_8nlz, op_jmp_8o, op_jmp_8no, op_jmp_8e, op_jmp_8ne, op_jmp_8ls, op_jmp_8nls, op_jmp_8lu, op_jmp_8nlu : begin
						// legal op
					end
					op_jsb_8 : begin
						alu_ctl_o.pc_sel <= '1;  // psh pc
						psh_o <= '1;  // push
					end
					op_mem_8r : begin  // memory read
						mem_rd_o <= '1;  // read
						im_mem_o <= oc_im8;  // uns im
						psh_o <= '1;  // push
					end
					op_mem_8w : begin  // memory write
						mem_ctl_o.wr <= '1;  // write
						im_mem_o <= oc_im8;  // uns im
					end
					op_mem_8wh : begin  // memory write hlf
						mem_ctl_o.wr <= '1;  // write
						mem_ctl_o.hlf <= '1;  // hlf
						im_mem_o <= oc_im8;  // uns im
					end
					op_mem_8wb : begin  // memory write byte
						mem_ctl_o.wr <= '1;  // write
						mem_ctl_o.byt <= '1;  // byte
						im_mem_o <= oc_im8;  // uns im
					end
					op_mem_8rhs : begin  // memory read hlf
						mem_rd_o <= '1;  // read
						mem_ctl_o.hlf <= '1;  // hlf
						mem_ctl_o.sgn <= '1;  // signed
						im_mem_o <= oc_im8;  // uns im
						psh_o <= '1;  // push
					end
					op_mem_8rhu : begin  // memory read hlf uns
						mem_rd_o <= '1;  // read
						mem_ctl_o.hlf <= '1;  // hlf
						im_mem_o <= oc_im8;  // uns im
						psh_o <= '1;  // push
					end
					op_mem_8rbs : begin  // memory read byte
						mem_rd_o <= '1;  // read
						mem_ctl_o.byt <= '1;  // byte
						mem_ctl_o.sgn <= '1;  // signed
						im_mem_o <= oc_im8;  // uns im
						psh_o <= '1;  // push
					end
					op_mem_8rbu : begin  // memory read byte uns
						mem_rd_o <= '1;  // read
						mem_ctl_o.byt <= '1;  // byte
						im_mem_o <= oc_im8;  // uns im
						psh_o <= '1;  // push
					end
					op_mem_i8r : begin  // memory read
						mem_rd_o <= '1;  // read
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= $signed( oc_im8 );  // sgn im
						psh_o <= '1;  // push
					end
					op_mem_i8w : begin  // memory write
						mem_ctl_o.wr <= '1;  // write
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= $signed( oc_im8 );  // sgn im
					end
					op_mem_i8wh : begin  // memory write hlf
						mem_ctl_o.wr <= '1;  // write
						mem_ctl_o.hlf <= '1;  // hlf
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= $signed( oc_im8 );  // sgn im
					end
					op_mem_i8wb : begin  // memory write byte
						mem_ctl_o.wr <= '1;  // write
						mem_ctl_o.byt <= '1;  // byte
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= $signed( oc_im8 );  // sgn im
					end
					op_mem_i8rhs : begin  // memory read hlf
						mem_rd_o <= '1;  // read
						mem_ctl_o.hlf <= '1;  // hlf
						mem_ctl_o.sgn <= '1;  // signed
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= $signed( oc_im8 );  // sgn im
						psh_o <= '1;  // push
					end
					op_mem_i8rhu : begin  // memory read hlf uns
						mem_rd_o <= '1;  // read
						mem_ctl_o.hlf <= '1;  // hlf
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= $signed( oc_im8 );  // sgn im
						psh_o <= '1;  // push
					end
					op_mem_i8rbs : begin  // memory read byte
						mem_rd_o <= '1;  // read
						mem_ctl_o.byt <= '1;  // byte
						mem_ctl_o.sgn <= '1;  // signed
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= $signed( oc_im8 );  // sgn im
						psh_o <= '1;  // push
					end
					op_mem_i8rbu : begin  // memory read byte uns
						mem_rd_o <= '1;  // read
						mem_ctl_o.byt <= '1;  // byte
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= $signed( oc_im8 );  // sgn im
						psh_o <= '1;  // push
					end
					op_add_8u : begin
						alu_ctl_o.as_op <= as_add_u;
						alu_ctl_o.as_sel <= '1;	// add/sub
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_add_8us : begin
						alu_ctl_o.as_op <= as_add_us;
						alu_ctl_o.as_sel <= '1;	// add/sub
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_add_8su : begin
						alu_ctl_o.as_op <= as_add_su;
						alu_ctl_o.as_sel <= '1;	// add/sub
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_add_8s : begin
						alu_ctl_o.as_op <= as_add_s;
						alu_ctl_o.as_sel <= '1;	// add/sub
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sub_8u : begin
						alu_ctl_o.as_op <= as_sub_u;
						alu_ctl_o.as_sel <= '1;	// add/sub
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sub_8us : begin
						alu_ctl_o.as_op <= as_sub_us;
						alu_ctl_o.as_sel <= '1;	// add/sub
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sub_8su : begin
						alu_ctl_o.as_op <= as_sub_su;
						alu_ctl_o.as_sel <= '1;	// add/sub
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sub_8s : begin
						alu_ctl_o.as_op <= as_sub_s;
						alu_ctl_o.as_sel <= '1;	// add/sub
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sbr_8u : begin
						alu_ctl_o.as_op <= as_sbr_u;
						alu_ctl_o.as_sel <= '1;	// add/sub
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sbr_8us : begin
						alu_ctl_o.as_op <= as_sbr_us;
						alu_ctl_o.as_sel <= '1;	// add/sub
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sbr_8su : begin
						alu_ctl_o.as_op <= as_sbr_su;
						alu_ctl_o.as_sel <= '1;	// add/sub
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sbr_8s : begin
						alu_ctl_o.as_op <= as_sbr_s;
						alu_ctl_o.as_sel <= '1;	// add/sub
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_mul_8u : begin
						alu_ctl_o.ms_op <= ms_mul_u;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_mul_8us : begin
						alu_ctl_o.ms_op <= ms_mul_us;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_mul_8su : begin
						alu_ctl_o.ms_op <= ms_mul_su;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_mul_8s : begin
						alu_ctl_o.ms_op <= ms_mul_s;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_shl_8u : begin
						alu_ctl_o.ms_op <= ms_shl_u;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_shl_8s : begin
						alu_ctl_o.ms_op <= ms_shl_s;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_rol_8 : begin
						alu_ctl_o.ms_op <= ms_rol;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_pow_8 : begin
						alu_ctl_o.ms_op <= ms_pow;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					//
					op_reg_8r : begin
						reg_rd_o <= '1;  // read
						imda_o <= '1;  // immediate b data
						psh_o <= '1;  // push
					end
					op_reg_8w : begin
						reg_wr_o <= 'b1;  // write
						imda_o <= '1;  // immediate b data
					end
					//
					op_and_8 : begin
						alu_ctl_o.lg_op <= lg_and;
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_orr_8 : begin
						alu_ctl_o.lg_op <= lg_orr;
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_xor_8 : begin
						alu_ctl_o.lg_op <= lg_xor;
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					// im16
					op_jmp_16z, op_jmp_16nz, op_jmp_16lz, op_jmp_16nlz, op_jmp_16o, op_jmp_16no, op_jmp_16e, op_jmp_16ne, op_jmp_16ls, op_jmp_16nls, op_jmp_16lu, op_jmp_16nlu : begin
						// legal op
					end
					op_jsb_16 : begin
						alu_ctl_o.pc_sel <= '1;  // psh pc
						psh_o <= '1;  // push
					end
					op_mem_16r : begin  // memory read
						mem_rd_o <= '1;  // read
						im_mem_o <= PC_W'( oc_im16 );  // uns im
						psh_o <= '1;  // push
					end
					op_mem_16w : begin  // memory write
						mem_ctl_o.wr <= '1;  // write
						im_mem_o <= PC_W'( oc_im16 );  // uns im
					end
					op_mem_16wh : begin  // memory write hlf
						mem_ctl_o.wr <= '1;  // write
						mem_ctl_o.hlf <= '1;  // hlf
						im_mem_o <= PC_W'( oc_im16 );  // uns im
					end
					op_mem_16wb : begin  // memory write byte
						mem_ctl_o.wr <= '1;  // write
						mem_ctl_o.byt <= '1;  // byte
						im_mem_o <= PC_W'( oc_im16 );  // uns im
					end
					op_mem_16rhs : begin  // memory read hlf
						mem_rd_o <= '1;  // read
						mem_ctl_o.hlf <= '1;  // hlf
						mem_ctl_o.sgn <= '1;  // signed
						im_mem_o <= PC_W'( oc_im16 );  // uns im
						psh_o <= '1;  // push
					end
					op_mem_16rhu : begin  // memory read hlf uns
						mem_rd_o <= '1;  // read
						mem_ctl_o.hlf <= '1;  // hlf
						im_mem_o <= PC_W'( oc_im16 );  // uns im
						psh_o <= '1;  // push
					end
					op_mem_16rbs : begin  // memory read byte
						mem_rd_o <= '1;  // read
						mem_ctl_o.byt <= '1;  // byte
						mem_ctl_o.sgn <= '1;  // signed
						im_mem_o <= PC_W'( oc_im16 );  // uns im
						psh_o <= '1;  // push
					end
					op_mem_16rbu : begin  // memory read byte uns
						mem_rd_o <= '1;  // read
						mem_ctl_o.byt <= '1;  // byte
						im_mem_o <= PC_W'( oc_im16 );  // uns im
						psh_o <= '1;  // push
					end
					op_mem_i16r : begin  // memory read
						mem_rd_o <= '1;  // read
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= PC_W'( $signed( oc_im16 ) );  // sgn im
						psh_o <= '1;  // push
					end
					op_mem_i16w : begin  // memory write
						mem_ctl_o.wr <= '1;  // write
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= PC_W'( $signed( oc_im16 ) );  // sgn im
					end
					op_mem_i16wh : begin  // memory write hlf
						mem_ctl_o.wr <= '1;  // write
						mem_ctl_o.hlf <= '1;  // hlf
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= PC_W'( $signed( oc_im16 ) );  // sgn im
					end
					op_mem_i16wb : begin  // memory write byte
						mem_ctl_o.wr <= '1;  // write
						mem_ctl_o.byt <= '1;  // byte
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= PC_W'( $signed( oc_im16 ) );  // sgn im
					end
					op_mem_i16rhs : begin  // memory read hlf
						mem_rd_o <= '1;  // read
						mem_ctl_o.hlf <= '1;  // hlf
						mem_ctl_o.sgn <= '1;  // signed
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= PC_W'( $signed( oc_im16 ) );  // sgn im
						psh_o <= '1;  // push
					end
					op_mem_i16rhu : begin  // memory read hlf uns
						mem_rd_o <= '1;  // read
						mem_ctl_o.hlf <= '1;  // hlf
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= PC_W'( $signed( oc_im16 ) );  // sgn im
						psh_o <= '1;  // push
					end
					op_mem_i16rbs : begin  // memory read byte
						mem_rd_o <= '1;  // read
						mem_ctl_o.byt <= '1;  // byte
						mem_ctl_o.sgn <= '1;  // signed
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= PC_W'( $signed( oc_im16 ) );  // sgn im
						psh_o <= '1;  // push
					end
					op_mem_i16rbu : begin  // memory read byte uns
						mem_rd_o <= '1;  // read
						mem_ctl_o.byt <= '1;  // byte
						mem_ctl_o.lit <= '1;  // lit
						im_mem_o <= PC_W'( $signed( oc_im16 ) );  // sgn im
						psh_o <= '1;  // push
					end
					op_add_16u : begin
						alu_ctl_o.as_op <= as_add_u;
						alu_ctl_o.as_sel <= '1;	// add/sub
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_add_16us : begin
						alu_ctl_o.as_op <= as_add_us;
						alu_ctl_o.as_sel <= '1;	// add/sub
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_add_16su : begin
						alu_ctl_o.as_op <= as_add_su;
						alu_ctl_o.as_sel <= '1;	// add/sub
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_add_16s : begin
						alu_ctl_o.as_op <= as_add_s;
						alu_ctl_o.as_sel <= '1;	// add/sub
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sub_16u : begin
						alu_ctl_o.as_op <= as_sub_u;
						alu_ctl_o.as_sel <= '1;	// add/sub
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sub_16us : begin
						alu_ctl_o.as_op <= as_sub_us;
						alu_ctl_o.as_sel <= '1;	// add/sub
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sub_16su : begin
						alu_ctl_o.as_op <= as_sub_su;
						alu_ctl_o.as_sel <= '1;	// add/sub
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sub_16s : begin
						alu_ctl_o.as_op <= as_sub_s;
						alu_ctl_o.as_sel <= '1;	// add/sub
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sbr_16u : begin
						alu_ctl_o.as_op <= as_sbr_u;
						alu_ctl_o.as_sel <= '1;	// add/sub
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sbr_16us : begin
						alu_ctl_o.as_op <= as_sbr_us;
						alu_ctl_o.as_sel <= '1;	// add/sub
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sbr_16su : begin
						alu_ctl_o.as_op <= as_sbr_su;
						alu_ctl_o.as_sel <= '1;	// add/sub
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_sbr_16s : begin
						alu_ctl_o.as_op <= as_sbr_s;
						alu_ctl_o.as_sel <= '1;	// add/sub
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_mul_16u : begin
						alu_ctl_o.ms_op <= ms_mul_u;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_mul_16us : begin
						alu_ctl_o.ms_op <= ms_mul_us;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_mul_16su : begin
						alu_ctl_o.ms_op <= ms_mul_su;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_mul_16s : begin
						alu_ctl_o.ms_op <= ms_mul_s;
						alu_ctl_o.ms_sel <= '1;	// mult/shift
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					//
					op_and_16 : begin
						alu_ctl_o.lg_op <= lg_and;
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_orr_16 : begin
						alu_ctl_o.lg_op <= lg_orr;
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					op_xor_16 : begin
						alu_ctl_o.lg_op <= lg_xor;
						im_alu_o <= $signed( oc_im16 );  // oc_im16
						imda_o <= '1;  // im => b
						a_sel_o <= oc_sb;  // b => a
						psh_o <= '1;  // push
					end
					default : begin
						op_er_o <= '1;  // illegal op!
					end
				endcase
			end
		end
	end
	

endmodule
