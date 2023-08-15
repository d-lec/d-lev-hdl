/*
--------------------------------------------------------------------------------

Module : hive_top_theremin.sv

--------------------------------------------------------------------------------

Function:
- General purpose barrel processor FPGA core with:
  - 8 threads & 8 stage pipeline
  - 8 indexed LIFO stacks per thread w/ pop control
  - 32 bit data
  - 16 bit opcode
  - 32 bit GPIO
- RS232 RX/TX UART
- SPI interface
- SPDIF interface
- Pitch interface
- Volume interface
- LED Tuner interface
- LCD module interface
- Rotary encoder interface

Instantiates (at this level):
- rst_bridge.sv
- hive_core.sv
- hive_reg_uart_tx.sv
- hive_reg_uart_rx.sv
- hive_reg_spi.sv
- hive_reg_spdif.sv
- hive_reg_midi.sv
- hive_reg_pitch.sv
- hive_reg_volume.sv
- hive_reg_tuner.sv
- hive_reg_lcd.sv
- hive_reg_rot_enc.sv

Dependencies:
- hive_pkg.sv

--------------------------------------------------------------------------------
*/

module hive_top_theremin
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	//
	input			logic								cla_i,						// clear all threads, active high
	input			logic	[THREADS-1:0]			xsr_i,						// external service request
	//
	input			logic	[ALU_W-1:0]				gpio_i,						// gpio
	output		logic	[ALU_W-1:0]				gpio_o,
	//
	input			logic								uart_rx_i,					// uart serial data
	output		logic								uart_tx_o,					// uart serial data
	//
	output		logic								midi_tx_o,					// midi serial data
	//
	output		logic								spi_scl_o,					// spi clock
	output		logic								spi_scs_o,					// spi chip select, active low
	output		logic								spi_sdo_o,					// spi serial data
	input			logic								spi_sdi_i,					// spi serial data
	// 
	input			logic								clk_spdif_i,				// clock
	output		logic	[3:0]						sq_48k_o,					// PCM clocks out
	output		logic								spdif_tx_o,					// serial data
	output		logic								spdif_tx_h_o,				// serial data
	//
	output		logic								pitch_sq_o,					// square output
	input			logic								pitch_zero_i,				// zero async input
	input			logic								pitch_quad_i,				// quad async input
	//
	output		logic								volume_sq_o,				// square output
	input			logic								volume_zero_i,				// zero async input
	input			logic								volume_quad_i,				// quad async input
	//
	output		logic								tuner_scl_o,				// serial clock
	output		logic								tuner_sda_o,				// serial data
	output		logic								tuner_le_o,					// latch enable, active high
	output		logic								tuner_oe_o,					// output enable, active low
	//
	output		logic								lcd_rs_o,					// 0=command; 1=data/addr
	output		logic	[3:0]						lcd_data_o,					// parallel data out
	output		logic								lcd_e_o,						// enable strobe, active high
	//
	input			logic	[1:0]						enc_0_i,						// rotary encoder inputs
	input			logic	[1:0]						enc_1_i,
	input			logic	[1:0]						enc_2_i,
	input			logic	[1:0]						enc_3_i,
	input			logic	[1:0]						enc_4_i,
	input			logic	[1:0]						enc_5_i,
	input			logic	[1:0]						enc_6_i,
	input			logic	[1:0]						enc_7_i,
	//
	input			logic	[7:0]						pb_i							// pushbutton inputs
	);

	
	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*; 
	import hive_types::*; 
	//
	logic												rst;
	logic					[RBUS_ADDR_W-1:0]		rbus_addr;
	logic												rbus_wr, rbus_rd;
	logic					[ALU_W-1:0]				rbus_wr_data, rbus_rd_data;
	logic					[ALU_W-1:0]				uart_tx_rd_data, uart_rx_rd_data;
	logic					[ALU_W-1:0]				spi_rd_data, spdif_rd_data;
	logic					[ALU_W-1:0]				pitch_rd_data, volume_rd_data;
	logic					[ALU_W-1:0]				tuner_rd_data, lcd_rd_data;
	logic					[ALU_W-1:0]				enc_rd_data;
	logic					[ALU_W-1:0]				midi_rd_data;
	logic					[1:0]						lpf_en;
	logic												lpf_ltch;
	logic					[TRI_W-1:0]				tri_48k;
	logic												pcm_rd;
	logic												spdif_en;


	/*
	================
	== code start ==
	================
	*/


	// reset bridge
	rst_bridge
	#(
	.SYNC_W				( SYNC_W )
	)
	rst_bridge
	(
	.*,
	.rst_o				( rst )
	);


	// the core
	hive_core  hive_core
	(
	.*,
	.rst_i				( rst ),
	.rbus_addr_o		( rbus_addr ),
	.rbus_wr_o			( rbus_wr ),
	.rbus_rd_o			( rbus_rd ),
	.rbus_wr_data_o	( rbus_wr_data ),
	.rbus_rd_data_i	( rbus_rd_data )
	);


	// big ORing of rbus read data
	always_comb rbus_rd_data = 
		uart_tx_rd_data |
		uart_rx_rd_data |
		spi_rd_data |
		spdif_rd_data |
		midi_rd_data |
		pitch_rd_data |
		volume_rd_data |
		tuner_rd_data |
		lcd_rd_data |
		enc_rd_data |
		lcd_rd_data ;

		
	// uart tx
	hive_reg_uart_tx  hive_reg_uart_tx
	(
	.*,
	.rst_i				( rst ),
	.rbus_addr_i		( rbus_addr ),
	.rbus_wr_i			( rbus_wr ),
	.rbus_rd_i			( rbus_rd ),
	.rbus_wr_data_i	( rbus_wr_data ),
	.rbus_rd_data_o	( uart_tx_rd_data )
	);


	// uart rx
	hive_reg_uart_rx  hive_reg_uart_rx
	(
	.*,
	.rst_i				( rst ),
	.rbus_addr_i		( rbus_addr ),
	.rbus_wr_i			( rbus_wr ),
	.rbus_rd_i			( rbus_rd ),
	.rbus_wr_data_i	( rbus_wr_data ),
	.rbus_rd_data_o	( uart_rx_rd_data ),
	.line_err_o			(  ),  // unused
	.wr_err_o			(  )  // unused
	);


	// spi
	hive_reg_spi  hive_reg_spi
	(
	.*,
	.rst_i				( rst ),
	.rbus_addr_i		( rbus_addr ),
	.rbus_wr_i			( rbus_wr ),
	.rbus_rd_i			( rbus_rd ),
	.rbus_wr_data_i	( rbus_wr_data ),
	.rbus_rd_data_o	( spi_rd_data ),
	.scl_o				( spi_scl_o ),
	.scs_o				( spi_scs_o ),
	.sdo_o				( spi_sdo_o ),
	.sdi_i				( spi_sdi_i ),
	.loop_i				( 0 )
	);


	// spdif
	hive_reg_spdif  hive_reg_spdif
	(
	.*,
	.rst_i				( rst ),
	.rbus_addr_i		( rbus_addr ),
	.rbus_wr_i			( rbus_wr ),
	.rbus_rd_i			( rbus_rd ),
	.rbus_wr_data_i	( rbus_wr_data ),
	.rbus_rd_data_o	( spdif_rd_data ),
	.en_i					( spdif_en ),
	.pcm_rd_o			( pcm_rd )
	);


	// midi
	hive_reg_midi  hive_reg_midi
	(
	.*,
	.rst_i				( rst ),
	.rbus_addr_i		( rbus_addr ),
	.rbus_wr_i			( rbus_wr ),
	.rbus_rd_i			( rbus_rd ),
	.rbus_wr_data_i	( rbus_wr_data ),
	.rbus_rd_data_o	( midi_rd_data )
	);

	
	// timing
	timing
	#(
	.PRE_W				( PRE_W ),
	.TRI_W				( TRI_W )
	)
	timing
	(
	.*,
	.clk_i				( clk_spdif_i ),
	.rst_i				( rst ),
	.spdif_en_o			( spdif_en ),
	.pcm_rd_i			( pcm_rd ),
	.lpf_en_o			( lpf_en ),
	.lpf_ltch_o			( lpf_ltch ),
	.tri_48k_o			( tri_48k )
	);	

	
	// pitch axis
	hive_reg_pitch  hive_reg_pitch
	(
	.*,
	.rst_i				( rst ),
	.rbus_addr_i		( rbus_addr ),
	.rbus_wr_i			( rbus_wr ),
	.rbus_rd_i			( rbus_rd ),
	.rbus_wr_data_i	( rbus_wr_data ),
	.rbus_rd_data_o	( pitch_rd_data ),
	.tri_i				( ~tri_48k ),
	.lpf_ltch_i			( lpf_ltch ),
	.lpf_en_i			( lpf_en[0] ),
	.sq_o					( pitch_sq_o ),
	.zero_i				( pitch_zero_i ),
	.quad_i				( pitch_quad_i )
	);


	// volume axis
	hive_reg_volume  hive_reg_volume
	(
	.*,
	.rst_i				( rst ),
	.rbus_addr_i		( rbus_addr ),
	.rbus_wr_i			( rbus_wr ),
	.rbus_rd_i			( rbus_rd ),
	.rbus_wr_data_i	( rbus_wr_data ),
	.rbus_rd_data_o	( volume_rd_data ),
	.tri_i				( tri_48k ),
	.lpf_ltch_i			( lpf_ltch ),
	.lpf_en_i			( lpf_en[1] ),
	.sq_o					( volume_sq_o ),
	.zero_i				( volume_zero_i ),
	.quad_i				( volume_quad_i )
	);


	// tuner
	hive_reg_tuner	 hive_reg_tuner
	(
	.*,
	.rst_i				( rst ),
	.rbus_addr_i		( rbus_addr ),
	.rbus_wr_i			( rbus_wr ),
	.rbus_rd_i			( rbus_rd ),
	.rbus_wr_data_i	( rbus_wr_data ),
	.rbus_rd_data_o	( tuner_rd_data ),
	.scl_o				( tuner_scl_o ),
	.sda_o				( tuner_sda_o ),
	.le_o					( tuner_le_o ),
	.oe_o					( tuner_oe_o )
	);


	// lcd
	hive_reg_lcd	 hive_reg_lcd
	(
	.*,
	.rst_i				( rst ),
	.rbus_addr_i		( rbus_addr ),
	.rbus_wr_i			( rbus_wr ),
	.rbus_rd_i			( rbus_rd ),
	.rbus_wr_data_i	( rbus_wr_data ),
	.rbus_rd_data_o	( lcd_rd_data )
	);


	// rotary encoders
	hive_reg_enc	 hive_reg_enc
	(
	.*,
	.rst_i				( rst ),
	.rbus_addr_i		( rbus_addr ),
	.rbus_wr_i			( rbus_wr ),
	.rbus_rd_i			( rbus_rd ),
	.rbus_wr_data_i	( rbus_wr_data ),
	.rbus_rd_data_o	( enc_rd_data )
	);


endmodule
