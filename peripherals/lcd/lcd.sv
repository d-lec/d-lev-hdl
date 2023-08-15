/*
--------------------------------------------------------------------------------

Module: lcd

Function: 
- Forms a 4 bit LCD display interface.

Instantiates:
- (1x) ddfs.sv

Notes:
- RS processor interface input is inverted: 1=command; 0=data|address
- Nibble based LCD interface, 9-bit processor interface (rs & data[7:0]).
- Nibble data and control are presented simultaneously to the LCD module.
- Timing parameters are calculated automatically given the system and LCD
  clock frequencies and sub-cycle times.
- No provision for data read.
- No provision for busy read, worst case times are used instead.
- DDFS is used to provide a ~190kHz time base for the bus wait time.
- With 1 us between bus cycles, and LCD controller instructions 
  taking much longer than this to execute, there isn't much to be gained
  by strictly adhering to bus cycle timing minimums, so generous timing
  margins can provided here in terms of setup, enable active, and hold.
- Clear and return instructions are decoded and given the extra time
  they require.

LCD controller notes (from the datasheet):
- Single 8-bit access or double 4-bit access.
- For 4 bit access, nibbles are presented MSn first.
- Minimum times for a bus cycle (single enable bus transaction):
  - 60ns control (RS) setup to enable high.
  - 450ns enable (E) active high time.
  - 195ns data setup to enable (E) low.
  - 20ns enable (E) low to control (RS) and data hold.
  - 1000ns min time between enable (E) rises.
- 190kHz is minimum LCD internal clock frequency @ 2.7V supply.
- It seems it takes 10 LCD clocks to do most instructions, or 52.63us.
- There are two instructions, 0x01 (clear) and 0b0000,001x (return), which
  require 40x longer, or 2.12ms.
- There are no dedicated hardware reset or busy lines.  There is a complex 
  procedure to initiate reset via the bus, and busy may be read via 
  the bus if desired (though not during a reset).

--------------------------------------------------------------------------------
*/

