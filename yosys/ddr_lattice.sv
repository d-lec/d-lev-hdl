/*
--------------------------------------------------------------------------------

Module: ddr_lattice.sv

Function: 
- Dual data rate input / output for Lattice ECP5 target.
- 'altera' in the module name(s) is a misnomer here,
   but we retain the name for backwards compatibility with existing codebase

Instantiates:
- Nothing.

Notes:
- ddr_i[0] goes out first, on the rising clock.
- ddr_i[1] goes out second, on the falling clock.

Thanks to true_xark for this implementation, currently untested. -ESK

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
	
// Lattice ECP5 component
    IDDRX1F    
    IDDRX1F_component
    (
        .D        		( ddr_i ),
        .SCLK     		( clk_i ),
        .RST			( 1'b0 ),
        .Q0       		( ddr_o[0] ),
        .Q1       		( ddr_o[1] )
    );
endmodule 

module ddr_out_altera
    (
    // clocks & resets
    input   logic           clk_i,                      // clock
    // I/O
    input   logic   [1:0]   ddr_i,                      // ddr input
    output  logic           ddr_o                       // ddr output
    );

    logic   [1:0]   ddr;

    // register
    always_ff @ ( posedge clk_i ) begin
        ddr <= ddr_i;
    end
   
// Lattice ECP5 component
    ODDRX1F
    ODDRX1F_component
    (
        .SCLK(clk_i),
        .RST(1'b0),
        .D0( ddr[0]),    // NOTE: D0 sent "first", hopefully corresponds with Altera datain_h
        .D1( ddr[1]),
        .Q(ddr_o)
    );

    
endmodule 
