/*
--------------------------------------------------------------------------------

Module: spdif_tx

Function: 
- Forms the TX side of a SPDIF interface.

Instantiates:
- Nothing.

Notes:
- Minimalist consumer format SPDIF TX component.
- One PCM sample is placed within a 32 bit subframe w/ LSB first, and MSB aligned.
- One Left subframe plus one Right subframe forms a 64 bit frame.
- 192 frames form a block.
- TX data is bi-phase mark (BPM) encoded - except for preambles!
- BPM: always toggle output for every input data bit, 
  if data bit=1 then do mid toggle, if data bit=0 then no mid toggle.
- Preambles mark the beginnings of subframes and consume 4 PCM bit times.
- Preamble patterns intentionally voilate BPM encoding:
  - X: 11100010 or 00011101, Left subframe start.
  - Y: 11100100 or 00011011, Right subframe start.
  - Z: 11101000 or 00010111, Left subframe start & start of new block.
- Preamble polarity is the inverse of the output just before it.
- 192 Channel Status data bits (per block, replicated per subframe):
  - frame  2 : 1=copyright not asserted
  - frame 25 : 1=Fs 44.1kHz; 0=Fs 48kHz
- Subframes have odd parity bit calculated over [4:30], so parity is 
  even over [4:31] (even # of 1's).
- Subframe data is presented in this order (0 to 31): 
  - [0:3] preamble
  - [4:27] PWM data w/ MSB @ [27] & any unused LSBs zero padded
  - [28] Validity bit (0=PCM)
  - [29] User data (0)
  - [30] Channel Status data (0 except for frames 2 & 25)
  - [31] Parity bit (to make even # of 1's per subframe)
- Block data is presented as frames in this order:
  - Frame index:   190    191     0      1      2    ...
  - L/R:          [L,R]  [L,R]  [L,R]  [L,R]  [L,R]  ...
  - Preambles:    [X,Y]  [X,Y]  [Z,Y]  [X,Y]  [X,Y]  ...
- Enable pulse pulse s/b 1 clock high @ Fs * 128:
  - 48kHz * 128   = 6.144MHz
  - 44.1kHz * 128 = 5.6448MHz
- For reference: 
  - 48k   = (2^7)*(3^1)*(5^3)
  - 44.1k = (2^2)*(3^2)*(5^2)*(7^2)
- Operation / design is based on simple up counter constructed of the relevant
  frame and bit fields.
- Input PCM data is latched internally @ pcm_rd_o rise.
- Instantiate multiple units if desired via the UNITS parameter.

--------------------------------------------------------------------------------
*/

