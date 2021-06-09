////////////////////////////////////////////////////////////////////////////////
//
// Filename:	fftstage.v
// {{{
// Project:	A General Purpose Pipelined FFT Implementation
//
// Purpose:	This file is (almost) a Verilog source file.  It is meant to
//		be used by a FFT core compiler to generate FFTs which may be
//	used as part of an FFT core.  Specifically, this file encapsulates
//	the options of an FFT-stage.  For any 2^N length FFT, there shall be
//	(N-1) of these stages.
//
//
// Operation:
// 	Given a stream of values, operate upon them as though they were
// 	value pairs, x[n] and x[n+N/2].  The stream begins when n=0, and ends
// 	when n=N/2-1 (i.e. there's a full set of N values).  When the value
// 	x[0] enters, the synchronization input, i_sync, must be true as well.
//
// 	For this stream, produce outputs
// 	y[n    ] = x[n] + x[n+N/2], and
// 	y[n+N/2] = (x[n] - x[n+N/2]) * c[n],
// 			where c[n] is a complex coefficient found in the
// 			external memory file COEFFILE.
// 	When y[0] is output, a synchronization bit o_sync will be true as
// 	well, otherwise it will be zero.
//
// 	Most of the work to do this is done within the butterfly, whether the
// 	hardware accelerated butterfly (uses a DSP) or not.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2015-2021, Gisselquist Technology, LLC
// {{{
// This file is part of the general purpose pipelined FFT project.
//
// The pipelined FFT project is free software (firmware): you can redistribute
// it and/or modify it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// The pipelined FFT project is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
// General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  (It's in the $(ROOT)/doc directory.  Run make
// with no target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
// }}}
// License:	LGPL, v3, as defined and found on www.gnu.org,
// {{{
//		http://www.gnu.org/licenses/lgpl.html
//
// }}}
////////////////////////////////////////////////////////////////////////////////
//
//
`default_nettype	none
//
module	fftstage #(
		// {{{
		parameter	IWIDTH=16,CWIDTH=20,OWIDTH=17,
		// Parameters specific to the core that should be changed when
		// this core is built ... Note that the minimum LGSPAN (the base
		// two log of the span, or the base two log of the current FFT
		// size) is 3.  Smaller spans (i.e. the span of 2) must use the
		// dbl laststage module.
		// Verilator lint_off UNUSED
		parameter	LGSPAN=7, BFLYSHIFT=0, // LGWIDTH=8
		parameter [0:0]	OPT_HWMPY = 1,
		// Clocks per CE.  If your incoming data rate is less than 50%
		// of your clock speed, you can set CKPCE to 2'b10, make sure
		// there's at least one clock between cycles when i_ce is high,
		// and then use two multiplies instead of three.  Setting CKPCE
		// to 2'b11, and insisting on at least two clocks with i_ce low
		// between cycles with i_ce high, then the hardware optimized
		// butterfly code will used one multiply instead of two.
		parameter	CKPCE = 1,
		// The COEFFILE parameter contains the name of the file
		// containing the FFT twiddle factors
		parameter	COEFFILE="cmem_256.hex"
		// Verilator lint_on  UNUSED

// `ifdef	VERILATOR
		// parameter  [0:0]	ZERO_ON_IDLE = 1'b0
// `else
		// localparam [0:0]	ZERO_ON_IDLE = 1'b0
// `endif // VERILATOR
		// }}}
	) (
		// {{{
		input	wire				i_clk, i_reset,
							i_ce, i_sync,
		input	wire	[(2*IWIDTH-1):0]	i_data,
		output	reg	[(2*OWIDTH-1):0]	o_data,
		output	reg				o_sync

		// }}}
	);
		localparam [0:0]	ZERO_ON_IDLE = 1'b0;

	// Local signal definitions
	// {{{
	// I am using the prefixes
	// 	ib_*	to reference the inputs to the butterfly, and
	// 	ob_*	to reference the outputs from the butterfly
	reg	wait_for_sync;
	reg	[(2*IWIDTH-1):0]	ib_a, ib_b;
	reg	[(2*CWIDTH-1):0]	ib_c;
	reg	ib_sync;

	reg	b_started;
	wire	ob_sync;
	wire	[(2*OWIDTH-1):0]	ob_a, ob_b;

	// cmem is defined as an array of real and complex values,
	// where the top CWIDTH bits are the real value and the bottom
	// CWIDTH bits are the imaginary value.
	//
	// cmem[i] = { (2^(CWIDTH-2)) * cos(2*pi*i/(2^LGWIDTH)),
	//		(2^(CWIDTH-2)) * sin(2*pi*i/(2^LGWIDTH)) };
	//
	// reg	[(2*CWIDTH-1):0]	cmem [0:((1<<LGSPAN)-1)];
    reg	[(2*CWIDTH-1):0]	cmem;
	reg	[(LGSPAN):0]		iaddr;
