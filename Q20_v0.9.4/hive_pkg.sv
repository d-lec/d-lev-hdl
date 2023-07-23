/*
--------------------------------------------------------------------------------

Module : hive_pkg.sv

--------------------------------------------------------------------------------

Function:
- Packages for hive processor

Instantiates: 
- Nothing.

Dependencies:
- None.

--------------------------------------------------------------------------------
*/
package hive_params;

	// version
	parameter CORE_VER				= 'h1312;	// core version

	// basic params (don't change)
	parameter THREADS					= 8;		// number of threads (=pipe stages)
	parameter STACKS					= 8;		// number of stacks per thread
	parameter ALU_W					= 32;		// alu width
	parameter LG_OP_W					= 4;		// logic op selector width
	parameter AS_OP_W					= 4;		// add/sub op selector width
	parameter MS_OP_W					= 4;		// mult/shift op selector width
	parameter TST_W					= 4;		// test field width
	parameter LEN_W					= 3;		// pc inc width
	parameter FLG_W					= 4;		// alu flags width

	// OK to change these
	parameter PC_W						= 14;		// pc width
	parameter RBUS_ADDR_W			= 4;		// register set address width
	parameter STK_PTR_W				= 5;		// stack pointer width
	parameter PROT_POP				= 1;		// 1=stacks pop error protection, 0=none
	parameter PROT_PSH				= 1;		// 1=stacks push error protection, 0=none
	parameter CORE_HZ					= 180000000;	// core clock rate (Hz)
	parameter SPDIF_HZ				= 196666667;	// SPDIF clock rate (Hz)
	parameter SYNC_W 					= 2;		// number of resync regs (1 or larger)
	parameter ENC_DEB_W 				= 16;		// encoder debounce counter width

	// derivations of basic params (don't change)
	parameter MEM_ADDR_W				= PC_W;
	parameter ZSX_W					= ALU_W+1;
	parameter ADD_W					= ALU_W+2;
	parameter DBL_W					= ALU_W<<1;
	parameter MUL_W					= DBL_W+1;
	parameter HLF_W					= ALU_W>>1;
	parameter BYT_W					= ALU_W>>2;
	parameter MEM_DEPTH				= 1<<MEM_ADDR_W;
	parameter THD_W					= $clog2(THREADS);
	parameter STK_W					= $clog2(STACKS);
	parameter SEL_W					= $clog2(ALU_W);
	parameter LZC_W					= SEL_W+1;
	parameter STK_LVL_W				= STK_PTR_W+1;	// stack level width

	// vector params (OK to change)
	parameter [PC_W-1:0] CLT_BASE = 'h0;				// thread clear address base (concat)
	parameter [PC_W-1:0] CLT_SPAN = 'h2;				// thread clear address span (2^n)
	parameter [PC_W-1:0] IRQ_BASE = 'h20;				// interrupt address base (concat)
	parameter [PC_W-1:0] IRQ_SPAN = 'h2;				// interrupt address span (2^n)
	parameter [THREADS-1:0] XSR_LIVE_MASK = '1;		// 1=enable input
	parameter [THREADS-1:0] XSR_SYNC_MASK = '1;		// 1=resync input
	parameter [THREADS-1:0] XSR_RISE_MASK = '1;		// 1=detect rising edge
	parameter [THREADS-1:0] XSR_FALL_MASK = 0;		// 1=detect falling edge

	// spi params
	parameter SPI_W						= 8;			// spi data width (bits)
	parameter SPI_PHASE_CLKS			= 9;			// spi high & low period clocks (1 min)

	// uart params
	parameter UART_W						= 8;			// uart data width (bits)
	parameter UART_BAUD_HZ				= 230400;	// uart baud rate (Hz)
	parameter UART_TX_STOP_BITS		= 1;			// number of tx stop bits
	parameter UART_TX_FIFO_ADDR_W		= 10;			// tx fifo address width (bits); 0=no fifo
	parameter UART_RX_FIFO_ADDR_W		= 0;			// rx fifo address width (bits); 0=no fifo

	// midi params
	parameter MIDI_W						= 8;			// midi data width (bits)
	parameter MIDI_BAUD_HZ				= 31250;		// midi baud rate (Hz)
	parameter MIDI_TX_STOP_BITS		= 1;			// number of tx stop bits
	parameter MIDI_TX_FIFO_ADDR_W		= 10;			// tx fifo address width (bits); 0=no fifo

	// spdif params
	parameter PCM_W						= 24;			// pcm data width (bits)
	parameter PRE_W						= 5;			// prescale clock divider width (bits)
	parameter TRI_W						= PRE_W+6;	// tri 48kHz width (bits)

	// lcd params
	parameter LCD_W						= 4;			// lcd data width (bits)
	parameter LCD_HZ						= 190000;	// lcd board clock rate (Hz)
	parameter LCD_FIFO_ADDR_W			= 10;			// lcd fifo address width (bits); 0=no fifo
	
	// DPLL params
	// pitch axis
	parameter	real	P_LC_FREQ		= 1300000;	// lc res. frequency (1mH)
	parameter	real	P_LC_Q			= 100;		// lc res. quality factor (loop BW)
	parameter			P_FREQ_W			= 25;			// nco freq width (loop BW)
	parameter			P_LSV				= 0;			// LSb's constant value, 0 to disable
	parameter			P_LPF_SHR		= 15;			// LPF right shift (corner freq)
	// volume axis
	parameter	real	V_LC_FREQ		= 900000;	// lc res. frequency (2mH)
	parameter	real	V_LC_Q			= 100;		// lc res. quality factor (loop BW)
	parameter			V_FREQ_W			= 25;			// nco freq width (loop BW)
	parameter			V_LSV				= 0;			// LSb's constant value, 0 to disable
	parameter			V_LPF_SHR		= 15;			// LPF right shift (corner freq)
	// common
	parameter			PV_RANGE_W		= 3;			// NCO range (lower limit)
	parameter			PV_D_SHL_W		= 3;			// dither left shift width (control bits)
	parameter			PV_LPF_ORDER	= 4;			// LPF order
	parameter			PV_IO_DDR		= 1;			// 1=use ddr at inputs & output; 0=no ddr	
	
