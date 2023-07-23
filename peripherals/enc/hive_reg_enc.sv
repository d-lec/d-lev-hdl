/*
--------------------------------------------------------------------------------

Module: hive_reg_enc

Function: 
- Rotary encoder interface.

Instantiates:
- (8x) enc_dec.sv
- (8x) pb_cond.sv
- (1x) hive_reg_base.sv

Notes:
- See individual components for details.

--------------------------------------------------------------------------------
*/

module hive_reg_enc
	(
	// clocks & resets
	input		logic							clk_i,							// clock
	input		logic							rst_i,							// async. reset, active hi
	// rbus interface
	input		logic	[RBUS_ADDR_W-1:0]	rbus_addr_i,					// address
	input		logic							rbus_wr_i,						// data write enable, active high
	input		logic							rbus_rd_i,						// data read enable, active high
	input		logic	[ALU_W-1:0]			rbus_wr_data_i,				// write data
	output	logic	[ALU_W-1:0]			rbus_rd_data_o,				// read data
	// encoder interface
	input		logic	[1:0]					enc_0_i,							// rotary encoder inputs
	input		logic	[1:0]					enc_1_i,
	input		logic	[1:0]					enc_2_i,
	input		logic	[1:0]					enc_3_i,
	input		logic	[1:0]					enc_4_i,
	input		logic	[1:0]					enc_5_i,
	input		logic	[1:0]					enc_6_i,
	input		logic	[1:0]					enc_7_i,
	input		logic	[7:0]					pb_i								// pushbutton inputs
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/	
	import hive_params::*; 
	import hive_defines::*; 
	//
	logic										rd;
	logic		[23:0]						rd_data;

	
	/*
	================
	== code start ==
	================
	*/

	// encoders
	enc_dec
	#(
	.SYNC_W				( SYNC_W ),
	.DEB_W				( ENC_DEB_W )
	)
	rot_0_inst
	(
	.*,
	.rd_i					( rd ),
	.enc_i				( enc_0_i ),
	.cnt_o				( rd_data[1:0] )
	);


	enc_dec
	#(
	.SYNC_W				( SYNC_W ),
	.DEB_W				( ENC_DEB_W )
	)
	rot_1_inst
	(
	.*,
	.rd_i					( rd ),
	.enc_i				( enc_1_i ),
	.cnt_o				( rd_data[3:2] )
	);


	enc_dec
	#(
	.SYNC_W				( SYNC_W ),
	.DEB_W				( ENC_DEB_W )
	)
	rot_2_inst
	(
	.*,
	.rd_i					( rd ),
	.enc_i				( enc_2_i ),
	.cnt_o				( rd_data[5:4] )
	);


	enc_dec
	#(
	.SYNC_W				( SYNC_W ),
	.DEB_W				( ENC_DEB_W )
	)
	rot_3_inst
	(
	.*,
	.rd_i					( rd ),
	.enc_i				( enc_3_i ),
	.cnt_o				( rd_data[7:6] )
	);


	enc_dec
	#(
	.SYNC_W				( SYNC_W ),
	.DEB_W				( ENC_DEB_W )
	)
	rot_4_inst
	(
	.*,
	.rd_i					( rd ),
	.enc_i				( enc_4_i ),
	.cnt_o				( rd_data[9:8] )
	);


	enc_dec
	#(
	.SYNC_W				( SYNC_W ),
	.DEB_W				( ENC_DEB_W )
	)
	rot_5_inst
	(
	.*,
	.rd_i					( rd ),
	.enc_i				( enc_5_i ),
	.cnt_o				( rd_data[11:10] )
	);


	enc_dec
	#(
	.SYNC_W				( SYNC_W ),
	.DEB_W				( ENC_DEB_W )
	)
	rot_6_inst
	(
	.*,
	.rd_i					( rd ),
	.enc_i				( enc_6_i ),
	.cnt_o				( rd_data[13:12] )
	);


	enc_dec
	#(
	.SYNC_W				( SYNC_W ),
	.DEB_W				( ENC_DEB_W )
	)
	rot_7_inst
	(
	.*,
	.rd_i					( rd ),
	.enc_i				( enc_7_i ),
	.cnt_o				( rd_data[15:14] )
	);


	// push buttons
	pb_cond
	#(
	.SYNC_W				( SYNC_W )
	)
	pb_0_inst
	(
	.*,
	.rd_i					( rd ),
	.pb_i					( pb_i[0] ),
	.pb_o					( rd_data[16] )
	);


	pb_cond
	#(
	.SYNC_W				( SYNC_W )
	)
	pb_1_inst
	(
	.*,
	.rd_i					( rd ),
	.pb_i					( pb_i[1] ),
	.pb_o					( rd_data[17] )
	);


	pb_cond
	#(
	.SYNC_W				( SYNC_W )
	)
	pb_2_inst
	(
	.*,
	.rd_i					( rd ),
	.pb_i					( pb_i[2] ),
	.pb_o					( rd_data[18] )
	);


	pb_cond
	#(
	.SYNC_W				( SYNC_W )
	)
	pb_3_inst
	(
	.*,
	.rd_i					( rd ),
	.pb_i					( pb_i[3] ),
	.pb_o					( rd_data[19] )
	);

	
	pb_cond
	#(
	.SYNC_W				( SYNC_W )
	)
	pb_4_inst
	(
	.*,
	.rd_i					( rd ),
	.pb_i					( pb_i[4] ),
	.pb_o					( rd_data[20] )
	);


	pb_cond
	#(
	.SYNC_W				( SYNC_W )
	)
	pb_5_inst
	(
	.*,
	.rd_i					( rd ),
	.pb_i					( pb_i[5] ),
	.pb_o					( rd_data[21] )
	);

	
	pb_cond
	#(
	.SYNC_W				( SYNC_W )
	)
	pb_6_inst
	(
	.*,
	.rd_i					( rd ),
	.pb_i					( pb_i[6] ),
	.pb_o					( rd_data[22] )
	);


	pb_cond
	#(
	.SYNC_W				( SYNC_W )
	)
	pb_7_inst
	(
	.*,
	.rd_i					( rd ),
	.pb_i					( pb_i[7] ),
	.pb_o					( rd_data[23] )
	);



	// rbus register
	hive_reg_base
	#(
	.DATA_W			( ALU_W ),
	.ADDR_W			( RBUS_ADDR_W ),
	.ADDR				( `RBUS_ENC ),
	.WR_MODE			( "THRU" ),
	.RD_MODE			( "THRU" )
	)
	reg_rot_enc
	(
	.*,
	.reg_rd_o		( rd ),
	.reg_wr_o		(  ),  // unused
	.reg_data_o		(  ),  // unused
	.reg_data_i		( rd_data )
	);


endmodule