`ifdef	FORMAL
// Let the formal tool pick the coefficients
`else
	// initial	$readmemh(COEFFILE,cmem);
    generate
    if (COEFFILE == "cmem_256.hex") begin
        always @(*) begin
            case (iaddr[(LGSPAN-1):0])
                0   : cmem = 40'h4000000000;
                1   : cmem = 40'h3ffb1fe6df;
                2   : cmem = 40'h3fec4fcdc1;
                3   : cmem = 40'h3fd3afb4ab;
                4   : cmem = 40'h3fb12f9ba1;
                5   : cmem = 40'h3f84df82a7;
                6   : cmem = 40'h3f4ebf69bf;
                7   : cmem = 40'h3f0edf50ef;
                8   : cmem = 40'h3ec53f383a;
                9   : cmem = 40'h3e71ef1fa4;
                10  : cmem = 40'h3e150f0730;
                11  : cmem = 40'h3dae8eeee3;
                12  : cmem = 40'h3d3e8ed6c0;
                13  : cmem = 40'h3cc51ebeca;
                14  : cmem = 40'h3c424ea706;
                15  : cmem = 40'h3bb62e8f78;
                16  : cmem = 40'h3b20de7822;
                17  : cmem = 40'h3a827e6108;
                18  : cmem = 40'h39dafe4a2f;
                19  : cmem = 40'h392a9e3399;
                20  : cmem = 40'h38716e1d4a;
                21  : cmem = 40'h37af8e0746;
                22  : cmem = 40'h36e50df18f;
                23  : cmem = 40'h36121ddc2a;
                24  : cmem = 40'h3536ddc719;
                25  : cmem = 40'h34535db25f;
                26  : cmem = 40'h3367cd9e01;
                27  : cmem = 40'h32744d8a01;
                28  : cmem = 40'h31790d7662;
                29  : cmem = 40'h30762d6327;
                30  : cmem = 40'h2f6bcd5053;
                31  : cmem = 40'h2e5a1d3de9;
                32  : cmem = 40'h2d414d2bec;
                33  : cmem = 40'h2c217d1a5f;
                34  : cmem = 40'h2afadd0944;
                35  : cmem = 40'h29cd9cf89e;
                36  : cmem = 40'h2899ece870;
                37  : cmem = 40'h275ffcd8bc;
                38  : cmem = 40'h261ffcc984;
                39  : cmem = 40'h24da1cbacb;
                40  : cmem = 40'h238e7cac93;
                41  : cmem = 40'h223d6c9edf;
                42  : cmem = 40'h20e71c91b0;
                43  : cmem = 40'h1f8bac8508;
                44  : cmem = 40'h1e2b6c78ea;
                45  : cmem = 40'h1cc67c6d57;
                46  : cmem = 40'h1b5d1c6251;
                47  : cmem = 40'h19ef8c57d9;
                48  : cmem = 40'h187dec4df3;
                49  : cmem = 40'h17088c449e;
                50  : cmem = 40'h158fac3bdc;
                51  : cmem = 40'h14136c33af;
                52  : cmem = 40'h12940c2c18;
                53  : cmem = 40'h1111dc2518;
                54  : cmem = 40'h0f8d0c1eb0;
                55  : cmem = 40'h0e05cc18e2;
                56  : cmem = 40'h0c7c6c13ad;
                57  : cmem = 40'h0af11c0f13;
                58  : cmem = 40'h09641c0b15;
                59  : cmem = 40'h07d59c07b3;
                60  : cmem = 40'h0645fc04ee;
                61  : cmem = 40'h04b55c02c6;
                62  : cmem = 40'h0323fc013c;
                63  : cmem = 40'h01921c004f;
                64  : cmem = 40'h00000c0000;
                65  : cmem = 40'hfe6dfc004f;
                66  : cmem = 40'hfcdc1c013c;
                67  : cmem = 40'hfb4abc02c6;
                68  : cmem = 40'hf9ba1c04ee;
                69  : cmem = 40'hf82a7c07b3;
                70  : cmem = 40'hf69bfc0b15;
                71  : cmem = 40'hf50efc0f13;
                72  : cmem = 40'hf383ac13ad;
                73  : cmem = 40'hf1fa4c18e2;
                74  : cmem = 40'hf0730c1eb0;
                75  : cmem = 40'heeee3c2518;
                76  : cmem = 40'hed6c0c2c18;
                77  : cmem = 40'hebecac33af;
                78  : cmem = 40'hea706c3bdc;
                79  : cmem = 40'he8f78c449e;
                80  : cmem = 40'he7822c4df3;
                81  : cmem = 40'he6108c57d9;
                82  : cmem = 40'he4a2fc6251;
                83  : cmem = 40'he3399c6d57;
                84  : cmem = 40'he1d4ac78ea;
                85  : cmem = 40'he0746c8508;
                86  : cmem = 40'hdf18fc91b0;
                87  : cmem = 40'hddc2ac9edf;
                88  : cmem = 40'hdc719cac93;
                89  : cmem = 40'hdb25fcbacb;
                90  : cmem = 40'hd9e01cc984;
                91  : cmem = 40'hd8a01cd8bc;
                92  : cmem = 40'hd7662ce870;
                93  : cmem = 40'hd6327cf89e;
                94  : cmem = 40'hd5053d0944;
                95  : cmem = 40'hd3de9d1a5f;
                96  : cmem = 40'hd2becd2bec;
                97  : cmem = 40'hd1a5fd3de9;
                98  : cmem = 40'hd0944d5053;
                99  : cmem = 40'hcf89ed6327;
                100 : cmem = 40'hce870d7662;
                101 : cmem = 40'hcd8bcd8a01;
                102 : cmem = 40'hcc984d9e01;
                103 : cmem = 40'hcbacbdb25f;
                104 : cmem = 40'hcac93dc719;
                105 : cmem = 40'hc9edfddc2a;
                106 : cmem = 40'hc91b0df18f;
                107 : cmem = 40'hc8508e0746;
                108 : cmem = 40'hc78eae1d4a;
                109 : cmem = 40'hc6d57e3399;
                110 : cmem = 40'hc6251e4a2f;
                111 : cmem = 40'hc57d9e6108;
                112 : cmem = 40'hc4df3e7822;
                113 : cmem = 40'hc449ee8f78;
                114 : cmem = 40'hc3bdcea706;
                115 : cmem = 40'hc33afebeca;
                116 : cmem = 40'hc2c18ed6c0;
                117 : cmem = 40'hc2518eeee3;
                118 : cmem = 40'hc1eb0f0730;
                119 : cmem = 40'hc18e2f1fa4;
                120 : cmem = 40'hc13adf383a;
                121 : cmem = 40'hc0f13f50ef;
                122 : cmem = 40'hc0b15f69bf;
                123 : cmem = 40'hc07b3f82a7;
                124 : cmem = 40'hc04eef9ba1;
                125 : cmem = 40'hc02c6fb4ab;
                126 : cmem = 40'hc013cfcdc1;
                127 : cmem = 40'hc004ffe6df;
            endcase
        end
    end else if (COEFFILE == "cmem_128.hex") begin
        always @(*) begin
            case (iaddr[(LGSPAN-1):0])
                0   : cmem = 42'h10000000000;
                1   : cmem = 42'h0ffb11f9b82;
                2   : cmem = 42'h0fec47f3743;
                3   : cmem = 42'h0fd3abed37f;
                4   : cmem = 42'h0fb14de7074;
                5   : cmem = 42'h0f8541e0e60;
                6   : cmem = 42'h0f4fa1dad7f;
                7   : cmem = 42'h0f1091d4e0d;
                8   : cmem = 42'h0ec837cf044;
                9   : cmem = 42'h0e76bfc945e;
                10  : cmem = 42'h0e1c5bc3a94;
                11  : cmem = 42'h0db943be31e;
                12  : cmem = 42'h0d4db5b8e31;
                13  : cmem = 42'h0cd9f1b3c02;
                14  : cmem = 42'h0c5e41aecc3;
                15  : cmem = 42'h0bdaf1aa0a6;
                16  : cmem = 42'h0b5051a57d8;
                17  : cmem = 42'h0abeb5a1288;
                18  : cmem = 42'h0a267b9d0e0;
                19  : cmem = 42'h0987fd99308;
                20  : cmem = 42'h08e39f95926;
                21  : cmem = 42'h0839c59235f;
                22  : cmem = 42'h078ad98f1d3;
                23  : cmem = 42'h06d7458c4a1;
                24  : cmem = 42'h061f7989be5;
                25  : cmem = 42'h0563e7877b8;
                26  : cmem = 42'h04a50385830;
                27  : cmem = 42'h03e34183d60;
                28  : cmem = 42'h031f198275a;
                29  : cmem = 42'h0259038162b;
                30  : cmem = 42'h01917b809dd;
                31  : cmem = 42'h00c8fd80278;
                32  : cmem = 42'h00000180000;
                33  : cmem = 42'h3f370580278;
                34  : cmem = 42'h3e6e87809dd;
                35  : cmem = 42'h3da6ff8162b;
                36  : cmem = 42'h3ce0e98275a;
                37  : cmem = 42'h3c1cc183d60;
                38  : cmem = 42'h3b5aff85830;
                39  : cmem = 42'h3a9c1b877b8;
                40  : cmem = 42'h39e08989be5;
                41  : cmem = 42'h3928bd8c4a1;
                42  : cmem = 42'h3875298f1d3;
                43  : cmem = 42'h37c63d9235f;
                44  : cmem = 42'h371c6395926;
                45  : cmem = 42'h36780599308;
                46  : cmem = 42'h35d9879d0e0;
                47  : cmem = 42'h35414da1288;
                48  : cmem = 42'h34afb1a57d8;
                49  : cmem = 42'h342511aa0a6;
                50  : cmem = 42'h33a1c1aecc3;
                51  : cmem = 42'h332611b3c02;
                52  : cmem = 42'h32b24db8e31;
                53  : cmem = 42'h3246bfbe31e;
                54  : cmem = 42'h31e3a7c3a94;
                55  : cmem = 42'h318943c945e;
                56  : cmem = 42'h3137cbcf044;
                57  : cmem = 42'h30ef71d4e0d;
                58  : cmem = 42'h30b061dad7f;
                59  : cmem = 42'h307ac1e0e60;
                60  : cmem = 42'h304eb5e7074;
                61  : cmem = 42'h302c57ed37f;
                62  : cmem = 42'h3013bbf3743;
                63  : cmem = 42'h3004f1f9b82;
            endcase
        end
    end else if (COEFFILE == "cmem_64.hex") begin
        always @(*) begin
            case (iaddr[(LGSPAN-1):0])
                0   : cmem = 44'h40000000000;
                1   : cmem = 44'h3fb11fe6e86;
                2   : cmem = 44'h3ec533ce0e9;
                3   : cmem = 44'h3d3e87b5afe;
                4   : cmem = 44'h3b20db9e087;
                5   : cmem = 44'h38716787529;
                6   : cmem = 44'h3536cf71c62;
                7   : cmem = 44'h3179035d986;
                8   : cmem = 44'h2d413f4afb1;
                9   : cmem = 44'h2899eb3a1c0;
                10  : cmem = 44'h238e7b2b24d;
                11  : cmem = 44'h1e2b5f1e3a7;
                12  : cmem = 44'h187de7137ca;
                13  : cmem = 44'h12940b0b05f;
                14  : cmem = 44'h0c7c5f04eb4;
                15  : cmem = 44'h0645eb013b9;
                16  : cmem = 44'h00000300000;
                17  : cmem = 44'hf9ba1b013b9;
                18  : cmem = 44'hf383a704eb4;
                19  : cmem = 44'hed6bfb0b05f;
                20  : cmem = 44'he7821f137ca;
                21  : cmem = 44'he1d4a71e3a7;
                22  : cmem = 44'hdc718b2b24d;
                23  : cmem = 44'hd7661b3a1c0;
                24  : cmem = 44'hd2bec74afb1;
                25  : cmem = 44'hce87035d986;
                26  : cmem = 44'hcac93771c62;
                27  : cmem = 44'hc78e9f87529;
                28  : cmem = 44'hc4df2b9e087;
                29  : cmem = 44'hc2c17fb5afe;
                30  : cmem = 44'hc13ad3ce0e9;
                31  : cmem = 44'hc04ee7e6e86;
            endcase
        end
    end else if (COEFFILE == "cmem_32.hex") begin
        always @(*) begin
            case (iaddr[(LGSPAN-1):0])
                0   : cmem = 44'h40000000000;
                1   : cmem = 44'h3ec533ce0e9;
                2   : cmem = 44'h3b20db9e087;
                3   : cmem = 44'h3536cf71c62;
                4   : cmem = 44'h2d413f4afb1;
                5   : cmem = 44'h238e7b2b24d;
                6   : cmem = 44'h187de7137ca;
                7   : cmem = 44'h0c7c5f04eb4;
                8   : cmem = 44'h00000300000;
                9   : cmem = 44'hf383a704eb4;
                10  : cmem = 44'he7821f137ca;
                11  : cmem = 44'hdc718b2b24d;
                12  : cmem = 44'hd2bec74afb1;
                13  : cmem = 44'hcac93771c62;
                14  : cmem = 44'hc4df2b9e087;
                15  : cmem = 44'hc13ad3ce0e9;
            endcase
        end
    end else if (COEFFILE == "cmem_16.hex") begin
        always @(*) begin
            case (iaddr[(LGSPAN-1):0])
                0   : cmem = 46'h100000000000;
                1   : cmem = 46'h0ec83673c10f;
                2   : cmem = 46'h0b504f695f62;
                3   : cmem = 46'h061f78e26f94;
                4   : cmem = 46'h000000600000;
                5   : cmem = 46'h39e087e26f94;
                6   : cmem = 46'h34afb1695f62;
                7   : cmem = 46'h3137ca73c10f;
            endcase
        end
    end else begin
        always @(*) begin
            case (iaddr[(LGSPAN-1):0])
                0   : cmem = 46'h100000000000;
                1   : cmem = 46'h0b504f695f62;
                2   : cmem = 46'h000000600000;
                3   : cmem = 46'h34afb1695f62;
            endcase
        end
    end
    endgenerate