module spdif_tx
	#(
	parameter								UNITS					= 1,		// number of SPDIF units
	parameter								PCM_W					= 24,		// input pcm data width
	parameter								COPY_OK				= 1,		// copyright: 0=enforce; 1=copying ok
	parameter								FS_44K1				= 0		// sample frequency: 0=48kHz; 1=44.1kHz
	)
	(
	// clocks & resets
	input		logic							clk_i,							// clock
	input		logic							rst_i,							// async. reset, active hi
	input		logic							en_i,								// enable, active hi
	// parallel interface	
	input		logic	[PCM_W-1:0]			pcm_L_i[0:UNITS-1],			// pcm data left
	input		logic	[PCM_W-1:0]			pcm_R_i[0:UNITS-1],			// pcm data right
	output	logic							pcm_rd_o,						// pcm read, active hi one clock
	// serial interface
	output	logic							spdif_tx_o[0:UNITS-1]		// serial data
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	localparam								FRAME_W				= 8;			// frame count width
	localparam								BIT_W					= 5;			// sub frame bit count width
	localparam								PRE_W					= 8;			// preamble bits
	localparam								SR_W					= PCM_W + PRE_W;  // shift register width
	// preambles (index flipped and delta encoded so 1=toggle):
	localparam								PRE_X					= 'b11100100;
	localparam								PRE_Y					= 'b10110100;
	localparam								PRE_Z					= 'b10011100;
	//
	logic				[SR_W-1:0]			R_sr[0:UNITS-1];
	logic				[SR_W-1:0]			L_sr[0:UNITS-1];
	// deconstructed master counter
	logic				[FRAME_W-1:0]		frame_count;	// frame index
	logic										sub_frame;		// sub frame
	logic				[BIT_W-1:0]			bit_count;		// bit index
	logic										sub_bit;			// sub bit
	//
	logic										load_f, done_f, en_f;
	logic										parity[0:UNITS-1];
	logic										spdif_tx[0:UNITS-1];
	//
	genvar									g;


	/*
	================
	== code start ==
	================
	*/


	// register input
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			en_f <= 0;
		end else begin
			en_f <= en_i;
		end
	end

	// form the master up-counter
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			{ frame_count, sub_frame, bit_count, sub_bit } <= 0;
		end else begin
			if ( en_f ) begin  // prescale
				if ( done_f ) begin
					{ frame_count, sub_frame, bit_count, sub_bit } <= 0;
				end else begin
					{ frame_count, sub_frame, bit_count, sub_bit } <= { frame_count, sub_frame, bit_count, sub_bit } + 1'b1;
				end
			end
		end
	end

	// decode flags
	always_comb done_f = ( { frame_count, sub_frame, bit_count, sub_bit } == { FRAME_W'(191), 1'b1, BIT_W'(31), 1'b1 } );
	
	// decode & register flag (speed-up)
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			load_f <= 0;
		end else begin
			if ( en_f ) begin  // prescale
				load_f <= ( { sub_frame, bit_count, sub_bit } == { 1'b1, BIT_W'(31), 1'b0 } );
			end
		end
	end


	generate
		for ( g=0; g<UNITS; g=g+1 ) begin : unit_loop
		
			// load inputs, decode output
			always_ff @ ( posedge clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					L_sr[g] <= 0;
					R_sr[g] <= 0;
					parity[g] <= 0;
					spdif_tx[g] <= 0;
				end else begin
					if ( en_f ) begin  // prescale
						if ( load_f ) begin  // LOAD
							L_sr[g][SR_W-1:PRE_W] <= pcm_L_i[g];
							R_sr[g][SR_W-1:PRE_W] <= pcm_R_i[g];
							//
							L_sr[g][PRE_W-1:0] <= ( frame_count == 191 ) ? PRE_W'( PRE_Z ) : PRE_W'( PRE_X );
							R_sr[g][PRE_W-1:0] <= PRE_W'( PRE_Y );
						end
						//
						if ( bit_count < 4 ) begin  // PREAMBLE
							parity[g] <= 0;
							if ( ~sub_frame ) begin  // left
								spdif_tx[g] <= spdif_tx[g] ^ L_sr[g][0];
								L_sr[g] <= L_sr[g][SR_W-1:1];
							end else begin  // right
								spdif_tx[g] <= spdif_tx[g] ^ R_sr[g][0];
								R_sr[g] <= R_sr[g][SR_W-1:1];
							end
						end else if ( bit_count < 28 ) begin  // PCM
							if ( sub_bit ) begin  // bit boundary
								spdif_tx[g] <= ~spdif_tx[g];
							end else begin	 // inside bit
								if ( ~sub_frame ) begin  // left
									spdif_tx[g] <= spdif_tx[g] ^ L_sr[g][0];
									parity[g] <= parity[g] ^ L_sr[g][0];
									L_sr[g] <= L_sr[g][SR_W-1:1];
								end else begin  // right
									spdif_tx[g] <= spdif_tx[g] ^ R_sr[g][0];
									parity[g] <= parity[g] ^ R_sr[g][0];
									R_sr[g] <= R_sr[g][SR_W-1:1];
								end
							end
						end else begin  // OVERHEAD BS
							if ( sub_bit ) begin  // bit boundary
								spdif_tx[g] <= ~spdif_tx[g];
							end else begin	 // inside bit
								if ( bit_count == 30 ) begin  // channel status bit
									if ( frame_count == 2 ) begin  // copyright bit
										spdif_tx [g]<= spdif_tx[g] ^ 1'( COPY_OK );
										parity[g] <= parity[g] ^ 1'( COPY_OK );
									end else if ( frame_count == 'd25 ) begin  // Fs bit
										spdif_tx[g] <= spdif_tx[g] ^ 1'( FS_44K1 );
										parity[g] <= parity[g] ^ 1'( FS_44K1 );
									end
								end else if ( bit_count == 31 ) begin  // parity bit
									spdif_tx[g] <= spdif_tx[g] ^ parity[g];
								end
							end
						end
					end
				end
			end
			
			// register outputs
			always_ff @ ( posedge clk_i or posedge rst_i ) begin
				if ( rst_i ) begin
					spdif_tx_o[g] <= 0;
				end else begin
					spdif_tx_o[g] <= spdif_tx[g];
				end
			end
			
		end  // endfor
	endgenerate

	// decode and register output
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			pcm_rd_o <= 0;
		end else begin
			pcm_rd_o <= load_f && en_f;
		end
	end

endmodule
