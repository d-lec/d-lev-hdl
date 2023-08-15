/*
--------------------------------------------------------------------------------

Module: hive_reg_pitch

Function: 
- Forms the pitch side of a digital Theremin.

Instantiates:
- (1x) lc_dpll.sv
- (1x) hive_reg_base.sv

Notes:
- See individual components for details.

--------------------------------------------------------------------------------
*/

module hive_reg_pitch
	#(
	parameter	real						LC_FREQ				= P_LC_FREQ,	// lc res. frequency
	parameter	real						LC_Q					= P_LC_Q,		// lc res. quality factor
	parameter								FREQ_W				= P_FREQ_W,		// sets bandwidth
	parameter								RANGE_W				= PV_RANGE_W,	// sets range (low limit)
	parameter								D_SHL_W				= PV_D_SHL_W,	// dither left shift width (bits)
	parameter								LSV					= P_LSV,			// LSb's constant value, 0 to disable
	parameter								LPF_SHR				= P_LPF_SHR,	// LPF right shift (sets corner freq)
	parameter								LPF_ORDER			= PV_LPF_ORDER,// LPF order
	parameter								IO_DDR				= PV_IO_DDR		// 1=use ddr at inputs & output; 0=no ddr
	)
	(
	// clocks & resets
	input		logic							clk_i,							// clock
	input		logic							clk_spdif_i,					// clock
	input		logic							rst_i,							// async. reset, active hi
	// rbus interface
	input		logic	[RBUS_ADDR_W-1:0]	rbus_addr_i,					// address
	input		logic							rbus_wr_i,						// data write enable, active high
	input		logic							rbus_rd_i,						// data read enable, active high
	input		logic	[ALU_W-1:0]			rbus_wr_data_i,				// write data
	output	logic	[ALU_W-1:0]			rbus_rd_data_o,				// read data
	// theremin interface
	input		logic	[TRI_W-1:0]			tri_i,							// triangle in (sgn)
	input		logic							lpf_ltch_i,						// lpf latch in
	input		logic							lpf_en_i,						// lpf enable, active high
	output	logic							sq_o,								// square output
	input		logic							zero_i,							// zero async input
	input		logic							quad_i							// quad async input
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/	
	import hive_params::*; 
	import hive_defines::*; 
	//
	logic		[D_SHL_W-1:0]				wr_data;
	logic		[ALU_W-1:0]					rd_data;

	
	/*
	================
	== code start ==
	================
	*/

	lc_dpll
	#(
	.CLK_FREQ			( SPDIF_HZ ),
	.LC_FREQ				( LC_FREQ ),
	.LC_Q					( LC_Q ),
	.DATA_W				( ALU_W ),
	.FREQ_W				( FREQ_W ),
	.RANGE_W				( RANGE_W ),
	.D_SHL_W				( D_SHL_W ),
	.LSV					( LSV ),
	.LPF_SHR				( LPF_SHR ),
	.LPF_ORDER			( LPF_ORDER ),
	.SYNC_W				( SYNC_W ),
	.IO_DDR				( IO_DDR ),
	.TRI_W				( TRI_W )
	)
	lc_dpll
	(
	.*,
	.clk_i				( clk_spdif_i ),
	.d_shl_i				( wr_data ),
	.lpf_o				( rd_data )
	);


	// rbus register
	hive_reg_base
	#(
	.DATA_W			( ALU_W ),
	.ADDR_W			( RBUS_ADDR_W ),
	.ADDR				( `RBUS_PITCH ),
	.WR_MODE			( "LTCH" ),
	.RD_MODE			( "THRU" ),
	.WR_MASK			( { D_SHL_W{ 1'b1 } } )
	)
	reg_pitch
	(
	.*,
	.reg_rd_o		(  ),  // unused
	.reg_wr_o		(  ),  // unused
	.reg_data_o		( wr_data ),
	.reg_data_i		( rd_data )
	);

	
endmodule
