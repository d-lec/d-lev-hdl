/*
--------------------------------------------------------------------------------

Module: lc_dpll

Function: 
- Forms an LC tank based digital phase locked loop.

Instantiates:
- (1x) pd_int.sv
  - (2x) ddr_in_altera.sv (if IO_DDR=1)
- (1x) nco.sv
  - (1x) tri_gen.sv
  - (1x) ddr_out_altera.sv (if IO_DDR=1)
- (1x) lpf
- (1x) lpf_multi
  - (4x) lpf
- (1x) ltch

Notes:
- Not a full PLL because LC transfer function is always frequency locked.
- Phase error is XOR detected, integrated, attenuated, and fed back.
- Proportional phase error is not used (unnecessary and causes trouble).
- Use "nco_2016-10-08.xls" & "fast_iir_2012-12-20.xls" as design aids.
- See individual components for more details.

--------------------------------------------------------------------------------
*/

module lc_dpll
	#(
	// input params - ok to change
	parameter	real								CLK_FREQ			= 196666667,	// clock frequency
	parameter	real								LC_FREQ			= 2600000,	// lc res. frequency
	parameter	real								LC_Q				= 200,	// lc res. quality factor
	parameter										DATA_W			= 32,	// output data width
	parameter										FREQ_W			= 25,	// sets bandwidth
	parameter										RANGE_W			= 4,	// sets range (low limit)
	parameter										D_SHL_W			= 3,	// dither left shift width (bits)
	parameter										LSV				= 1,	// LSb's constant value, 0 to disable
	parameter										LPF_SHR			= 14,	// LPF right shift (sets cutoff freq)
	parameter										LPF_ORDER		= 4,	// LPF filter order
	parameter										SYNC_W			= 2,	// resync registers, 1 min (if IO_DDR=0)
	parameter										IO_DDR			= 1,	// 1=use ddr at inputs & output; 0=no ddr
	parameter										TRI_W				= 11,	// tri width (bits)
	// const & derrived params - don't change!
	parameter										D_SHL				= FREQ_W - TRI_W - 2**D_SHL_W - 3,  // dither left shift (bits)
	parameter	real								PD_GAIN			= 4,	// phase detector gain
	parameter										LPF_USR			= 2,	// LPF undersampling ratio
	parameter	real								CYCLE_CLKS		= CLK_FREQ/LC_FREQ,	// system clocks per LC cycle
	parameter										NCO_W				= $clog2(int'(CYCLE_CLKS+0.5))+FREQ_W-1,	// NCO accum width (MSB=clk_o)
	parameter	real								NCO_W_R			= NCO_W,  // real version
	parameter	real								NCO_MOD			= 2**NCO_W_R,  // nco modulo
	parameter										FREQ_SHL			= DATA_W-FREQ_W,	// left shift into lpf
	parameter	real								FREQ_NOM			= int'(NCO_MOD/CYCLE_CLKS),
	parameter	real								LC_FREQ_NOM		= FREQ_NOM*CLK_FREQ/NCO_MOD,
	parameter	real								LC_FREQ_INC		= (FREQ_NOM+1)*CLK_FREQ/NCO_MOD,
	parameter	real								NCO_GAIN			= ((1/LC_FREQ_NOM)-(1/LC_FREQ_INC))*CLK_FREQ,	// NCO gain
	parameter	real								LC_Q_GAIN		= LC_Q/3.1416,	// LC Q gain
	parameter	real								LOOP_GAIN		= PD_GAIN*NCO_GAIN*LC_Q_GAIN,  // loop gain
	parameter	real								PRE_ATTEN		= 2**FREQ_SHL,
	parameter	real								LPF_ATTEN		= 2**LPF_SHR,
	parameter	real								LPF_ORDER_R		= LPF_ORDER,	// real version
	parameter	real								ORDER_GAIN		= (2**(1/LPF_ORDER_R)-1)**0.5,
	// FYI
	parameter	real								FMAX_DIV			= 2**(NCO_W-FREQ_W),
	parameter	real								LC_FMAX			= CLK_FREQ/FMAX_DIV,	// max dpll frequency (Hz)
	parameter	real								LOOP_BW			= LOOP_GAIN*LC_FREQ/(2*3.1416),  // loop bandwidth (Hz)
	parameter	real								PRE_BW			= CLK_FREQ/PRE_ATTEN/(2*3.1416),  // pre bandwidth (Hz)
	parameter	real								LPF_BW			= ORDER_GAIN*CLK_FREQ/LPF_ATTEN/(2*3.1416)/LPF_USR  // lpf bandwidth (Hz)
	)
	(
	// clocks & resets
	input		logic									clk_i,					// clock
	input		logic									rst_i,					// async. reset, active hi
	// logic interface
	input		logic		[TRI_W-1:0]				tri_i,					// triangle in (sgn)
	input		logic		[D_SHL_W-1:0]			d_shl_i,					// dither left shift (gain)
	input		logic									lpf_ltch_i,				// lpf latch in
	input		logic									lpf_en_i,				// lpf enable, active high
	output	logic		[DATA_W-1:0]			lpf_o,					// low pass filtered frequency output
	// LC interface
	output	logic									sq_o,						// square output
	input		logic									zero_i,					// zero async input
	input		logic									quad_i					// quad async input
	);

	/*
	----------------------
	-- internal signals --
	----------------------
	*/	
	//
	logic		[FREQ_W-1:0]						freq;
	logic		[DATA_W-1:0]						freq_pre, freq_lpf;

	
	/*
	================
	== code start ==
	================
	*/

	// phase detect & accum
	pdi_zq
	#(
	.FREQ_W				( FREQ_W ),
	.RANGE_W				( RANGE_W ),
	.SYNC_W				( SYNC_W ),
	.I_DDR				( IO_DDR )
	)
	pdi_zq
	(
	.*,
	.freq_o				( freq )
	);

	
	// nco
	nco
	#(
	.NCO_W				( NCO_W ),
	.FREQ_W				( FREQ_W ),
	.TRI_W				( TRI_W ),
	.D_SHL_W				( D_SHL_W ),
	.D_SHL				( D_SHL ),
	.LSV					( LSV ),
	.O_DDR				( IO_DDR )
	)
	nco
	(
	.*,
	.freq_i				( freq )
	);


	// freq pre lpf
	lpf
	#(
	.DATA_W			( DATA_W ),
	.SHR				( FREQ_SHL )
	)
	lpf
	(
	.*,
	.en_i				( '1 ),
	.data_i			( freq << FREQ_SHL ),
	.lp_o				( freq_pre )
	);

	
	// freq lpf
	lpf_multi
	#(
	.DATA_W			( DATA_W ),
	.SHR				( LPF_SHR ),
	.ORDER			( LPF_ORDER )
	)
	lpf_multi
	(
	.*,
	.en_i				( lpf_en_i ),
	.data_i			( freq_pre ),
	.lp_o				( freq_lpf )
	);


	// data latch
	ltch
	#(
	.DATA_W			( DATA_W )
	)
	ltch
	(
	.*,
	.ltch_i			( lpf_ltch_i ),
	.data_i			( freq_lpf ),
	.data_o			( lpf_o )
	);


endmodule
