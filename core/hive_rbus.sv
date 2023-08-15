/*
--------------------------------------------------------------------------------

Module : hive_rbus.sv

--------------------------------------------------------------------------------

Function:
- Processor register set logic.

Instantiates:
- Nothing.

Dependencies:
- hive_pkg.sv

Notes:
- Basically just address selection and a single layer of registering.

--------------------------------------------------------------------------------
*/

module hive_rbus
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// control I/O
	input			logic								imda_i,						// 1=immediate data
	input			logic	[ALU_W-1:0]				im_alu_i,					// alu immediate
	input			logic	[ALU_W-1:0]				a_i,							// a
	input			logic	[ALU_W-1:0]				b_i,							// b 
	// reg I/O
	input			logic								reg_rd_i,					// 1=read
	input			logic								reg_wr_i,					// 1=write
	// rbus I/O
	output		logic								rbus_rd_o,					// data read enable, active high
	output		logic								rbus_wr_o,					// data write enable, active high
	output		logic	[RBUS_ADDR_W-1:0]		rbus_addr_o,				// address
	output		logic	[ALU_W-1:0]				rbus_wr_data_o,			// write data
	input			logic	[ALU_W-1:0]				rbus_rd_data_i,			// read data in
	output		logic	[ALU_W-1:0]				rbus_rd_data_o				// read data out
	);


	
	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	import hive_types::*;
	//
 	logic													imda;
 	logic					[RBUS_ADDR_W-1:0]			im_alu, b;




	/*
	================
	== code start ==
	================
	*/


	// register
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			rbus_wr_o <= 0;
			rbus_rd_o <= 0;
			rbus_wr_data_o <= 0;
			rbus_rd_data_o <= 0;
			imda <= 0;
			im_alu <= 0;
			b <= 0;
		end else begin
			rbus_wr_o <= reg_wr_i;
			rbus_rd_o <= reg_rd_i;
			rbus_wr_data_o <= a_i;
			rbus_rd_data_o <= rbus_rd_data_i;
			imda <= imda_i;
			im_alu <= RBUS_ADDR_W'( im_alu_i );
			b <= RBUS_ADDR_W'( b_i );
		end
	end

	// select
	always_comb rbus_addr_o = ( imda ) ? im_alu : b;


endmodule
