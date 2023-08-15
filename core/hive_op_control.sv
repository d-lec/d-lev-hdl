/*
--------------------------------------------------------------------------------

Module : hive_op_control.sv

--------------------------------------------------------------------------------

Function:
- Opcode decoder for hive processor control ring.

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

module hive_op_control
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// state I/O
	input			logic								clt_i,						// clear thread, active high
	output		logic								clt_o,						// clear thread
	input			logic								irq_i,						// irq, active high
	output		logic								irq_o,						// irq, active high
	output		logic								irt_o,						// irq return, active high
	input			logic	[ALU_W-1:0]				oc_i,							// opcode
	// data I/O
	output		logic	[PC_W-1:0]				im_pc_o,						// pc immediate
	// pc pipe control
	output		logic								cnd_o,						// 1 = conditional
	output		logic								jmp_o,						// 1 = pc=pc+B|I for jump (cond)
	output		logic								gto_o,						// 1 = pc=B for goto / gosub / irt
	output		logic	[LEN_W-1:0]				len_o,						// pc inc val
	// conditional masks
	output		TST_T								tst_o,						// test field
	// immediate flags
	output		logic								imad_o						// 1=immediate address
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
	TST_T												oc_tst_2, oc_tst_4;
	logic					[PC_W-1:0]				oc_im8_lo, oc_im16_lo, oc_im24_lo;
	logic					[BYT_W-1:0]				oc_im8;
	logic					[HLF_W-1:0]				oc_im16;



	/*
	================
	== code start ==
	================
	*/


	// split out opcode fields
	always_comb	oc = OC_T'(oc_i[7:0]);
	always_comb	oc_im8_lo = $signed( oc_i[15:8] );
	always_comb	oc_im16_lo = PC_W'( $signed( oc_i[23:8] ) );
	always_comb	oc_im24_lo = PC_W'( $signed( oc_i[31:8] ) );
	always_comb	oc_im8 = oc_i[23:16];
	always_comb	oc_im16 = oc_i[31:16];
	always_comb	oc_tst_2 = TST_T'(oc_i[1:0]);
	always_comb	oc_tst_4 = TST_T'(oc_i[3:0]);


	// register if & case: clear, interrupt, and opcode decode
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			clt_o <= 0;
			irq_o <= 0;
			irt_o <= 0;
			jmp_o <= 0;
			gto_o <= 0;
			len_o <= 0;
			tst_o <= TST_T'( 'x );
			cnd_o <= 0;
			imad_o <= 0;
			im_pc_o <= 'x;
		end else begin
			// clocked default values
			clt_o <= 0;  // default is no pc clear
			irq_o <= 0;  // default is no int
			irt_o <= 0;  // default is no irq_i return
			jmp_o <= 0;  // default is no jump
			gto_o <= 0;  // default is no goto
			len_o <= 'd2;  // default length is 2 bytes
			tst_o <= TST_T'( 'x );  // default is don't care
			cnd_o <= 0;  // default is unconditional
			imad_o <= 0;  // default is not immediate address
			im_pc_o <= 'x;  // default is don't care
			if ( clt_i ) begin  // clear thread
				clt_o <= '1;  // clear pc
			end else if ( irq_i ) begin  // interrupt thread
				irq_o <= '1;  // issue irq
				len_o <= 0;  // zero length
			end else begin
				// examine upper byte
				unique casex ( oc )
					op_nop : begin
						len_o <= 'd1;  // length 1 bytes
					end
					op_hlt : begin
						len_o <= 0;  // length 0 bytes
					end
					op_jmp_8 : begin
						jmp_o <= '1;  // jump
						imad_o <= '1;  // immediate address
						im_pc_o <= oc_im8_lo;
					end
					op_jmp_16 : begin
						jmp_o <= '1;  // jump
						imad_o <= '1;  // immediate address
						im_pc_o <= oc_im16_lo;
						len_o <= 'd3;  // length 3 bytes
					end
					op_jmp_24 : begin
						jmp_o <= '1;  // jump
						imad_o <= '1;  // immediate address
						im_pc_o <= oc_im24_lo;
						len_o <= 'd4;  // length 4 bytes
					end
					op_jmp_z, op_jmp_nz, op_jmp_lz, op_jmp_nlz : begin
						jmp_o <= '1;  // jump
						cnd_o <= '1;  // conditional
						tst_o <= oc_tst_2;  // zero test field
					end
					op_jmp, op_jsb : begin
						jmp_o <= '1;  // jump
					end
					op_gto : begin
						gto_o <= '1;  // goto
					end
					op_irt : begin
						gto_o <= '1;  // goto
						irt_o <= '1;  // irq return
					end
					op_gsb : begin
						gto_o <= '1;  // goto
					end
					// im8
					op_jmp_8z, op_jmp_8nz, op_jmp_8lz, op_jmp_8nlz, op_jmp_8o, op_jmp_8no, op_jmp_8e, op_jmp_8ne, op_jmp_8ls, op_jmp_8nls, op_jmp_8lu, op_jmp_8nlu : begin
						imad_o <= '1;  // immediate address
						im_pc_o <= $signed( oc_im8 );
						jmp_o <= '1;  // jump
						cnd_o <= '1;  // conditional
						tst_o <= oc_tst_4;  // full test field
						len_o <= 'd3;  // length 3 bytes
					end
					op_jsb_8 : begin
						imad_o <= '1;  // immediate address
						im_pc_o <= $signed( oc_im8 );
						jmp_o <= '1;  // jump
						len_o <= 'd3;  // length 3 bytes
					end
					op_mem_8r, op_mem_8w, op_mem_8wh, op_mem_8wb, op_mem_8rhs, op_mem_8rhu, op_mem_8rbs, op_mem_8rbu : begin
						len_o <= 'd3;  // length 3 bytes
					end
					op_mem_i8r, op_mem_i8w, op_mem_i8wh, op_mem_i8wb, op_mem_i8rhs, op_mem_i8rhu, op_mem_i8rbs, op_mem_i8rbu : begin
						len_o <= 'd3;  // length 3 bytes
					end
					op_lit : begin
						imad_o <= '1;  // immediate address
						im_pc_o <= 'd4;  // jump 4
						jmp_o <= '1;
					end
					op_lit_hs, op_lit_hu : begin
						imad_o <= '1;  // immediate address
						im_pc_o <= 'd2;  // jump 2
						jmp_o <= '1;
					end
					op_lit_bs, op_lit_bu : begin
						imad_o <= '1;  // immediate address
						im_pc_o <= 'd1;  // jump 1
						jmp_o <= '1;
					end
					op_add_8u, op_add_8us, op_add_8su, op_add_8s : begin
						len_o <= 'd3;  // length 3 bytes
					end
					op_sub_8u, op_sub_8us, op_sub_8su, op_sub_8s : begin
						len_o <= 'd3;  // length 3 bytes
					end
					op_sbr_8u, op_sbr_8us, op_sbr_8su, op_sbr_8s : begin
						len_o <= 'd3;  // length 3 bytes
					end
					op_mul_8u, op_mul_8us, op_mul_8su, op_mul_8s : begin
						len_o <= 'd3;  // length 3 bytes
					end
					op_shl_8u, op_shl_8s, op_rol_8, op_pow_8 : begin
						len_o <= 'd3;  // length 3 bytes
					end
					op_reg_8r, op_reg_8w : begin
						len_o <= 'd3;  // length 3 bytes
					end
					op_and_8, op_orr_8, op_xor_8 : begin
						len_o <= 'd3;  // length 3 bytes
					end
					// im16
					op_jmp_16z, op_jmp_16nz, op_jmp_16lz, op_jmp_16nlz, op_jmp_16o, op_jmp_16no, op_jmp_16e, op_jmp_16ne, op_jmp_16ls, op_jmp_16nls, op_jmp_16lu, op_jmp_16nlu : begin
						imad_o <= '1;  // immediate address
						im_pc_o <= PC_W'( $signed( oc_im16 ) );  // mem inline
						jmp_o <= '1;  // jump
						cnd_o <= '1;  // conditional
						tst_o <= oc_tst_4;  // full test field
						len_o <= 'd4;  // length 4 bytes
					end
					op_jsb_16 : begin
						imad_o <= '1;  // immediate address
						im_pc_o <= PC_W'( $signed( oc_im16 ) );  // mem inline
						jmp_o <= '1;  // jump
						len_o <= 'd4;  // length 3 bytes
					end
					op_mem_16r, op_mem_16w, op_mem_16wh, op_mem_16wb, op_mem_16rhs, op_mem_16rhu, op_mem_16rbs, op_mem_16rbu : begin  // memory read & write
						len_o <= 'd4;  // length 4 bytes
					end
					op_mem_i16r, op_mem_i16w, op_mem_i16wh, op_mem_i16wb, op_mem_i16rhs, op_mem_i16rhu, op_mem_i16rbs, op_mem_i16rbu : begin  // memory read & write
						len_o <= 'd4;  // length 4 bytes
					end
					op_add_16u, op_add_16us, op_add_16su, op_add_16s : begin
						len_o <= 'd4;  // length 4 bytes
					end
					op_sub_16u, op_sub_16us, op_sub_16su, op_sub_16s : begin
						len_o <= 'd4;  // length 4 bytes
					end
					op_sbr_16u, op_sbr_16us, op_sbr_16su, op_sbr_16s : begin
						len_o <= 'd4;  // length 4 bytes
					end
					op_mul_16u, op_mul_16us, op_mul_16su, op_mul_16s : begin
						len_o <= 'd4;  // length 4 bytes
					end
					op_and_16, op_orr_16, op_xor_16 : begin
						len_o <= 'd4;  // length 4 bytes
					end
					default begin 
						// to complete case
					end
				endcase
			end
		end
	end
	

endmodule
