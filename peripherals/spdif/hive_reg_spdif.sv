/*
--------------------------------------------------------------------------------

Module: hive_reg_spdif

Function: 
- Forms the SPDIF TX of a digital Theremin.

Instantiates:
- (2x) hive_reg_base.sv
- (2x) ss_buf.sv
- (1x) spdif_tx.sv

Notes:
- See individual components for details.

--------------------------------------------------------------------------------
*/

module hive_reg_spdif
	#(
	parameter								UNITS					= 2,		// number of SPDIF units
	parameter								COPY_OK				= 1,		// no copy prot.
	parameter								FS_44K1				= 0		// 48kHz
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
	input		logic							en_i,								// enable, active hi
	output	logic							pcm_rd_o,						// pcm read, active hi one clock
	output	logic							spdif_tx_o,						// serial data
	output	logic							spdif_tx_h_o					// serial data
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/	
	import hive_params::*; 
	import hive_defines::*; 
	//
	logic										wr;
	logic		[PCM_W-1:0]					wr_data;
	logic		[PCM_W-1:0]					wr_sr[0:3];
	logic		[PCM_W-1:0]					pcm_L2[0:1];
	logic		[PCM_W-1:0]					pcm_R2[0:1];
	logic										spdif_tx2[0:1];

	
	/*
	================
	== code start ==
	================
	*/


	// rbus register
	hive_reg_base
	#(
	.DATA_W				( ALU_W ),
	.ADDR_W				( RBUS_ADDR_W ),
	.ADDR					( `RBUS_SPDIF ),
	.WR_MODE				( "REGS" ),
	.RD_MODE				( "THRU" )
	)
	reg_spdif
	(
	.*,
	.reg_rd_o			(  ),  // unused
	.reg_wr_o			( wr ),
	.reg_data_o			( wr_data ),
	.reg_data_i			(  )  // unused
	);


	// write data to 4 deep shift reg
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			wr_sr[3] <= 0;
			wr_sr[2] <= 0;
			wr_sr[1] <= 0;
			wr_sr[0] <= 0;
		end else begin
			if ( wr ) begin
				wr_sr[3] <= wr_data;
				wr_sr[2] <= wr_sr[3];
				wr_sr[1] <= wr_sr[2];
				wr_sr[0] <= wr_sr[1];
			end
		end
	end


	// spdif encode & xmit
	spdif_tx
	#(
	.UNITS			( UNITS ),
	.PCM_W			( PCM_W ),
	.COPY_OK			( COPY_OK ),
	.FS_44K1			( FS_44K1 )
	)
	spdif_tx
	(
	.*,
	.clk_i			( clk_spdif_i ),
	.pcm_L_i			( pcm_L2 ),
	.pcm_R_i			( pcm_R2 ),
	.spdif_tx_o		( spdif_tx2 )
	);

	
	// connect pcm
	always_comb pcm_L2[0] = wr_sr[0];
	always_comb pcm_R2[0] = wr_sr[1];
	always_comb pcm_L2[1] = wr_sr[2];
	always_comb pcm_R2[1] = wr_sr[3];
	
	// connect outs
	always_comb spdif_tx_o = spdif_tx2[0];
	always_comb spdif_tx_h_o = spdif_tx2[1];
	
	
endmodule
