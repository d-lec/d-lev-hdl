/*
--------------------------------------------------------------------------------

Module: led_tuner

Function: 
- Forms a serial TLC5916 LED interface.

Instantiates:
- Nothing.

Notes:
- Controls three 8-bit ICs in series.
- SCL quiescent state is low.
- SDA is sent LSb first, transition @ clock fall.
- Parameterized parallel data width.
- No provision for serial data read.

TLC5916 notes:
- Data & mode control sampled @ clock rise.
- Serial data in "normal mode" is MSb first (IC LED output pin numbering).
- Serial data in "special mode" is LSb first!
- OE is async active low (but sampled for mode switch!).
- Setting LE high and clocking in new data causes the continuous transfer of 
  data from the serial flops to the parallel outputs, so LE is a
  transparent latch rather than a clocked flop (but sampled for mode switch!).
- Since LE is a transparent latch, output data changes on the rising edge of LE
  (and at clock rise if LE is held high).
- The switch to special mode is accomplished by sampling OE (at clock rise) 
  high, low, high, with LE sampled high on the fourth clock rise.
- The switch back to normal mode is accomplished by sampling OE (at clock 
  rise) high, low, high, with LE sampled low on the fourth clock rise.  The 
  datasheet has a big typo here.
- The datasheet says OE must be high for special mode data shifting.
- In special mode, with a 1k current set resistor, the maximum measured current 
  is 19.54mA, the minimum is 1.634mA.  The datasheet says these should be 
  18.75mA and 1.575mA, so not too far off the mark.
- Clock rise to data output on the serial data output pin 14 is around 18ns.  
  This could be problematic when cascading devices (data race), so use a series
  resistor located near SDO to slow the edge down.
  
--------------------------------------------------------------------------------
*/

module led_tuner
	#(
	parameter								DATA_W				= 24		// parallel data width (bits)
	)
	(
	// clocks & resets
	input		logic							clk_i,							// clock
	input		logic							rst_i,							// async. reset, active hi
	// parallel interface	
	input		logic							wr_i,								// write, active high
	input		logic							mode_i,							// special mode, active high
	input		logic	[DATA_W-1:0]		data_i,							// parallel data
	input		logic							en_i,								// enable, active high
	output	logic							busy_o,							// busy, active hi
	// serial interface
	output	logic							scl_o,							// serial clock
	output	logic							sda_o,							// serial data
	output	logic							le_o,								// latch enable, active high
	output	logic							oe_o								// output enable, active low
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	localparam								MAX_NORM				= DATA_W+1;  // 25 clocks
	localparam								MAX_MODE				= DATA_W+4;  // 28 clocks
	localparam								BIT_W 				= $clog2( MAX_MODE+1 );
	//
	logic				[BIT_W-1:0]			bit_count, bit_max;
	logic										sub_bit;
	//
	logic										wr, mode;
	logic				[DATA_W-1:0]		data, sr;
	//
	logic										shft_f, busy_f, load_f, mode_f;


	/*
	================
	== code start ==
	================
	*/


	/*
	-----------
	-- input --
	-----------
	*/
	
	
	// register inputs
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			wr <= 0;
			mode <= 0;
			data <= 0;
		end else begin
			wr <= wr_i;
			mode <= mode_i;
			data <= data_i;
		end
	end


	/*
	--------------
	-- counters --
	--------------
	*/

	// form the sub_bit & bit_count up-counters
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			bit_count <= BIT_W'( MAX_NORM );
			sub_bit <= '1;
		end else begin
			if ( load_f ) begin
				{ bit_count, sub_bit } <= 0;
			end else if ( busy_f && en_i ) begin
				{ bit_count, sub_bit } <= { bit_count, sub_bit } + 1'b1;
			end
		end
	end

	// decode max
	always_comb bit_max = ( mode_f ) ? BIT_W'( MAX_MODE ) : BIT_W'( MAX_NORM );

	// decode flags
	always_comb shft_f = ( sub_bit && en_i );
	always_comb busy_f = ( { bit_count, sub_bit } != { bit_max, 1'b1 } );
	always_comb load_f = ( wr && !busy_f );


	/*
	---------------------
	-- data conversion --
	---------------------
	*/
	
	// parallel => serial conversion (LSb first) & mode flag
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			sr <= 0;
			mode_f <= 0;
		end else begin
			if ( load_f ) begin
				sr <= data;
				mode_f <= mode;
			end else if ( shft_f ) begin
				sr <= sr[DATA_W-1:1];
			end
		end
	end


	/*
	------------
	-- output --
	------------
	*/

	// decode & register all outputs
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			scl_o <= 0;
			oe_o <= 0;
			le_o <= 0;
			//
			sda_o <= 0;
			busy_o <= 0;
		end else begin
			busy_o <= busy_f;
			//
			if ( en_i ) begin
				// decode scl_o
				unique case ( bit_count )
					DATA_W, bit_max : scl_o <= 0;
					default: scl_o <= sub_bit;
				endcase
				// decode oe_o
				unique case ( bit_count )
					1, MAX_NORM, bit_max : oe_o <= 0;
					default: oe_o <= mode_f;
				endcase
				// decode le_o
				unique case ( bit_count )
					3 : le_o <= mode_f;
					DATA_W : le_o <= '1;
					default: le_o <= 0;
				endcase
				// just register
				sda_o <= sr[0];
			end
		end
	end

endmodule
