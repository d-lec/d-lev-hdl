/*
--------------------------------------------------------------------------------

Module: spi_master

Function: 
- Forms a SPI bus master interface.

Instantiates:
- Nothing.

Notes:
- Byte based.
- Mode 0: SCL quiescent state is low.
- SDI & SDO: MSb first, sample @ clock rise, transition @ clock fall.
- Parameterized parallel data width.
- Parameterized phase clocks (clock divider).

--------------------------------------------------------------------------------
*/

module spi_master
	#(
	parameter								DATA_W				= 8,		// parallel data width (bits)
	parameter								PHASE_CLKS			= 3		// high & low period clocks (1 min)
	)
	(
	// clocks & resets
	input		logic							clk_i,							// clock
	input		logic							rst_i,							// async. reset, active hi
	// parallel interface	
	input		logic							wr_i,								// write, active high
	output	logic							busy_o,							// busy, active hi
	input		logic							csn_i,							// chip select, active low
	input		logic	[DATA_W-1:0]		data_i,							// parallel data
	output	logic	[DATA_W-1:0]		data_o,							// parallel data
	// serial interface
	output	logic							scl_o,							// serial clock
	output	logic							scs_o,							// serial chip select, active low
	output	logic							sdo_o,							// serial data
	input		logic							sdi_i								// serial data
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	localparam								PHASE_MAX 			= PHASE_CLKS - 1;
	localparam								BIT_MAX 				= DATA_W;
	localparam								PHASE_W				= $clog2( PHASE_CLKS );
	localparam								BIT_W 				= $clog2( BIT_MAX+1 );
	//
	logic				[PHASE_W-1:0]		phase_c;
	logic										scl;
	logic				[BIT_W-1:0]			bit_c;
	//
	logic										phase_f, busy_f, load_f, shift_f;
	//
	logic				[DATA_W-1:0]		data_i_r, sdo_sr, sdi_sr;
	//
	logic										wr, csn, scs;


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
			csn <= 0;
			data_i_r <= 0;
		end else begin
			wr <= wr_i;
			csn <= csn_i;
			data_i_r <= data_i;
		end
	end


	/*
	--------------
	-- counters --
	--------------
	*/

	// form the phase_c & bit_c up-counters
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			phase_c <= 0;
			scl <= 0;
			bit_c <= BIT_W'( BIT_MAX );
		end else begin
			if ( load_f ) begin
				phase_c <= 0;
				{ bit_c, scl } <= 0;
			end else if ( busy_f ) begin
				if ( phase_f ) begin
					phase_c <= 0;
					{ bit_c, scl } <= { bit_c, scl } + 1'b1;
				end else begin
					phase_c <= phase_c + 1'b1;
				end
			end
		end
	end

	// decode flags
	always_comb phase_f = ( phase_c == PHASE_MAX );
	always_comb busy_f = ( bit_c != BIT_MAX );
	always_comb shift_f = ( phase_f && scl );
	always_comb load_f = ( wr && !csn && !busy_f );
	

	/*
	---------------------
	-- data conversion --
	---------------------
	*/
	
	// parallel <=> serial conversion
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			sdi_sr <= 0;
			sdo_sr <= 0;
		end else begin
			if ( load_f ) begin
				sdo_sr <= data_i_r;
			end else if ( shift_f ) begin
				sdi_sr <= { sdi_sr[DATA_W-2:0], sdi_i };
				sdo_sr <= { sdo_sr[DATA_W-2:0], 1'b0 };
			end
		end
	end


	/*
	------------
	-- output --
	------------
	*/

	// chip select
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			scs <= '1;
		end else begin
			if ( wr ) begin
				scs <= csn;
			end
		end
	end

	// stuff
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			busy_o <= 0;
			scl_o <= 0;
			sdo_o <= 0;
			scs_o <= '1;
		end else begin
			busy_o <= busy_f;
			scl_o <= scl;
			sdo_o <= sdo_sr[DATA_W-1];
			scs_o <= scs;
		end
	end

	// data
	always_comb data_o = sdi_sr;


endmodule
