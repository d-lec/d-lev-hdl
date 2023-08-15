/*
--------------------------------------------------------------------------------

Module : hive_top.sv

--------------------------------------------------------------------------------

Function:
- General purpose barrel processor FPGA core with:
  - 8 threads & 8 stage pipeline
  - 8 indexed LIFO stacks per thread w/ pop control
  - 32 bit data
  - 1 to 4 byte opcode
  - 32 bit GPIO
  - RS232 RX/TX UART
  - SPI interface

Instantiates (at this level):
- rst_bridge.sv
- hive_core.sv
- hive_reg_uart_tx.sv
- hive_reg_uart_rx.sv
- hive_reg_spi.sv

Dependencies:
- hive_pkg.sv

--------------------------------------------------------------------------------
*/

module hive_top
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
	output		logic								spi_scl_o,					// spi clock
	output		logic								spi_scs_o,					// spi chip select, active low
	output		logic								spi_sdo_o,					// spi serial data
	input			logic								spi_sdi_i					// spi serial data
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
	logic					[ALU_W-1:0]				uart_tx_rd_data, uart_rx_rd_data, spi_rd_data;


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
		spi_rd_data;


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


endmodule
