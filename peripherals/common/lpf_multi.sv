/*
--------------------------------------------------------------------------------

Module: lpf_multi.sv

Function: 
- Cascade of first order filters.

Instantiates: 
- ORDER * lpf.sv

Notes:
- Identical params for all filters.
- See lpf.sv for details of base filter.

--------------------------------------------------------------------------------
*/

module lpf_multi
	#(
	parameter										DATA_W			= 32,	// I/O data width
	parameter										SHR				= 16,	// time constant, see notes
	parameter										ORDER				= 3	// filter order
	)
	(
	// clocks & resets
	input		logic									clk_i,					// clock
	input		logic									rst_i,					// async reset, active high
	// data interface
	input		logic									en_i,						// enable, active high
	input		logic		[DATA_W-1:0]			data_i,					// data in
	output	logic		[DATA_W-1:0]			lp_o						// low pass out
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	localparam										ACCUM_W			= DATA_W+SHR;
	genvar											g;


	/*
	================
	== code start ==
	================
	*/


	// fixed rate variable order lpf
	generate
		if ( ORDER == 0 ) begin

			// simple wires
			always_comb lp_o = data_i;

		end else begin
		
			// declare interconnect signals
			logic [ACCUM_W-1:0]	lp_io[0:ORDER-1];

			// input reg
			logic [DATA_W-1:0]	in_reg;
			
			always_ff @ ( posedge clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					in_reg <= 0;
				end else begin
					if ( en_i ) begin
						in_reg <= data_i;
					end
				end
			end

			// generate and interconnect
			for ( g=0; g<ORDER; g=g+1 ) begin : loop
				lpf
				#(
				.DATA_W			( ACCUM_W ),
				.SHR				( SHR )
				)
				lpf
				(
				.*,
				.data_i			( g ? lp_io[g-1] : in_reg << SHR ),
				.lp_o				( lp_io[g] )
				);
			end  // endfor : loop
			
			// drive output
			always_comb lp_o = DATA_W'( lp_io[ORDER-1] >> SHR );

		end
	endgenerate
	
endmodule
