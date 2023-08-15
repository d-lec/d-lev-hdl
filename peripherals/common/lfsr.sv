/*
--------------------------------------------------------------------------------

Module: lfsr.sv

Function: 
- Linear Feedback Shift Register pseudo random bit / vector generator.

Instantiates: 
- Nothing.

Notes:
- Parameterized linear feedback shift register width (auto taps): 3 to 168.
- Parameterized sequence length:
- If FULL_SEQ = 1 then the sequence length is 2^LFSR_W and all shift register
  states are represented with no lockup states possible.
- If FULL_SEQ = 0 then the sequence length is (2^LFSR_W)-1 and the all ones state 
  is missing.
- Feedback taps obtained from Xilinx publication "xapp052.pdf"

--------------------------------------------------------------------------------
*/

module lfsr
	#(
	parameter										LFSR_W				= 4,	// shift register width, 3 to 168
	parameter										FULL_SEQ				= 1	// sequence length: 1:2^LFSR_W; 0:(2^LFSR_W)-1
	)
	(
	// clocks & resets
	input		logic									clk_i,						// clock
	input		logic									rst_i,						// async reset, active hi
	// I/O
	input		logic									en_i,							// enable, active hi
	output	logic				[LFSR_W-1:0]	vect_o,						// full vector output
	output	logic									bit_o							// bit output
	);


	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	logic												fb;
	logic												fb_m;



	/*
	================
	== code start ==
	================
	*/


	// select feeback taps based on shift register length & xor them
	always_comb begin
		unique casex ( LFSR_W )
			  3 : fb = vect_o[2] ^ vect_o[1];
			  4 : fb = vect_o[3] ^ vect_o[2];
			  5 : fb = vect_o[4] ^ vect_o[2];
			  6 : fb = vect_o[5] ^ vect_o[4];
			  7 : fb = vect_o[6] ^ vect_o[5];
			  8 : fb = vect_o[7] ^ vect_o[5] ^ vect_o[4] ^ vect_o[3];  
			  9 : fb = vect_o[8] ^ vect_o[4];
			 10 : fb = vect_o[9] ^ vect_o[6];
			 11 : fb = vect_o[10] ^ vect_o[8];
			 12 : fb = vect_o[11] ^ vect_o[5] ^ vect_o[3] ^ vect_o[0];
			 13 : fb = vect_o[12] ^ vect_o[3] ^ vect_o[2] ^ vect_o[0];
			 14 : fb = vect_o[13] ^ vect_o[4] ^ vect_o[2] ^ vect_o[0];
			 15 : fb = vect_o[14] ^ vect_o[13];
			 16 : fb = vect_o[15] ^ vect_o[14] ^ vect_o[12] ^ vect_o[3];
			 17 : fb = vect_o[16] ^ vect_o[13];
			 18 : fb = vect_o[17] ^ vect_o[10];
			 19 : fb = vect_o[18] ^ vect_o[5] ^ vect_o[1] ^ vect_o[0];
			 20 : fb = vect_o[19] ^ vect_o[16];
			 21 : fb = vect_o[20] ^ vect_o[18];
			 22 : fb = vect_o[21] ^ vect_o[20];
			 23 : fb = vect_o[22] ^ vect_o[17];
			 24 : fb = vect_o[23] ^ vect_o[22] ^ vect_o[21] ^ vect_o[16];
			 25 : fb = vect_o[24] ^ vect_o[21];
			 26 : fb = vect_o[25] ^ vect_o[5] ^ vect_o[1] ^ vect_o[0];
			 27 : fb = vect_o[26] ^ vect_o[4] ^ vect_o[1] ^ vect_o[0];
			 28 : fb = vect_o[27] ^ vect_o[24];
			 29 : fb = vect_o[28] ^ vect_o[26];
			 30 : fb = vect_o[29] ^ vect_o[5] ^ vect_o[3] ^ vect_o[0];
			 31 : fb = vect_o[30] ^ vect_o[27];
			 32 : fb = vect_o[31] ^ vect_o[21] ^ vect_o[1] ^ vect_o[0];
			 33 : fb = vect_o[32] ^ vect_o[19];
			 34 : fb = vect_o[33] ^ vect_o[26] ^ vect_o[1] ^ vect_o[0];
			 35 : fb = vect_o[34] ^ vect_o[32];
			 36 : fb = vect_o[35] ^ vect_o[24];
			 37 : fb = vect_o[36] ^ vect_o[4] ^ vect_o[3] ^ vect_o[2] ^ vect_o[1] ^ vect_o[0];
			 38 : fb = vect_o[37] ^ vect_o[5] ^ vect_o[4] ^ vect_o[0];
			 39 : fb = vect_o[38] ^ vect_o[34];
			 40 : fb = vect_o[39] ^ vect_o[37] ^ vect_o[20] ^ vect_o[18];
			 41 : fb = vect_o[40] ^ vect_o[37];
			 42 : fb = vect_o[41] ^ vect_o[40] ^ vect_o[19] ^ vect_o[18];
			 43 : fb = vect_o[42] ^ vect_o[41] ^ vect_o[37] ^ vect_o[36];
			 44 : fb = vect_o[43] ^ vect_o[42] ^ vect_o[17] ^ vect_o[16];
			 45 : fb = vect_o[44] ^ vect_o[43] ^ vect_o[41] ^ vect_o[40];
			 46 : fb = vect_o[45] ^ vect_o[44] ^ vect_o[25] ^ vect_o[24];
			 47 : fb = vect_o[46] ^ vect_o[41];
			 48 : fb = vect_o[47] ^ vect_o[46] ^ vect_o[20] ^ vect_o[19];
			 49 : fb = vect_o[48] ^ vect_o[39];
			 50 : fb = vect_o[49] ^ vect_o[48] ^ vect_o[23] ^ vect_o[22];
			 51 : fb = vect_o[50] ^ vect_o[49] ^ vect_o[35] ^ vect_o[34];
			 52 : fb = vect_o[51] ^ vect_o[48];
			 53 : fb = vect_o[52] ^ vect_o[51] ^ vect_o[37] ^ vect_o[36];
			 54 : fb = vect_o[53] ^ vect_o[52] ^ vect_o[17] ^ vect_o[16];
			 55 : fb = vect_o[54] ^ vect_o[30];
			 56 : fb = vect_o[55] ^ vect_o[54] ^ vect_o[34] ^ vect_o[33];
			 57 : fb = vect_o[56] ^ vect_o[49];
			 58 : fb = vect_o[57] ^ vect_o[38];
			 59 : fb = vect_o[58] ^ vect_o[57] ^ vect_o[37] ^ vect_o[36];
			 60 : fb = vect_o[59] ^ vect_o[58];
			 61 : fb = vect_o[60] ^ vect_o[59] ^ vect_o[45] ^ vect_o[44];
			 62 : fb = vect_o[61] ^ vect_o[60] ^ vect_o[5] ^ vect_o[4];
			 63 : fb = vect_o[62] ^ vect_o[61];
			 64 : fb = vect_o[63] ^ vect_o[62] ^ vect_o[60] ^ vect_o[59];
			 65 : fb = vect_o[64] ^ vect_o[46];
			 66 : fb = vect_o[65] ^ vect_o[64] ^ vect_o[56] ^ vect_o[55];
			 67 : fb = vect_o[66] ^ vect_o[65] ^ vect_o[57] ^ vect_o[56];
			 68 : fb = vect_o[67] ^ vect_o[58];
			 69 : fb = vect_o[68] ^ vect_o[66] ^ vect_o[41] ^ vect_o[39];
			 70 : fb = vect_o[69] ^ vect_o[68] ^ vect_o[54] ^ vect_o[53];
			 71 : fb = vect_o[70] ^ vect_o[64];
			 72 : fb = vect_o[71] ^ vect_o[65] ^ vect_o[24] ^ vect_o[18];
			 73 : fb = vect_o[72] ^ vect_o[47];
			 74 : fb = vect_o[73] ^ vect_o[72] ^ vect_o[58] ^ vect_o[57];
			 75 : fb = vect_o[74] ^ vect_o[73] ^ vect_o[64] ^ vect_o[63];
			 76 : fb = vect_o[75] ^ vect_o[74] ^ vect_o[40] ^ vect_o[39];
			 77 : fb = vect_o[76] ^ vect_o[75] ^ vect_o[46] ^ vect_o[45];
			 78 : fb = vect_o[77] ^ vect_o[76] ^ vect_o[58] ^ vect_o[57];
			 79 : fb = vect_o[78] ^ vect_o[69];
		 	 80 : fb = vect_o[79] ^ vect_o[78] ^ vect_o[42] ^ vect_o[41];
			 81 : fb = vect_o[80] ^ vect_o[76];
			 82 : fb = vect_o[81] ^ vect_o[78] ^ vect_o[46] ^ vect_o[43];
			 83 : fb = vect_o[82] ^ vect_o[81] ^ vect_o[37] ^ vect_o[36];
			 84 : fb = vect_o[83] ^ vect_o[70];
			 85 : fb = vect_o[84] ^ vect_o[83] ^ vect_o[57] ^ vect_o[56];
			 86 : fb = vect_o[85] ^ vect_o[84] ^ vect_o[73] ^ vect_o[72];
			 87 : fb = vect_o[86] ^ vect_o[73];
			 88 : fb = vect_o[87] ^ vect_o[86] ^ vect_o[16] ^ vect_o[15];
			 89 : fb = vect_o[88] ^ vect_o[50];
			 90 : fb = vect_o[89] ^ vect_o[88] ^ vect_o[71] ^ vect_o[70];
			 91 : fb = vect_o[90] ^ vect_o[89] ^ vect_o[7] ^ vect_o[6];
			 92 : fb = vect_o[91] ^ vect_o[90] ^ vect_o[79] ^ vect_o[78];
			 93 : fb = vect_o[92] ^ vect_o[90];
			 94 : fb = vect_o[93] ^ vect_o[72];
			 95 : fb = vect_o[94] ^ vect_o[83];
			 96 : fb = vect_o[95] ^ vect_o[93] ^ vect_o[48] ^ vect_o[46];
			 97 : fb = vect_o[96] ^ vect_o[90];
			 98 : fb = vect_o[97] ^ vect_o[86];
			 99 : fb = vect_o[98] ^ vect_o[96] ^ vect_o[53] ^ vect_o[51];
			100 : fb = vect_o[99] ^ vect_o[62];
			101 : fb = vect_o[100] ^ vect_o[99] ^ vect_o[94] ^ vect_o[93];
			102 : fb = vect_o[101] ^ vect_o[100] ^ vect_o[35] ^ vect_o[34];
			103 : fb = vect_o[102] ^ vect_o[93];
			104 : fb = vect_o[103] ^ vect_o[102] ^ vect_o[93] ^ vect_o[92];
			105 : fb = vect_o[104] ^ vect_o[88];
			106 : fb = vect_o[105] ^ vect_o[90];
			107 : fb = vect_o[106] ^ vect_o[104] ^ vect_o[43] ^ vect_o[41];
			108 : fb = vect_o[107] ^ vect_o[76];
			109 : fb = vect_o[108] ^ vect_o[107] ^ vect_o[102] ^ vect_o[101];
			110 : fb = vect_o[109] ^ vect_o[108] ^ vect_o[97] ^ vect_o[96];
			111 : fb = vect_o[110] ^ vect_o[100];
			112 : fb = vect_o[111] ^ vect_o[109] ^ vect_o[68] ^ vect_o[66];
			113 : fb = vect_o[112] ^ vect_o[103];
			114 : fb = vect_o[113] ^ vect_o[112] ^ vect_o[32] ^ vect_o[31];
			115 : fb = vect_o[114] ^ vect_o[113] ^ vect_o[100] ^ vect_o[99];
			116 : fb = vect_o[115] ^ vect_o[114] ^ vect_o[45] ^ vect_o[44];
			117 : fb = vect_o[116] ^ vect_o[114] ^ vect_o[98] ^ vect_o[96];
			118 : fb = vect_o[117] ^ vect_o[84];
			119 : fb = vect_o[118] ^ vect_o[110];
			120 : fb = vect_o[119] ^ vect_o[112] ^ vect_o[8] ^ vect_o[1];
			121 : fb = vect_o[120] ^ vect_o[102];
			122 : fb = vect_o[121] ^ vect_o[120] ^ vect_o[62] ^ vect_o[61];
			123 : fb = vect_o[122] ^ vect_o[120];
			124 : fb = vect_o[123] ^ vect_o[86];
			125 : fb = vect_o[124] ^ vect_o[123] ^ vect_o[17] ^ vect_o[16];
			126 : fb = vect_o[125] ^ vect_o[124] ^ vect_o[89] ^ vect_o[88];
			127 : fb = vect_o[126] ^ vect_o[125];
			128 : fb = vect_o[127] ^ vect_o[125] ^ vect_o[100] ^ vect_o[98];
			129 : fb = vect_o[128] ^ vect_o[123];
			130 : fb = vect_o[129] ^ vect_o[126];
			131 : fb = vect_o[130] ^ vect_o[129] ^ vect_o[83] ^ vect_o[82];
			132 : fb = vect_o[131] ^ vect_o[102];
			133 : fb = vect_o[132] ^ vect_o[131] ^ vect_o[81] ^ vect_o[80];
			134 : fb = vect_o[133] ^ vect_o[76];
			135 : fb = vect_o[134] ^ vect_o[123];
			136 : fb = vect_o[135] ^ vect_o[134] ^ vect_o[10] ^ vect_o[9];
			137 : fb = vect_o[136] ^ vect_o[115];
			138 : fb = vect_o[137] ^ vect_o[136] ^ vect_o[130] ^ vect_o[129];
			139 : fb = vect_o[138] ^ vect_o[135] ^ vect_o[133] ^ vect_o[130];
			140 : fb = vect_o[139] ^ vect_o[110];
			141 : fb = vect_o[140] ^ vect_o[139] ^ vect_o[109] ^ vect_o[108];
			142 : fb = vect_o[141] ^ vect_o[120];
			143 : fb = vect_o[142] ^ vect_o[141] ^ vect_o[122] ^ vect_o[121];
			144 : fb = vect_o[143] ^ vect_o[142] ^ vect_o[74] ^ vect_o[73];
			145 : fb = vect_o[144] ^ vect_o[92];
			146 : fb = vect_o[145] ^ vect_o[144] ^ vect_o[86] ^ vect_o[85];
			147 : fb = vect_o[146] ^ vect_o[145] ^ vect_o[109] ^ vect_o[108];
			148 : fb = vect_o[147] ^ vect_o[120];
			149 : fb = vect_o[148] ^ vect_o[147] ^ vect_o[39] ^ vect_o[38];
			150 : fb = vect_o[149] ^ vect_o[96];
			151 : fb = vect_o[150] ^ vect_o[147];
			152 : fb = vect_o[151] ^ vect_o[150] ^ vect_o[86] ^ vect_o[85];
			153 : fb = vect_o[152] ^ vect_o[151];
			154 : fb = vect_o[153] ^ vect_o[151] ^ vect_o[26] ^ vect_o[24];
			155 : fb = vect_o[154] ^ vect_o[153] ^ vect_o[123] ^ vect_o[122];
			156 : fb = vect_o[155] ^ vect_o[154] ^ vect_o[40] ^ vect_o[39];
			157 : fb = vect_o[156] ^ vect_o[155] ^ vect_o[130] ^ vect_o[129];
			158 : fb = vect_o[157] ^ vect_o[156] ^ vect_o[131] ^ vect_o[130];
			159 : fb = vect_o[158] ^ vect_o[127];
			160 : fb = vect_o[159] ^ vect_o[158] ^ vect_o[141] ^ vect_o[140];
			161 : fb = vect_o[160] ^ vect_o[142];
			162 : fb = vect_o[161] ^ vect_o[160] ^ vect_o[74] ^ vect_o[73];
			163 : fb = vect_o[162] ^ vect_o[161] ^ vect_o[103] ^ vect_o[102];
			164 : fb = vect_o[163] ^ vect_o[162] ^ vect_o[150] ^ vect_o[149];
			165 : fb = vect_o[164] ^ vect_o[163] ^ vect_o[134] ^ vect_o[133];
			166 : fb = vect_o[165] ^ vect_o[164] ^ vect_o[127] ^ vect_o[126];
			167 : fb = vect_o[166] ^ vect_o[160];
			168 : fb = vect_o[167] ^ vect_o[165] ^ vect_o[152] ^ vect_o[150];
			default : fb = 1'b1;
		endcase
	end

	// select feedback based on sequence length
	always_comb fb_m = ( FULL_SEQ ) ? ~fb ^ &vect_o[LFSR_W-2:0] : ~fb;

	// shift when enabled
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			vect_o <= 0;
		end else begin
			if ( en_i ) begin
				vect_o <= LFSR_W'( { vect_o, fb_m } );
			end
		end
	end

	// single bit output
	always_comb bit_o = vect_o[0];


endmodule