module lcd
	#(
	parameter	int						LCD_W					= 4,		// lcd_data_o width (bits)
	parameter	real						CLK_HZ				= 160000000,	// system clock rate (Hz)
	parameter	real						LCD_HZ				= 190000		// LCD board clock rate (Hz)
	)
	(
	// clocks & resets
	input		logic							clk_i,							// clock
	input		logic							rst_i,							// async. reset, active high
	// control interface	
	input		logic							rsn_i,							// 0=data|addr; 1=command
	input		logic	[LCD_W*2-1:0]		data_i,							// parallel data in
	input		logic							rd_rdy_i,						// input data ready, active high
	output	logic							rd_o,								// read input data, active high
	// LCD interface
	output	logic							lcd_rs_o,						// 0=command; 1=data|addr
	output	logic	[LCD_W-1:0]			lcd_data_o,						// parallel data out
	output	logic							lcd_e_o							// enable strobe, active high
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	//
	localparam	int						SU_NS					= 300;	// control/data/address change to enable high (ns)
	localparam	int						EN_NS					= 600;	// enable high time (ns)
	localparam	int						HO_NS					= 100;	// enable low to control/data/address change (ns)
	localparam	int						NORM					= 10;		// LCD board clocks for instruction
	localparam	int						LONG					= NORM*40;	// for long instructions
	// derived parameters
	localparam								DATA_W 				= LCD_W*2;
	localparam	int						SU_CLKS				= (SU_NS/1.0E9)*CLK_HZ;	// clocks
	localparam	int						EN_CLKS				= (EN_NS/1.0E9)*CLK_HZ;	// clocks
	localparam	int						HO_CLKS				= (HO_NS/1.0E9)*CLK_HZ;	// clocks
	localparam	int						SU_MAX				= SU_CLKS-1;	// max
	localparam	int						EN_MAX				= EN_CLKS+SU_MAX;	// max
	localparam	int						HO_MAX				= HO_CLKS+EN_MAX;	// max
	localparam	int						CYC_W 				= $clog2( HO_MAX+1 );
	localparam	int						WAIT_W 				= $clog2( LONG+1 );
	//
	logic										lcd_f;
	//
	logic				[CYC_W-1:0]			cyc_c;
	logic				[WAIT_W-1:0]		wait_c;
	logic										cyc_max_f, norm_max_f, long_max_f, wait_max_f, long_f;
	//
	logic										rs_f;
	logic				[DATA_W-1:0]		data_r;
	typedef enum
		{
		st_idle,
		st_load,
		st_cyc_0,
		st_cyc_1,
		st_wait
		} STATE_T;
	STATE_T									state;



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
	
	// snag data and control, output read
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			rs_f <= 0;
			data_r <= 0;
			rd_o <= 0;
		end else begin
			rd_o <= 0;  // default
			if ( state == st_load ) begin
				rs_f <= !rsn_i;
				data_r <= data_i;
				rd_o <= '1;
			end
		end
	end

	// decode flag
	always_comb long_f = !( |{rs_f, data_r[DATA_W-1:2]} );


	/*
	------------
	-- timing --
	------------
	*/


	// ddfs for LCD analog timing
	ddfs
	#(
	.INC_W				( 8 ),  // 8 here gives ~1% timing
	.CLK_FREQ			( CLK_HZ ),
	.OUT_FREQ			( LCD_HZ )
	)
	ddfs_inst
	(
	.*,
	.en_i					( state == st_wait ),
	.sq_o					(  ),  // unused
	.rise_o				(  ),  // unused
	.fall_o				( lcd_f )
	);


	// form the cycle up-counter
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			cyc_c <= 0;
		end else begin
			case ( state )
				st_cyc_0, st_cyc_1 : begin
					if ( cyc_max_f ) begin
						cyc_c <= 0;
					end else begin
						cyc_c <= cyc_c + 1'b1;
					end
				end
				default : begin
					cyc_c <= 0;
				end
			endcase
		end
	end
			

	// decode flag
	always_comb cyc_max_f = ( cyc_c == HO_MAX );

	// form the wait up-counter
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			wait_c <= 0;
		end else begin
			if ( state != st_wait ) begin
				wait_c <= 0;
			end else if ( lcd_f ) begin
				wait_c <= wait_c + 1'b1;
			end
		end
	end

	// decode flags
	always_comb norm_max_f = ( wait_c == NORM );
	always_comb long_max_f = ( wait_c == LONG );
	always_comb wait_max_f = ( long_f ) ? long_max_f : norm_max_f;


	/*
	-------------------
	-- state machine --
	-------------------
	*/

	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			state <= st_idle;
		end else begin
			state <= state;  // default: stay in current state
			case ( state )
				st_idle : begin  // idle
					if ( rd_rdy_i ) begin
						state <= st_load;  // load
					end
				end
				st_load : begin
					state <= st_cyc_0;  // do bus cycle
				end
				st_cyc_0 : begin
					if ( cyc_max_f ) begin
						state <= st_cyc_1;  // do MSn
					end
				end
				st_cyc_1 : begin
					if ( cyc_max_f ) begin
						state <= st_wait;  // do LSn
					end
				end
				st_wait : begin
					if ( wait_max_f ) begin
						state <= st_idle;  // done
					end
				end
				default : begin  // for fault tolerance
					state <= st_idle;
				end
			endcase
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
			lcd_rs_o <= 0;
			lcd_data_o <= 0;
			lcd_e_o <= 0;
		end else begin
			case ( state )
				st_cyc_0, st_cyc_1 : begin
					lcd_rs_o <= rs_f;
					lcd_data_o <= ( state == st_cyc_1 ) ? data_r[LCD_W-1:0] : data_r[DATA_W-1:LCD_W];
					case ( cyc_c )
						SU_MAX : lcd_e_o <= '1;
						EN_MAX : lcd_e_o <= 0;
					endcase
				end
				default : begin
					lcd_rs_o <= 0;
					lcd_data_o <= 0;
					lcd_e_o <= 0;
				end
			endcase
		end
	end


endmodule
