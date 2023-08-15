/*
--------------------------------------------------------------------------------

Module: debounce.sv

Function: 
- Single input debounce.

Instantiates: 
- Nothing.

Notes:
- Uses linear counter rather than IIR filter.
- Debounce count range is roughly 3/4 * 2^DEB_W.
- Hysteresis zone is roughly 1/3 the count range.
- For example, for DEB_W = 8: count is [-97:96]; hysteresis is [-33:32].
- Low input weighted 3x (-3); high input weighted 1x (+1).

--------------------------------------------------------------------------------
*/
module debounce
	#(
	parameter									SYNC_W 			= 2,		// number of resync regs (1 or larger)
	parameter									DEB_W				= 16		// debounce counter width (3 or larger)
	)
	(
	// clocks & resets
	input		logic								clk_i,						// clock
	input		logic								rst_i,						// async. reset, active hi
	// data I/O
	input		logic								data_i,						// data input
	output	logic								data_o						// data output
	);



	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	logic				[SYNC_W-1:0]			in_sr;
	logic				[DEB_W-1:0]				deb;
	logic											max_f, min_f;
	logic											hi_f, lo_f;



	/*
	================
	== code start ==
	================
	*/


	// resync input
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			in_sr <= '1;
		end else begin
			in_sr <= SYNC_W'( { in_sr, data_i } );
		end
	end

	// form the up/down counter
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			deb <= 0;
		end else begin
			if ( in_sr[SYNC_W-1] && ~max_f ) begin
				deb <= deb + 1'd1;
			end else if ( ~in_sr[SYNC_W-1] && ~min_f ) begin
				deb <= deb - 2'd3;
			end
		end
	end

	// decode flags
	always_comb max_f = ( deb[DEB_W-1:DEB_W-3] == 3'b011 );
	always_comb hi_f  = ( deb[DEB_W-1:DEB_W-3] == 3'b001 );
	always_comb lo_f  = ( deb[DEB_W-1:DEB_W-3] == 3'b110 );
	always_comb min_f = ( deb[DEB_W-1:DEB_W-3] == 3'b100 );

	// output register
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			data_o <= 0;
		end else begin
			if ( hi_f ) begin
				data_o <= '1;
			end else if ( lo_f ) begin
				data_o <= '0;
			end
		end
	end

endmodule