`endif

	reg	[(2*IWIDTH-1):0]	imem	[0:((1<<LGSPAN)-1)];

	reg	[LGSPAN:0]		oaddr;
	reg	[(2*OWIDTH-1):0]	omem	[0:((1<<LGSPAN)-1)];

	wire				idle;
	reg	[(LGSPAN-1):0]		nxt_oaddr;
	reg	[(2*OWIDTH-1):0]	pre_ovalue;
	// }}}

	// wait_for_sync, iaddr
	// {{{
	initial wait_for_sync = 1'b1;
	initial iaddr = 0;
	always @(posedge i_clk)
	if (i_reset)
	begin
		wait_for_sync <= 1'b1;
		iaddr <= 0;
	end else if ((i_ce)&&((!wait_for_sync)||(i_sync)))
	begin
		//
		// First step: Record what we're not ready to use yet
		//
		iaddr <= iaddr + { {(LGSPAN){1'b0}}, 1'b1 };
		wait_for_sync <= 1'b0;
	end
	// }}}

	// Write to imem
	// {{{
	always @(posedge i_clk) // Need to make certain here that we don't read
	if ((i_ce)&&(!iaddr[LGSPAN])) // and write the same address on
		imem[iaddr[(LGSPAN-1):0]] <= i_data; // the same clk
	// }}}

	// ib_sync
	// {{{
	// Now, we have all the inputs, so let's feed the butterfly
	//
	// ib_sync is the synchronization bit to the butterfly.  It will
	// be tracked within the butterfly, and used to create the o_sync
	// value when the results from this output are produced
	initial ib_sync = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
		ib_sync <= 1'b0;
	else if (i_ce)
	begin
		// Set the sync to true on the very first
		// valid input in, and hence on the very
		// first valid data out per FFT.
		ib_sync <= (iaddr==(1<<(LGSPAN)));
	end
	// }}}

	// ib_a, ib_b, ib_c
	// {{{
	// Read the values from our input memory, and use them to feed
	// first of two butterfly inputs
	always	@(posedge i_clk)
	if (i_ce)
	begin
		// One input from memory, ...
		ib_a <= imem[iaddr[(LGSPAN-1):0]];
		// One input clocked in from the top
		ib_b <= i_data;
		// and the coefficient or twiddle factor
		// ib_c <= cmem[iaddr[(LGSPAN-1):0]];
        ib_c <= cmem;
	end
	// }}}

	// idle
	// {{{
	// The idle register is designed to keep track of when an input
	// to the butterfly is important and going to be used.  It's used
	// in a flag following, so that when useful values are placed
	// into the butterfly they'll be non-zero (idle=0), otherwise when
	// the inputs to the butterfly are irrelevant and will be ignored,
	// then (idle=1) those inputs will be set to zero.  This
	// functionality is not designed to be used in operation, but only
	// within a Verilator simulation context when chasing a bug.
	// In this limited environment, the non-zero answers will stand
	// in a trace making it easier to highlight a bug.
	generate if (ZERO_ON_IDLE)
	begin : GEN_ZERO_ON_IDLE
		reg	r_idle;

		initial	r_idle = 1;
		always @(posedge i_clk)
		if (i_reset)
			r_idle <= 1'b1;
		else if (i_ce)
			r_idle <= (!iaddr[LGSPAN])&&(!wait_for_sync);

		assign	idle = r_idle;

	end else begin : NO_IDLE_GENERATION

		assign	idle = 0;

	end endgenerate
	// }}}

	////////////////////////////////////////////////////////////////////////
	//
	// Instantiate the butterfly
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
// For the formal proof, we'll assume the outputs of hwbfly and/or
// butterfly, rather than actually calculating them.  This will simplify
// the proof and (if done properly) will be equivalent.  Be careful of
// defining FORMAL if you want the full logic!
`ifndef	FORMAL
	//
	generate if (OPT_HWMPY)
	begin : HWBFLY

		hwbfly #(
			// {{{
			.IWIDTH(IWIDTH),
			.CWIDTH(CWIDTH),
			.OWIDTH(OWIDTH),
			.CKPCE(CKPCE),
			.SHIFT(BFLYSHIFT)
			// }}}
		) bfly(
			// {{{
			.i_clk(i_clk), .i_reset(i_reset), .i_ce(i_ce),
			.i_coef((idle && !i_ce) ? 0:ib_c),
			.i_left((idle && !i_ce) ? 0:ib_a),
			.i_right((idle && !i_ce) ? 0:ib_b),
			.i_aux(ib_sync && i_ce),
			.o_left(ob_a), .o_right(ob_b), .o_aux(ob_sync)
			// }}}
		);

	end else begin : FWBFLY

		butterfly #(
			// {{{
			.IWIDTH(IWIDTH),
			.CWIDTH(CWIDTH),
			.OWIDTH(OWIDTH),
			.CKPCE(CKPCE),
			.SHIFT(BFLYSHIFT)
			// }}}
		) bfly(
			// {{{
			.i_clk(i_clk), .i_reset(i_reset), .i_ce(i_ce),
			.i_coef( (idle && !i_ce)?0:ib_c),
			.i_left( (idle && !i_ce)?0:ib_a),
			.i_right((idle && !i_ce)?0:ib_b),
			.i_aux(ib_sync && i_ce),
			.o_left(ob_a), .o_right(ob_b), .o_aux(ob_sync)
			// }}}
		);

	end endgenerate
