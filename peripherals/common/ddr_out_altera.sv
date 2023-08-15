/*
--------------------------------------------------------------------------------

Module: ddr_out_altera.sv

Function: 
- Dual data rate output for Altera target.

Instantiates:
- Nothing.

Notes:
- ddr_i[0] goes out first, on the rising clock.
- ddr_i[1] goes out second, on the falling clock.

--------------------------------------------------------------------------------
*/

module ddr_out_altera
	(
	// clocks & resets
	input		logic									clk_i,						// clock
	// I/O
	input		logic		[1:0]						ddr_i,						// ddr input
	output	logic									ddr_o							// ddr output
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	// None.


	/*
	================
	== code start ==
	================
	*/


	logic		[1:0]						ddr;

	// register
	always_ff @ ( posedge clk_i ) begin
		ddr <= ddr_i;
	end


	altddio_out
	#(
	.extend_oe_disable	( "UNUSED" ),
	.invert_output			( "OFF" ),
	.lpm_type				( "altddio_out" ),
	.oe_reg					( "UNUSED" ),
	.power_up_high			( "OFF" ),
	.width					( 1 )
	)
	altddio_out_component
	(
	.outclock				( clk_i ),
//	.datain_h				( ddr_i[0] ),
//	.datain_l				( ddr_i[1] ),
	.datain_h				( ddr[0] ),
	.datain_l				( ddr[1] ),
	.dataout					( ddr_o ),
	.aclr						( 1'b0 ),  // unused
	.aset						( 1'b0 ),  // unused
	.oe						( 1'b1 ),  // unused
	.oe_out					(  ),  // unused
	.outclocken				( 1'b1 ),  // unused
	.sclr						( 1'b0 ),  // unused
	.sset						( 1'b0 )  // unused
	);


/*
module altd_o (
	datain_h,
	datain_l,
	outclock,
	dataout);

	input	  datain_h;
	input	  datain_l;
	input	  outclock;
	output	  dataout;

	wire [0:0] sub_wire0;
	wire [0:0] sub_wire1 = sub_wire0[0:0];
	wire  dataout = sub_wire1;
	wire  sub_wire2 = datain_h;
	wire  sub_wire3 = sub_wire2;
	wire  sub_wire4 = datain_l;
	wire  sub_wire5 = sub_wire4;

	altddio_out	altddio_out_component (
				.outclock (outclock),
				.datain_h (sub_wire3),
				.datain_l (sub_wire5),
				.dataout (sub_wire0),
				.aclr (1'b0),
				.aset (1'b0),
				.oe (1'b1),
				.oe_out (),
				.outclocken (1'b1),
				.sclr (1'b0),
				.sset (1'b0));
	defparam
		altddio_out_component.extend_oe_disable = "UNUSED",
		altddio_out_component.intended_device_family = "Cyclone III",
		altddio_out_component.invert_output = "OFF",
		altddio_out_component.lpm_type = "altddio_out",
		altddio_out_component.oe_reg = "UNUSED",
		altddio_out_component.power_up_high = "OFF",
		altddio_out_component.width = 1;

*/
	
endmodule 