/*
--------------------------------------------------------------------------------

Module: pb_cond.sv

Function: 
- Pushbutton conditioning.

Instantiates: 
- Nothing.

Notes:
- Input is resynchronized & inverted.
- Input low state is latched.
- Clear on read.

--------------------------------------------------------------------------------
*/

module pb_cond
	#(
	parameter										SYNC_W		= 2		// resync registers, 1 min
	)
	(
	// clocks & resets
	input 	logic									clk_i,					// clock
	input		logic									rst_i,					// async. reset, active high
	// interface
	input		logic									rd_i,						// read, active high
	input		logic									pb_i,						// pushbutton input, active low
	output	logic									pb_o						// sampled low state, active high
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	logic					[SYNC_W-1:0]			pb_sr;
	logic												rd;



	/*
	================
	== code start ==
	================
	*/


	// register & resync
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			rd  <= 0;
			pb_sr <= '1;
		end else begin
			rd <= rd_i;
			pb_sr <= SYNC_W'( { pb_sr, pb_i } );
		end
	end

	// latch input low (takes precedence over) clear on read
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			pb_o  <= 0;
		end else begin
			if ( ~pb_sr[SYNC_W-1] ) begin
				pb_o <= '1;
			end else if ( rd ) begin
				pb_o <= 0;
			end
		end
	end


endmodule
