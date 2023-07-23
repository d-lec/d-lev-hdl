/*
--------------------------------------------------------------------------------

Module: ltch.sv

Function: 
- Data latch.

Instantiates: 
- Nothing.

Notes:
- Output is latched when 0=>1 change is seen at ltch_i.

--------------------------------------------------------------------------------
*/

module ltch
	#(
	parameter										DATA_W			= 4	// I/O width
	)
	(
	// clocks & resets
	input		logic									clk_i,					// clock
	input		logic									rst_i,					// async reset, active high
	// data interface
	input		logic									ltch_i,					// rise=latch output
	input		logic		[DATA_W-1:0]			data_i,					// input data
	output	logic		[DATA_W-1:0]			data_o					// output data
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	logic												ltch_r;


	/*
	================
	== code start ==
	================
	*/


	// latch output on edge
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			ltch_r <= 0;
			data_o <= 0;
		end else begin
			ltch_r <= ltch_i;
			if ( ltch_i && ~ltch_r ) begin  // rising edge
				data_o <= data_i;
			end
		end
	end

	
endmodule
