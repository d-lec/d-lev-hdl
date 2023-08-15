/*
--------------------------------------------------------------------------------

Module: ddr_in_altera.sv

Function: 
- Dual data rate input for Altera target.

Instantiates:
- Nothing.

Notes:

--------------------------------------------------------------------------------
*/

module ddr_in_altera
	(
	// clocks & resets
	input		logic									clk_i,						// clock
	// I/O
	input		logic									ddr_i,						// ddr input
	output	logic		[1:0]						ddr_o							// ddr output
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


	altddio_in	
	#(
	.invert_input_clocks ( "OFF" ),
	.lpm_type				( "altddio_in" ),
	.power_up_high			( "OFF" ),
	.width					( 1 )
	)
	altddio_in_component
	(
	.datain					( ddr_i ),
	.inclock					( clk_i ),
	.dataout_h				( ddr_o[0] ),
	.dataout_l				( ddr_o[1] ),
	.aclr						( 1'b0 ),  // unused
	.aset						( 1'b0 ),  // unused
	.inclocken				( 1'b1 ),  // unused
	.sclr						( 1'b0 ),  // unused
	.sset						( 1'b0 )  // unused
	);


	
endmodule 