`else

	// Verilator lint_off UNDRIVEN
	(* anyseq *)    wire    [(2*OWIDTH-1):0]        f_ob_a, f_ob_b;
	(* anyseq *)    wire    f_ob_sync;
	// Verilator lint_on  UNDRIVEN

	assign  ob_sync = f_ob_sync;
	assign  ob_a    = f_ob_a;
	assign  ob_b    = f_ob_b;

`endif

	// }}}

	// oaddr, o_sync, b_started
	// {{{
	// Next step: recover the outputs from the butterfly
	//
	// The first output can go immediately to the output of this routine
	// The second output must wait until this time in the idle cycle
	// oaddr is the output memory address, keeping track of where we are
	// in this output cycle.
	initial oaddr     = 0;
	initial o_sync    = 0;
	initial b_started = 0;
	always @(posedge i_clk)
	if (i_reset)
	begin
		oaddr     <= 0;
		o_sync    <= 0;
		// b_started will be true once we've seen the first ob_sync
		b_started <= 0;
	end else if (i_ce)
	begin
		o_sync <= (!oaddr[LGSPAN])?ob_sync : 1'b0;
		if (ob_sync||b_started)
			oaddr <= oaddr + 1'b1;
		if ((ob_sync)&&(!oaddr[LGSPAN]))
			// If b_started is true, then a butterfly output
			// is available
			b_started <= 1'b1;
	end
	// }}}

	// nxt_oaddr
	// {{{
	always @(posedge i_clk)
	if (i_ce)
		nxt_oaddr[0] <= oaddr[0];
	generate if (LGSPAN>1)
	begin

		always @(posedge i_clk)
		if (i_ce)
			nxt_oaddr[LGSPAN-1:1] <= oaddr[LGSPAN-1:1] + 1'b1;

	end endgenerate
	// }}}

	// omem
	// {{{
	// Only write to the memory on the first half of the outputs
	// We'll use the memory value on the second half of the outputs
	always @(posedge i_clk)
	if ((i_ce)&&(!oaddr[LGSPAN]))
		omem[oaddr[(LGSPAN-1):0]] <= ob_b;
	// }}}

	// pre_ovalue
	// {{{
	always @(posedge i_clk)
	if (i_ce)
		pre_ovalue <= omem[nxt_oaddr[(LGSPAN-1):0]];
	// }}}

	// o_data
	// {{{
	always @(posedge i_clk)
	if (i_ce)
		o_data <= (!oaddr[LGSPAN]) ? ob_a : pre_ovalue;
	// }}}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// Formal properties
