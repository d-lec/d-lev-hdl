/*
--------------------------------------------------------------------------------

Module: enc_dec.sv

Function: 
- Rotary encoder debounce / decode.

Instantiates: 
- (2x) debounce.sv.

Notes:
- enc_i detent (rest) state = 'b11.
- cnt_o++ @ CW; cnt_o-- @ CCW, clear on read.
- Outputs are debounced & active high until read.

--------------------------------------------------------------------------------
*/

module enc_dec
	#(
	parameter										SYNC_W		= 2,		// resync registers, 1 min
	parameter										DEB_W			= 8,		// debounce counter width (3 or larger)
	parameter										CNT_W			= 2		// count width
	)
	(
	// clocks & resets
	input 	logic									clk_i,					// clock
	input		logic									rst_i,					// async. reset, active high
	// interface
	input		logic									rd_i,						// read, active high
	input		logic		[1:0]						enc_i,					// rotary encoder input
	output	logic		[CNT_W-1:0]				cnt_o						// ++ @ CW, -- @ CCW, clear on read
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	localparam										STATE_W		= 3;		// state width (bits)
	//
	logic												rd;
	logic					[1:0]						enc_deb, enc_not, enc_bin;
	logic	signed		[STATE_W-1:0]			state, state_sel;



	/*
	================
	== code start ==
	================
	*/

	// resync and debounce inputs
	debounce
	#(
	.SYNC_W				( SYNC_W ),
	.DEB_W				( DEB_W )
	)
	deb_0_inst
	(
	.*,
	.data_i				( enc_i[0] ),
	.data_o				( enc_deb[0] )
	);
	
	debounce
	#(
	.SYNC_W				( SYNC_W ),
	.DEB_W				( DEB_W )
	)
	deb_1_inst
	(
	.*,
	.data_i				( enc_i[1] ),
	.data_o				( enc_deb[1] )
	);
	

	// combine & invert
	always_comb enc_not = ~enc_deb;

	// convert input Gray-code to binary
	assign enc_bin = { enc_not[1], ^enc_not };

	/*
	-------------------
	-- state machine --
	-------------------
	*/

	// state mux
	always_comb begin
		if ( enc_bin == 0 ) begin
			state_sel <= 0;  // detent position
		end else begin
			state_sel <= state;  // default is stay in current state
			if ( enc_bin - state[1:0] == 2'b01 ) begin  // +1
				state_sel <= state + 1'b1;  // go clockwise
			end else if ( enc_bin - state[1:0] == 2'b11 ) begin  // -1
				state_sel <= state - 1'b1;  // go counter-clockwise
			end
		end
	end

	// register state
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			state <= 0;  // detent position
		end else begin
			state <= state_sel;
		end
	end


	/*
	------------
	-- output --
	------------
	*/

	// output
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			rd <= 0;
			cnt_o <= 0;
		end else begin
			rd <= rd_i;
			if (( state_sel == 0 ) && ( state == 3 )) cnt_o <= cnt_o + 1'b1;  // CW
			else if (( state_sel == 0 ) && ( state == -3 )) cnt_o <= cnt_o - 1'b1;  // CCW
			else if ( rd )	cnt_o <= 0;  // clear on read
		end
	end


endmodule
