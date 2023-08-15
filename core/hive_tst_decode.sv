/*
--------------------------------------------------------------------------------

Module : hive_tst_decode.sv

--------------------------------------------------------------------------------

Function:
- Processor test decoding for conditional jumps, etc.

Instantiates:
- (2x) pipe.sv

Dependencies:
- hive_pkg.sv

Notes:
- I/O registered.

--------------------------------------------------------------------------------
*/

module hive_tst_decode
	(
	// clocks & resets
	input			logic								clk_i,						// clock
	input			logic								rst_i,						// async. reset, active high
	// test inputs
	input			logic	[ALU_W-1:0]				a_i,							// operand
	input			logic	[ALU_W-1:0]				b_i,							// operand
	// tests
	input			logic								cnd_i,						// 1=conditional
	input			TST_T								tst_i,						// test field
	// output
	output		logic								res_3_o						// 1=true; 0=false
	);

	
	/*
	----------------------
	-- internal signals --
	----------------------
	*/
	import hive_params::*;
	import hive_types::*;
	//
	logic					[ALU_W-1:0]				a_1, b_1;
	logic												flg_nz_2, flg_lz_2, flg_o_2, flg_ne_2, flg_ls_2, flg_lu_2;
	logic												cnd_1, cnd_2;
	TST_T												tst_1, tst_2;
	logic												res_2;
	


	/*
	================
	== code start ==
	================
	*/


	// register inputs
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			a_1 <= 0;
			b_1 <= 0;
			cnd_1 <= 0;
			tst_1 <= TST_T'( 'x );
		end else begin
			a_1 <= a_i;
			b_1 <= b_i;
			cnd_1 <= cnd_i;
			tst_1 <= tst_i;
		end
	end
	
	// decode & reg mid results
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			flg_nz_2 <= 0;
			flg_lz_2 <= 0;
			flg_o_2  <= 0;
			flg_ne_2 <= 0;
			flg_ls_2 <= 0;
			flg_lu_2 <= 0;
			cnd_2 <= 0;
			tst_2 <= TST_T'( 'x );
		end else begin
			flg_nz_2 <= |a_1;
			flg_lz_2 <= a_1[ALU_W-1];
			flg_o_2  <= a_1[0];
			flg_ne_2 <= ( a_1 != b_1 );
			flg_ls_2 <= $signed( a_1 ) < $signed( b_1 );
			flg_lu_2 <= a_1 < b_1;
			cnd_2 <= cnd_1;
			tst_2 <= tst_1;
		end
	end

	// mux
	always_comb begin
		unique case ( tst_2 )
			tst_z   : res_2 <= ~flg_nz_2;
			tst_nz  : res_2 <=  flg_nz_2;
			tst_lz  : res_2 <=  flg_lz_2;
			tst_nlz : res_2 <= ~flg_lz_2;
			tst_o   : res_2 <=  flg_o_2;
			tst_no  : res_2 <= ~flg_o_2;
			tst_e   : res_2 <= ~flg_ne_2;
			tst_ne  : res_2 <=  flg_ne_2;
			tst_ls  : res_2 <=  flg_ls_2;
			tst_nls : res_2 <= ~flg_ls_2;
			tst_lu  : res_2 <=  flg_lu_2;
			tst_nlu : res_2 <= ~flg_lu_2;
			default : res_2 <= 1'b1;  // benign default
		endcase
	end

	// decode & register output
	always_ff @ ( posedge clk_i or posedge rst_i ) begin
		if ( rst_i ) begin
			res_3_o <= 0;
		end else begin
			res_3_o <= ( cnd_2 ) ? res_2 : 1'b1;
		end
	end

endmodule