// {{{
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
`ifdef	FORMAL
	// Local (formal) declarations
	// {{{
	// An arbitrary processing delay from butterfly input to
	// butterfly output(s)
	// Verilator lint_off UNDRIVEN
	(* anyconst *) reg	[LGSPAN:0]	f_mpydelay;
	(* anyconst *)	reg	[LGSPAN:0]	f_addr;
	// Verilator lint_on  UNDRIVEN
	reg	[2*IWIDTH-1:0]			f_left, f_right;
	reg	[2*OWIDTH-1:0]	f_oleft, f_oright;
	reg	[LGSPAN:0]	f_oaddr;
	wire	[LGSPAN:0]	f_oaddr_m1 = f_oaddr - 1'b1;
	reg	f_output_active;
	// }}}


	always @(*)
		assume(f_mpydelay > 1);

	reg	f_past_valid;
	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

	always @(posedge i_clk)
	if ((!f_past_valid)||($past(i_reset)))
	begin
		assert(iaddr == 0);
		assert(wait_for_sync);
		assert(o_sync == 0);
		assert(oaddr == 0);
		assert(!b_started);
		assert(!o_sync);
	end

	////////////////////////////////////////////////////////////////////////
	//
	// Formally verify the input half, from the inputs to this module
	// to the inputs of the butterfly
	//
	////////////////////////////////////////////////////////////////////////
	//
	//

	// Let's  verify a specific set of inputs

	always @(posedge i_clk)
	if (!$past(i_ce) && !$past(i_ce,2) && !$past(i_ce,3) && !$past(i_ce,4))
		assume(!i_ce);

	always @(*)
		assume(f_addr[LGSPAN]==1'b0);

	always @(posedge i_clk)
	if ((i_ce)&&(iaddr[LGSPAN:0] == f_addr))
		f_left <= i_data;

	always @(*)
	if (wait_for_sync)
		assert(iaddr == 0);

	wire	[LGSPAN:0]	f_last_addr = iaddr - 1'b1;

	always @(posedge i_clk)
	if ((!wait_for_sync)&&(f_last_addr >= { 1'b0, f_addr[LGSPAN-1:0]}))
		assert(f_left == imem[f_addr[LGSPAN-1:0]]);

	always @(posedge i_clk)
	if ((i_ce)&&(iaddr == { 1'b1, f_addr[LGSPAN-1:0]}))
		f_right <= i_data;

	always @(posedge i_clk)
	if (i_ce && !wait_for_sync
		&& (f_last_addr == { 1'b1, f_addr[LGSPAN-1:0]}))
	begin
		assert(ib_a == f_left);
		assert(ib_b == f_right);
		assert(ib_c == cmem[f_addr[LGSPAN-1:0]]);
	end

	////////////////////////////////////////////////////////////////////////
	//
	// Formally verify the output half, from the output of the butterfly
	// to the outputs of this module
	//
	////////////////////////////////////////////////////////////////////////
	//
	//

	always @(*)
		f_oaddr = iaddr - f_mpydelay + {1'b1,{(LGSPAN-1){1'b0}} };

	assign	f_oaddr_m1 = f_oaddr - 1'b1;

	initial	f_output_active = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
		f_output_active <= 1'b0;
	else if ((i_ce)&&(ob_sync))
		f_output_active <= 1'b1;

	always @(*)
		assert(f_output_active == b_started);

	always @(*)
	if (wait_for_sync)
		assert(!f_output_active);

	always @(*)
	if (f_output_active)
	begin
		assert(oaddr == f_oaddr);
	end else
		assert(oaddr == 0);

	always @(*)
	if (wait_for_sync)
		assume(!ob_sync);

	always @(*)
		assume(ob_sync == (f_oaddr == 0));

	always @(posedge i_clk)
	if ((f_past_valid)&&(!$past(i_ce)))
	begin
		assume($stable(ob_a));
		assume($stable(ob_b));
	end

	initial	f_oleft  = 0;
	initial	f_oright = 0;
	always @(posedge i_clk)
	if ((i_ce)&&(f_oaddr == f_addr))
	begin
		f_oleft  <= ob_a;
		f_oright <= ob_b;
	end

	always @(posedge i_clk)
	if ((f_output_active)&&(f_oaddr_m1 >= { 1'b0, f_addr[LGSPAN-1:0]}))
		assert(omem[f_addr[LGSPAN-1:0]] == f_oright);

	always @(posedge i_clk)
	if ((i_ce)&&(f_oaddr_m1 == 0)&&(f_output_active))
	begin
		assert(o_sync);
	end else if ((i_ce)||(!f_output_active))
		assert(!o_sync);

	always @(posedge i_clk)
	if ((i_ce)&&(f_output_active)&&(f_oaddr_m1 == f_addr))
		assert(o_data == f_oleft);

	always @(posedge i_clk)
	if ((i_ce)&&(f_output_active)&&(f_oaddr[LGSPAN])
			&&(f_oaddr[LGSPAN-1:0] == f_addr[LGSPAN-1:0]))
		assert(pre_ovalue == f_oright);

	always @(posedge i_clk)
	if ((i_ce)&&(f_output_active)&&(f_oaddr_m1[LGSPAN])
			&&(f_oaddr_m1[LGSPAN-1:0] == f_addr[LGSPAN-1:0]))
		assert(o_data == f_oright);

	// Make Verilator happy
	// {{{
	// Verilator lint_off UNUSED
	wire	unused_formal;
	assign unused_formal = &{ 1'b0, idle, ib_sync };
	// Verilator lint_on  UNUSED
	// }}}

`endif // FORMAL
// }}}
endmodule