endpackage



package hive_defines;

	// encode register set addresses
	`define RBUS_VECT		4'h0 
	`define RBUS_TIME		4'h1
	`define RBUS_ERROR	4'h2
	`define RBUS_GPIO		4'h3
	`define RBUS_UART_TX	4'h4
	`define RBUS_UART_RX	4'h5
	`define RBUS_SPI		4'h6
	`define RBUS_SPDIF	4'h8
	`define RBUS_MIDI		4'h9
	`define RBUS_PITCH	4'ha
	`define RBUS_VOLUME	4'hb
	`define RBUS_TUNER	4'hc
	`define RBUS_LCD		4'hd
	`define RBUS_ENC		4'he


	// lg alias values
	`define lg_cpy			4'h0
	`define lg_nsb			4'h1
	`define lg_lim			4'h2
	`define lg_sat			4'h3
	`define lg_flp			4'h4
	`define lg_swp			4'h5
	`define lg_not			4'h6
	`define lg_brx			4'h8
	`define lg_sgn			4'h9
	`define lg_lzc			4'ha
	`define lg_and			4'hc
	`define lg_orr			4'hd
	`define lg_xor			4'he


	// as alias values
	`define as_add_u		4'h0
	`define as_add_us		4'h1
	`define as_add_su		4'h2
	`define as_add_s		4'h3
	`define as_sub_u		4'h4
	`define as_sub_us		4'h5
	`define as_sub_su		4'h6
	`define as_sub_s		4'h7
	`define as_sbr_u		4'h8
	`define as_sbr_us		4'h9
	`define as_sbr_su		4'ha
	`define as_sbr_s		4'hb


	// ms alias values
	`define ms_mul_u		4'h0
	`define ms_mul_us		4'h1
	`define ms_mul_su		4'h2
	`define ms_mul_s		4'h3
	`define ms_shl_u		4'h4
	`define ms_shl_s		4'h5
	`define ms_rol			4'h6
	`define ms_pow			4'h7


	// test alias values
	`define tst_z			4'h0
	`define tst_nz			4'h1
	`define tst_lz			4'h2
	`define tst_nlz		4'h3
	`define tst_o			4'h4
	`define tst_no			4'h5
	`define tst_e			4'h6
	`define tst_ne			4'h7
	`define tst_ls			4'h8
	`define tst_nls		4'h9
	`define tst_lu			4'ha
	`define tst_nlu		4'hb

endpackage



package hive_types;

	// we need these
	import hive_defines::*;
	import hive_params::*;

	
	// thread ID type
	typedef logic [THD_W-1:0] ID_T[THREADS];

	
	// program counter type
	typedef logic [PC_W-1:0] PC_T[THREADS];


	// enumerated test select type
	typedef enum logic [TST_W-1:0] 
		{
		tst_z		= `tst_z,
		tst_nz	= `tst_nz,
		tst_lz	= `tst_lz,
		tst_nlz	= `tst_nlz,
		tst_o		= `tst_o,
		tst_no	= `tst_no,
		tst_e		= `tst_e,
		tst_ne	= `tst_ne,
		tst_ls	= `tst_ls,
		tst_nls	= `tst_nls,
		tst_lu	= `tst_lu,
		tst_nlu	= `tst_nlu
		} TST_T;


	// enumerated logical select type
	typedef enum logic [LG_OP_W-1:0] 
		{
		lg_cpy	= `lg_cpy,
		lg_nsb	= `lg_nsb,
		lg_lim	= `lg_lim,
		lg_sat	= `lg_sat,
		lg_flp	= `lg_flp,
		lg_swp	= `lg_swp,
		lg_not	= `lg_not,
		lg_brx	= `lg_brx,
		lg_sgn	= `lg_sgn,
		lg_lzc	= `lg_lzc,
		lg_and	= `lg_and,
		lg_orr	= `lg_orr,
		lg_xor	= `lg_xor
		} LG_OP_T;


	// enumerated add/sub function select type
	typedef enum logic [AS_OP_W-1:0] 
		{
		as_add_u		= `as_add_u,
		as_add_us	= `as_add_us,
		as_add_su	= `as_add_su,
		as_add_s		= `as_add_s,
		as_sub_u		= `as_sub_u,
		as_sub_us	= `as_sub_us,
		as_sub_su	= `as_sub_su,
		as_sub_s		= `as_sub_s,
		as_sbr_u		= `as_sbr_u,
		as_sbr_us	= `as_sbr_us,
		as_sbr_su	= `as_sbr_su,
		as_sbr_s		= `as_sbr_s
		} AS_OP_T;


	// enumerated mult/shift function select type
	typedef enum logic [MS_OP_W-1:0] 
		{
		ms_mul_u		= `ms_mul_u,
		ms_mul_us	= `ms_mul_us,
		ms_mul_su	= `ms_mul_su,
		ms_mul_s		= `ms_mul_s,
		ms_shl_u		= `ms_shl_u,
		ms_shl_s		= `ms_shl_s,
		ms_rol		= `ms_rol,
		ms_pow		= `ms_pow
		} MS_OP_T;


	// alu control type
	typedef struct
		{
		logic 	as_sel;
		logic 	ms_sel;
		logic 	pc_sel;
		logic 	ext;
		LG_OP_T	lg_op;
		AS_OP_T	as_op;
		MS_OP_T	ms_op;
		} ALU_CTL_T;


	// mem control type
	typedef struct
		{
		logic	lit;
		logic	byt;
		logic	hlf;
		logic	sgn;
		logic	wr;
		} MEM_CTL_T;


	// enumerated opcode type
	typedef enum logic [BYT_W-1:0] 
		{
		op_nop			= 8'h00,
		op_hlt			= 8'h01,
		//
		op_pop			= 8'h04,
		op_cls			= 8'h05,
		//
		op_jmp_8			= 8'h08,
		op_jmp_16		= 8'h09,
		op_jmp_24		= 8'h0a,
		//
		op_add_xu		= 8'h20 + `as_add_u,
		op_add_xus		= 8'h20 + `as_add_us,
		op_add_xsu		= 8'h20 + `as_add_su,
		op_add_xs		= 8'h20 + `as_add_s,
		op_sub_xu		= 8'h20 + `as_sub_u,
		op_sub_xus		= 8'h20 + `as_sub_us,
		op_sub_xsu		= 8'h20 + `as_sub_su,
		op_sub_xs		= 8'h20 + `as_sub_s,
		op_sbr_xu		= 8'h20 + `as_sbr_u,
		op_sbr_xus		= 8'h20 + `as_sbr_us,
		op_sbr_xsu		= 8'h20 + `as_sbr_su,
		op_sbr_xs		= 8'h20 + `as_sbr_s,
		op_mul_xu		= 8'h2c + `ms_mul_u,
		op_mul_xus		= 8'h2c + `ms_mul_us,
		op_mul_xsu		= 8'h2c + `ms_mul_su,
		op_mul_xs		= 8'h2c + `ms_mul_s,
		//
		op_cpy			= 8'h30 + `lg_cpy,
		op_nsb			= 8'h30 + `lg_nsb,
		op_lim			= 8'h30 + `lg_lim,
		op_sat			= 8'h30 + `lg_sat,
		op_flp			= 8'h30 + `lg_flp,
		op_swp			= 8'h30 + `lg_swp,
		op_not			= 8'h30 + `lg_not,
		op_brx			= 8'h30 + `lg_brx,
		op_sgn			= 8'h30 + `lg_sgn,
		op_lzc			= 8'h30 + `lg_lzc,
		//
		op_jmp_z			= 8'h40 + `tst_z,
		op_jmp_nz		= 8'h40 + `tst_nz,
		op_jmp_lz		= 8'h40 + `tst_lz,
		op_jmp_nlz		= 8'h40 + `tst_nlz,
		op_jsb			= 8'h48,
		op_jmp			= 8'h49,
		op_gsb			= 8'h4a,
		op_gto			= 8'h4b,
		op_irt			= 8'h4c,
		op_pcr			= 8'h4e,
		//
		op_mem_r			= 8'h50,
		op_mem_w			= 8'h51,
		op_mem_wh		= 8'h52,
		op_mem_wb		= 8'h53,
		op_mem_rhs		= 8'h54,
		op_mem_rhu		= 8'h55,
		op_mem_rbs		= 8'h56,
		op_mem_rbu		= 8'h57,
		op_lit			= 8'h58,
		op_lit_hs		= 8'h5c,
		op_lit_hu		= 8'h5d,
		op_lit_bs		= 8'h5e,
		op_lit_bu		= 8'h5f,
		//
		op_add_u			= 8'h60 + `as_add_u,
		op_add_us		= 8'h60 + `as_add_us,
		op_add_su		= 8'h60 + `as_add_su,
		op_add_s			= 8'h60 + `as_add_s,
		op_sub_u			= 8'h60 + `as_sub_u,
		op_sub_us		= 8'h60 + `as_sub_us,
		op_sub_su		= 8'h60 + `as_sub_su,
		op_sub_s			= 8'h60 + `as_sub_s,
		op_sbr_u			= 8'h60 + `as_sbr_u,
		op_sbr_us		= 8'h60 + `as_sbr_us,
		op_sbr_su		= 8'h60 + `as_sbr_su,
		op_sbr_s			= 8'h60 + `as_sbr_s,
		op_mul_u			= 8'h6c + `ms_mul_u,
		op_mul_us		= 8'h6c + `ms_mul_us,
		op_mul_su		= 8'h6c + `ms_mul_su,
		op_mul_s			= 8'h6c + `ms_mul_s,
		//
		op_shl_u			= 8'h6c + `ms_shl_u,
		op_shl_s			= 8'h6c + `ms_shl_s,
		op_rol			= 8'h6c + `ms_rol,
		op_pow			= 8'h6c + `ms_pow,
		op_reg_r			= 8'h78,
		op_reg_w			= 8'h79,
		op_and			= 8'h70 + `lg_and,
		op_orr			= 8'h70 + `lg_orr,
		op_xor			= 8'h70 + `lg_xor,
		//
		op_jmp_8z		= 8'h80 + `tst_z,
		op_jmp_8nz		= 8'h80 + `tst_nz,
		op_jmp_8lz		= 8'h80 + `tst_lz,
		op_jmp_8nlz		= 8'h80 + `tst_nlz,
		op_jmp_8o		= 8'h80 + `tst_o,
		op_jmp_8no		= 8'h80 + `tst_no,
		op_jmp_8e		= 8'h80 + `tst_e,
		op_jmp_8ne		= 8'h80 + `tst_ne,
		op_jmp_8ls		= 8'h80 + `tst_ls,
		op_jmp_8nls		= 8'h80 + `tst_nls,
		op_jmp_8lu		= 8'h80 + `tst_lu,
		op_jmp_8nlu		= 8'h80 + `tst_nlu,
		op_jsb_8			= 8'h8c,
		//
		op_mem_8r		= 8'h90,
		op_mem_8w		= 8'h91,
		op_mem_8wh		= 8'h92,
		op_mem_8wb		= 8'h93,
		op_mem_8rhs		= 8'h94,
		op_mem_8rhu		= 8'h95,
		op_mem_8rbs		= 8'h96,
		op_mem_8rbu		= 8'h97,
		op_mem_i8r		= 8'h98,
		op_mem_i8w		= 8'h99,
		op_mem_i8wh		= 8'h9a,
		op_mem_i8wb		= 8'h9b,
		op_mem_i8rhs	= 8'h9c,
		op_mem_i8rhu	= 8'h9d,
		op_mem_i8rbs	= 8'h9e,
		op_mem_i8rbu	= 8'h9f,
		//
		op_add_8u		= 8'ha0 + `as_add_u,
		op_add_8us		= 8'ha0 + `as_add_us,
		op_add_8su		= 8'ha0 + `as_add_su,
		op_add_8s		= 8'ha0 + `as_add_s,
		op_sub_8u		= 8'ha0 + `as_sub_u,
		op_sub_8us		= 8'ha0 + `as_sub_us,
		op_sub_8su		= 8'ha0 + `as_sub_su,
		op_sub_8s		= 8'ha0 + `as_sub_s,
		op_sbr_8u		= 8'ha0 + `as_sbr_u,
		op_sbr_8us		= 8'ha0 + `as_sbr_us,
		op_sbr_8su		= 8'ha0 + `as_sbr_su,
		op_sbr_8s		= 8'ha0 + `as_sbr_s,
		op_mul_8u		= 8'hac + `ms_mul_u,
		op_mul_8us		= 8'hac + `ms_mul_us,
		op_mul_8su		= 8'hac + `ms_mul_su,
		op_mul_8s		= 8'hac + `ms_mul_s,
		//
		op_shl_8u		= 8'hac + `ms_shl_u,
		op_shl_8s		= 8'hac + `ms_shl_s,
		op_rol_8			= 8'hac + `ms_rol,
		op_pow_8			= 8'hac + `ms_pow,
		op_reg_8r		= 8'hb8,
		op_reg_8w		= 8'hb9,
		op_and_8			= 8'hb0 + `lg_and,
		op_orr_8			= 8'hb0 + `lg_orr,
		op_xor_8			= 8'hb0 + `lg_xor,
		//
		op_jmp_16z		= 8'hc0 + `tst_z,
		op_jmp_16nz		= 8'hc0 + `tst_nz,
		op_jmp_16lz		= 8'hc0 + `tst_lz,
		op_jmp_16nlz	= 8'hc0 + `tst_nlz,
		op_jmp_16o		= 8'hc0 + `tst_o,
		op_jmp_16no		= 8'hc0 + `tst_no,
		op_jmp_16e		= 8'hc0 + `tst_e,
		op_jmp_16ne		= 8'hc0 + `tst_ne,
		op_jmp_16ls		= 8'hc0 + `tst_ls,
		op_jmp_16nls	= 8'hc0 + `tst_nls,
		op_jmp_16lu		= 8'hc0 + `tst_lu,
		op_jmp_16nlu	= 8'hc0 + `tst_nlu,
		op_jsb_16		= 8'hcc,
		//
		op_mem_16r		= 8'hd0,
		op_mem_16w		= 8'hd1,
		op_mem_16wh		= 8'hd2,
		op_mem_16wb		= 8'hd3,
		op_mem_16rhs	= 8'hd4,
		op_mem_16rhu	= 8'hd5,
		op_mem_16rbs	= 8'hd6,
		op_mem_16rbu	= 8'hd7,
		op_mem_i16r		= 8'hd8,
		op_mem_i16w		= 8'hd9,
		op_mem_i16wh	= 8'hda,
		op_mem_i16wb	= 8'hdb,
		op_mem_i16rhs	= 8'hdc,
		op_mem_i16rhu	= 8'hdd,
		op_mem_i16rbs	= 8'hde,
		op_mem_i16rbu	= 8'hdf,
		//
		op_add_16u		= 8'he0 + `as_add_u,
		op_add_16us		= 8'he0 + `as_add_us,
		op_add_16su		= 8'he0 + `as_add_su,
		op_add_16s		= 8'he0 + `as_add_s,
		op_sub_16u		= 8'he0 + `as_sub_u,
		op_sub_16us		= 8'he0 + `as_sub_us,
		op_sub_16su		= 8'he0 + `as_sub_su,
		op_sub_16s		= 8'he0 + `as_sub_s,
		op_sbr_16u		= 8'he0 + `as_sbr_u,
		op_sbr_16us		= 8'he0 + `as_sbr_us,
		op_sbr_16su		= 8'he0 + `as_sbr_su,
		op_sbr_16s		= 8'he0 + `as_sbr_s,
		op_mul_16u		= 8'hec + `ms_mul_u,
		op_mul_16us		= 8'hec + `ms_mul_us,
		op_mul_16su		= 8'hec + `ms_mul_su,
		op_mul_16s		= 8'hec + `ms_mul_s,
		//
		op_and_16		= 8'hf0 + `lg_and,
		op_orr_16		= 8'hf0 + `lg_orr,
		op_xor_16		= 8'hf0 + `lg_xor
		} OC_T;

endpackage



package hive_rst_vals;

	// we need these
	import hive_params::*;
	import hive_types::*;

	// ID reset values
	parameter ID_T ID_RST = '{ 1, 0, 7, 6, 5, 4, 3, 2 };

endpackage



package hive_funcs;

	// we need these
	import hive_params::*;

	// return leading zero count of input value
	function automatic logic [LZC_W-1:0] lzc;
	input logic [ALU_W-1:0] in;
	integer i;
		begin
			lzc = (LZC_W)'(ALU_W);
			// priority encoder (find MSB 1 position)
			for (i = 0; i < ALU_W; i = i + 1) begin 
				if (in[i]) begin
					lzc = LZC_W'( ALU_W - 1 - i );
				end
			end
		end
	endfunction

	// flip input vector end for end (LSb => MSb, etc.)
	function automatic logic [ALU_W-1:0] flip;
	input logic [ALU_W-1:0] in;
	integer i;
		begin
			for (i = 0; i < ALU_W; i = i + 1) begin
				flip[i] = in[ALU_W-1-i];
			end
		end
	endfunction


endpackage
