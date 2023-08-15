/*
--------------------------------------------------------------------------------

Module : ep4ce10f17c8n_module.sv

--------------------------------------------------------------------------------

Function:
- Processor core with PLL & peripherals.

Instantiates:
- hive_core_theremin.sv
- altera_pll.v

Notes:


--------------------------------------------------------------------------------
*/

module ep4ce10f17c8n_module
	(
	// clocks & resets
	input			logic								clk_50m_i,					// clock
	input			logic								rstn_i,						// async. reset, active low
	//
	input			logic	[3:0]						gpio_i,						// gpio inputs
	output		logic	[3:0]						gpio_o,						// gpio outputs
	output		logic	[3:0]						led_o,						// demo board LEDs, active low
	//
	input			logic								uart_rx_i,					// uart serial data
	output		logic								uart_tx_o,					// uart serial data
	//
	input			logic								midi_rx_i,					// midi serial data
	output		logic								midi_tx_o,					// midi serial data
	output		logic								midi_tx_n_o,				// midi serial data
	//
	output		logic								spi_scl_o,					// spi clock
	output		logic								spi_scs_o,					// spi chip select, active low
	output		logic								spi_sdo_o,					// spi serial data
	input			logic								spi_sdi_i,					// spi serial data
	//
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
	input			logic	[7:0]						pb_i,							// pushbutton inputs

	// SDRAM on AC608 module - unused
	output logic        sdram_clk,
	output logic [11:0] sdram_addr,
	output logic [1:0]  sdram_ba,
	output logic        sdram_cas_n,
	output logic        sdram_cke,
	output logic        sdram_cs_n,
	inout  logic [15:0] sdram_dq,
	output logic [1:0]  sdram_dqm,
	output logic        sdram_ras_n,
	output logic        sdram_we_n
	
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	logic					[31:0]					gpo;
	logic					[7:0]						xsr;
	logic												clk_core, clk_spdif;
	logic					[3:0]						sq_48k;
	logic												midi_tx;


	/*
	================
	== code start ==
	================
	*/


	// spdif pll
	pll_spdif  pll_spdif 
	(
	.inclk0				( clk_50m_i ),
	.c0					( clk_spdif )
	);


	// core pll
	pll_core  pll_core
	(
	.inclk0				( clk_50m_i ),
	.c0					( clk_core )
	);
	

	// the core
	hive_top_theremin  hive_top_theremin
	(
	.*,
	.clk_i				( clk_core ),
	.rst_i				( ~rstn_i ),
	.cla_i				( 0 ),
	.xsr_i				( xsr ),
	.gpio_i				( { '0, ~gpio_i } ),
	.gpio_o				( gpo ),
	.midi_tx_o			( midi_tx ),
	.clk_spdif_i		( clk_spdif ),
	.sq_48k_o			( sq_48k )
	);

	
	// assign xsrs
	always_comb xsr = { ~sq_48k, sq_48k };
	
	// assign gpio_o
	always_comb gpio_o = gpo[3:0];

	// the LEDs are active low
	always_comb led_o = ~gpo[7:4];
	
	// inverted MIDI TX (for use with external inverter)
	always_comb midi_tx_n_o = ~midi_tx;

	// non-inverted MIDI TX for development
	always_comb midi_tx_o = midi_tx;
	

endmodule
