// =============================================================================
// Module:       DCT
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Computes a 32-element DCT and outputs the first 13 coefficients. Input data
// is expected to stay the same for 13 cycles, permitting the accumulation
// of each output coefficient simultaneously.
// =============================================================================

module dct #(
    // =========================================================================
    // Local Parameters - Do Not Edit
    // =========================================================================
    parameter I_BW = 8,
    parameter O_BW = 16
) (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input         [I_BW - 1 : 0]            data_i,
    input                                   valid_i,
    input                                   last_i,

    // streaming output
    output signed [O_BW - 1 : 0]            data_o,
    output                                  valid_o,
    output                                  last_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam INTERNAL_BW   = 32;
    localparam COEF_BW       = 16;
    localparam FRAME_LEN     = 32;  // length of the DCT
    localparam ELEM_COUNT_BW = $clog2(FRAME_LEN);
    localparam N_COEF        = 13;
    localparam COEF_COUNT_BW = $clog2(N_COEF);
    localparam ADDR_BW       = $clog2(N_COEF * FRAME_LEN);
    localparam SHIFT         = 15;

    localparam COEFFILE     = "dct.hex";

    // =========================================================================
    // Signal Declarations
    // =========================================================================
    reg [ELEM_COUNT_BW - 1 : 0] elem_counter;
    wire last_elem = (elem_counter == FRAME_LEN - 1);
    reg signed [COEF_BW - 1 : 0] coefs;

    // =========================================================================
    // Element Counter
    // =========================================================================
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            elem_counter <= 'd0;
        end else begin
            if (valid_i & next_elem) begin
                elem_counter <= elem_counter + 'd1;
            end else if (valid_i) begin
                elem_counter <= elem_counter;
            end else begin
                elem_counter <= 'd0;
            end
        end
    end

    // =========================================================================
    // Coefficient Counter (aka Cadence)
    // =========================================================================
    reg [COEF_COUNT_BW - 1 : 0] coef_counter;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            coef_counter <= 'd0;
        end else begin
            if (next_elem) begin
                coef_counter <= 'd0;
            end else if (valid_i) begin
                coef_counter <= coef_counter + 'd1;
            end else begin
                coef_counter <= 'd0;
            end
        end
    end
    wire next_elem = (coef_counter == N_COEF - 'd1);

    // =========================================================================
    // Multiplication
    // =========================================================================
    wire [ADDR_BW - 1 : 0] addr = N_COEF * elem_counter + coef_counter;
    wire signed [INTERNAL_BW - 1 : 0] mult;
    wire signed [I_BW : 0] data_i_signed = data_i;
    // assign mult = data_i_signed * coefs[addr];
    assign mult = data_i_signed * coefs;

    // =========================================================================
    // Accumulated coefficients
    // =========================================================================
    reg signed [INTERNAL_BW - 1 : 0] acc_arr [N_COEF - 1 : 0];
    genvar i;
    for (i = 0; i < N_COEF; i = i + 1) begin: accumulation_regs
        always @(posedge clk_i) begin
            if (!rst_n_i | !en_i) begin
                acc_arr[i] <= 'd0;
            end else if (valid_i & (coef_counter == i)) begin
                acc_arr[i] <= acc_arr[i] + mult;
            end else if (valid_i) begin
                acc_arr[i] <= acc_arr[i];
            end else begin
                acc_arr[i] <= 'd0;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    wire signed [INTERNAL_BW - 1 : 0] pre_shift = acc_arr[coef_counter] + mult;
    assign valid_o = (en_i & last_elem);
    assign data_o = pre_shift >> SHIFT;
    assign last_o = last_i;

    // =========================================================================
    // ROM Memory for DCT coefficients
    // =========================================================================
    // reg signed [COEF_BW - 1 : 0] coefs [0 : N_COEF * FRAME_LEN - 1];
    always @(*) begin
        case (addr)
            0   : coefs = 'h16a1;
            1   : coefs = 'h1ff6;
            2   : coefs = 'h1fd9;
            3   : coefs = 'h1fa7;
            4   : coefs = 'h1f63;
            5   : coefs = 'h1f0a;
            6   : coefs = 'h1e9f;
            7   : coefs = 'h1e21;
            8   : coefs = 'h1d90;
            9   : coefs = 'h1ced;
            10  : coefs = 'h1c39;
            11  : coefs = 'h1b73;
            12  : coefs = 'h1a9b;
            13  : coefs = 'h16a1;
            14  : coefs = 'h1fa7;
            15  : coefs = 'h1e9f;
            16  : coefs = 'h1ced;
            17  : coefs = 'h1a9b;
            18  : coefs = 'h17b6;
            19  : coefs = 'h144d;
            20  : coefs = 'h1074;
            21  : coefs = 'h0c3f;
            22  : coefs = 'h07c6;
            23  : coefs = 'h0323;
            24  : coefs = 'hfe6e;
            25  : coefs = 'hf9c2;
            26  : coefs = 'h16a1;
            27  : coefs = 'h1f0a;
            28  : coefs = 'h1c39;
            29  : coefs = 'h17b6;
            30  : coefs = 'h11c7;
            31  : coefs = 'h0ac8;
            32  : coefs = 'h0323;
            33  : coefs = 'hfb4e;
            34  : coefs = 'hf3c1;
            35  : coefs = 'hecf0;
            36  : coefs = 'he743;
            37  : coefs = 'he313;
            38  : coefs = 'he09d;
            39  : coefs = 'h16a1;
            40  : coefs = 'h1e21;
            41  : coefs = 'h18bd;
            42  : coefs = 'h1074;
            43  : coefs = 'h063e;
            44  : coefs = 'hfb4e;
            45  : coefs = 'hf0ea;
            46  : coefs = 'he84a;
            47  : coefs = 'he270;
            48  : coefs = 'he00a;
            49  : coefs = 'he161;
            50  : coefs = 'he64c;
            51  : coefs = 'hee39;
            52  : coefs = 'h16a1;
            53  : coefs = 'h1ced;
            54  : coefs = 'h144d;
            55  : coefs = 'h07c6;
            56  : coefs = 'hf9c2;
            57  : coefs = 'hecf0;
            58  : coefs = 'he3c7;
            59  : coefs = 'he00a;
            60  : coefs = 'he270;
            61  : coefs = 'hea83;
            62  : coefs = 'hf6b6;
            63  : coefs = 'h04b2;
            64  : coefs = 'h11c7;
            65  : coefs = 'h16a1;
            66  : coefs = 'h1b73;
            67  : coefs = 'h0f16;
            68  : coefs = 'hfe6e;
            69  : coefs = 'hee39;
            70  : coefs = 'he313;
            71  : coefs = 'he027;
            72  : coefs = 'he64c;
            73  : coefs = 'hf3c1;
            74  : coefs = 'h04b2;
            75  : coefs = 'h144d;
            76  : coefs = 'h1e21;
            77  : coefs = 'h1f63;
            78  : coefs = 'h16a1;
            79  : coefs = 'h19b4;
            80  : coefs = 'h094a;
            81  : coefs = 'hf538;
            82  : coefs = 'he565;
            83  : coefs = 'he00a;
            84  : coefs = 'he743;
            85  : coefs = 'hf83a;
            86  : coefs = 'h0c3f;
            87  : coefs = 'h1b73;
            88  : coefs = 'h1fd9;
            89  : coefs = 'h17b6;
            90  : coefs = 'h063e;
            91  : coefs = 'h16a1;
            92  : coefs = 'h17b6;
            93  : coefs = 'h0323;
            94  : coefs = 'hecf0;
            95  : coefs = 'he09d;
            96  : coefs = 'he48d;
            97  : coefs = 'hf6b6;
            98  : coefs = 'h0daf;
            99  : coefs = 'h1d90;
            100 : coefs = 'h1e21;
            101 : coefs = 'h0f16;
            102 : coefs = 'hf83a;
            103 : coefs = 'he565;
            104 : coefs = 'h16a1;
            105 : coefs = 'h157d;
            106 : coefs = 'hfcdd;
            107 : coefs = 'he64c;
            108 : coefs = 'he09d;
            109 : coefs = 'hef8c;
            110 : coefs = 'h094a;
            111 : coefs = 'h1ced;
            112 : coefs = 'h1d90;
            113 : coefs = 'h0ac8;
            114 : coefs = 'hf0ea;
            115 : coefs = 'he0f6;
            116 : coefs = 'he565;
            117 : coefs = 'h16a1;
            118 : coefs = 'h1310;
            119 : coefs = 'hf6b6;
            120 : coefs = 'he1df;
            121 : coefs = 'he565;
            122 : coefs = 'hfe6e;
            123 : coefs = 'h18bd;
            124 : coefs = 'h1f0a;
            125 : coefs = 'h0c3f;
            126 : coefs = 'hef8c;
            127 : coefs = 'he027;
            128 : coefs = 'hea83;
            129 : coefs = 'h063e;
            130 : coefs = 'h16a1;
            131 : coefs = 'h1074;
            132 : coefs = 'hf0ea;
            133 : coefs = 'he00a;
            134 : coefs = 'hee39;
            135 : coefs = 'h0daf;
            136 : coefs = 'h1fd9;
            137 : coefs = 'h1310;
            138 : coefs = 'hf3c1;
            139 : coefs = 'he059;
            140 : coefs = 'hebb3;
            141 : coefs = 'h0ac8;
            142 : coefs = 'h1f63;
            143 : coefs = 'h16a1;
            144 : coefs = 'h0daf;
            145 : coefs = 'hebb3;
            146 : coefs = 'he0f6;
            147 : coefs = 'hf9c2;
            148 : coefs = 'h19b4;
            149 : coefs = 'h1c39;
            150 : coefs = 'hfe6e;
            151 : coefs = 'he270;
            152 : coefs = 'he84a;
            153 : coefs = 'h094a;
            154 : coefs = 'h1fa7;
            155 : coefs = 'h11c7;
            156 : coefs = 'h16a1;
            157 : coefs = 'h0ac8;
            158 : coefs = 'he743;
            159 : coefs = 'he48d;
            160 : coefs = 'h063e;
            161 : coefs = 'h1fa7;
            162 : coefs = 'h0f16;
            163 : coefs = 'hea83;
            164 : coefs = 'he270;
            165 : coefs = 'h0192;
            166 : coefs = 'h1e9f;
            167 : coefs = 'h1310;
            168 : coefs = 'hee39;
            169 : coefs = 'h16a1;
            170 : coefs = 'h07c6;
            171 : coefs = 'he3c7;
            172 : coefs = 'hea83;
            173 : coefs = 'h11c7;
            174 : coefs = 'h1e21;
            175 : coefs = 'hfcdd;
            176 : coefs = 'he059;
            177 : coefs = 'hf3c1;
            178 : coefs = 'h19b4;
            179 : coefs = 'h18bd;
            180 : coefs = 'hf251;
            181 : coefs = 'he09d;
            182 : coefs = 'h16a1;
            183 : coefs = 'h04b2;
            184 : coefs = 'he161;
            185 : coefs = 'hf251;
            186 : coefs = 'h1a9b;
            187 : coefs = 'h157d;
            188 : coefs = 'hebb3;
            189 : coefs = 'he48d;
            190 : coefs = 'h0c3f;
            191 : coefs = 'h1f0a;
            192 : coefs = 'hfcdd;
            193 : coefs = 'he00a;
            194 : coefs = 'hf9c2;
            195 : coefs = 'h16a1;
            196 : coefs = 'h0192;
            197 : coefs = 'he027;
            198 : coefs = 'hfb4e;
            199 : coefs = 'h1f63;
            200 : coefs = 'h07c6;
            201 : coefs = 'he161;
            202 : coefs = 'hf538;
            203 : coefs = 'h1d90;
            204 : coefs = 'h0daf;
            205 : coefs = 'he3c7;
            206 : coefs = 'hef8c;
            207 : coefs = 'h1a9b;
            208 : coefs = 'h16a1;
            209 : coefs = 'hfe6e;
            210 : coefs = 'he027;
            211 : coefs = 'h04b2;
            212 : coefs = 'h1f63;
            213 : coefs = 'hf83a;
            214 : coefs = 'he161;
            215 : coefs = 'h0ac8;
            216 : coefs = 'h1d90;
            217 : coefs = 'hf251;
            218 : coefs = 'he3c7;
            219 : coefs = 'h1074;
            220 : coefs = 'h1a9b;
            221 : coefs = 'h16a1;
            222 : coefs = 'hfb4e;
            223 : coefs = 'he161;
            224 : coefs = 'h0daf;
            225 : coefs = 'h1a9b;
            226 : coefs = 'hea83;
            227 : coefs = 'hebb3;
            228 : coefs = 'h1b73;
            229 : coefs = 'h0c3f;
            230 : coefs = 'he0f6;
            231 : coefs = 'hfcdd;
            232 : coefs = 'h1ff6;
            233 : coefs = 'hf9c2;
            234 : coefs = 'h16a1;
            235 : coefs = 'hf83a;
            236 : coefs = 'he3c7;
            237 : coefs = 'h157d;
            238 : coefs = 'h11c7;
            239 : coefs = 'he1df;
            240 : coefs = 'hfcdd;
            241 : coefs = 'h1fa7;
            242 : coefs = 'hf3c1;
            243 : coefs = 'he64c;
            244 : coefs = 'h18bd;
            245 : coefs = 'h0daf;
            246 : coefs = 'he09d;
            247 : coefs = 'h16a1;
            248 : coefs = 'hf538;
            249 : coefs = 'he743;
            250 : coefs = 'h1b73;
            251 : coefs = 'h063e;
            252 : coefs = 'he059;
            253 : coefs = 'h0f16;
            254 : coefs = 'h157d;
            255 : coefs = 'he270;
            256 : coefs = 'hfe6e;
            257 : coefs = 'h1e9f;
            258 : coefs = 'hecf0;
            259 : coefs = 'hee39;
            260 : coefs = 'h16a1;
            261 : coefs = 'hf251;
            262 : coefs = 'hebb3;
            263 : coefs = 'h1f0a;
            264 : coefs = 'hf9c2;
            265 : coefs = 'he64c;
            266 : coefs = 'h1c39;
            267 : coefs = 'h0192;
            268 : coefs = 'he270;
            269 : coefs = 'h17b6;
            270 : coefs = 'h094a;
            271 : coefs = 'he059;
            272 : coefs = 'h11c7;
            273 : coefs = 'h16a1;
            274 : coefs = 'hef8c;
            275 : coefs = 'hf0ea;
            276 : coefs = 'h1ff6;
            277 : coefs = 'hee39;
            278 : coefs = 'hf251;
            279 : coefs = 'h1fd9;
            280 : coefs = 'hecf0;
            281 : coefs = 'hf3c1;
            282 : coefs = 'h1fa7;
            283 : coefs = 'hebb3;
            284 : coefs = 'hf538;
            285 : coefs = 'h1f63;
            286 : coefs = 'h16a1;
            287 : coefs = 'hecf0;
            288 : coefs = 'hf6b6;
            289 : coefs = 'h1e21;
            290 : coefs = 'he565;
            291 : coefs = 'h0192;
            292 : coefs = 'h18bd;
            293 : coefs = 'he0f6;
            294 : coefs = 'h0c3f;
            295 : coefs = 'h1074;
            296 : coefs = 'he027;
            297 : coefs = 'h157d;
            298 : coefs = 'h063e;
            299 : coefs = 'h16a1;
            300 : coefs = 'hea83;
            301 : coefs = 'hfcdd;
            302 : coefs = 'h19b4;
            303 : coefs = 'he09d;
            304 : coefs = 'h1074;
            305 : coefs = 'h094a;
            306 : coefs = 'he313;
            307 : coefs = 'h1d90;
            308 : coefs = 'hf538;
            309 : coefs = 'hf0ea;
            310 : coefs = 'h1f0a;
            311 : coefs = 'he565;
            312 : coefs = 'h16a1;
            313 : coefs = 'he84a;
            314 : coefs = 'h0323;
            315 : coefs = 'h1310;
            316 : coefs = 'he09d;
            317 : coefs = 'h1b73;
            318 : coefs = 'hf6b6;
            319 : coefs = 'hf251;
            320 : coefs = 'h1d90;
            321 : coefs = 'he1df;
            322 : coefs = 'h0f16;
            323 : coefs = 'h07c6;
            324 : coefs = 'he565;
            325 : coefs = 'h16a1;
            326 : coefs = 'he64c;
            327 : coefs = 'h094a;
            328 : coefs = 'h0ac8;
            329 : coefs = 'he565;
            330 : coefs = 'h1ff6;
            331 : coefs = 'he743;
            332 : coefs = 'h07c6;
            333 : coefs = 'h0c3f;
            334 : coefs = 'he48d;
            335 : coefs = 'h1fd9;
            336 : coefs = 'he84a;
            337 : coefs = 'h063e;
            338 : coefs = 'h16a1;
            339 : coefs = 'he48d;
            340 : coefs = 'h0f16;
            341 : coefs = 'h0192;
            342 : coefs = 'hee39;
            343 : coefs = 'h1ced;
            344 : coefs = 'he027;
            345 : coefs = 'h19b4;
            346 : coefs = 'hf3c1;
            347 : coefs = 'hfb4e;
            348 : coefs = 'h144d;
            349 : coefs = 'he1df;
            350 : coefs = 'h1f63;
            351 : coefs = 'h16a1;
            352 : coefs = 'he313;
            353 : coefs = 'h144d;
            354 : coefs = 'hf83a;
            355 : coefs = 'hf9c2;
            356 : coefs = 'h1310;
            357 : coefs = 'he3c7;
            358 : coefs = 'h1ff6;
            359 : coefs = 'he270;
            360 : coefs = 'h157d;
            361 : coefs = 'hf6b6;
            362 : coefs = 'hfb4e;
            363 : coefs = 'h11c7;
            364 : coefs = 'h16a1;
            365 : coefs = 'he1df;
            366 : coefs = 'h18bd;
            367 : coefs = 'hef8c;
            368 : coefs = 'h063e;
            369 : coefs = 'h04b2;
            370 : coefs = 'hf0ea;
            371 : coefs = 'h17b6;
            372 : coefs = 'he270;
            373 : coefs = 'h1ff6;
            374 : coefs = 'he161;
            375 : coefs = 'h19b4;
            376 : coefs = 'hee39;
            377 : coefs = 'h16a1;
            378 : coefs = 'he0f6;
            379 : coefs = 'h1c39;
            380 : coefs = 'he84a;
            381 : coefs = 'h11c7;
            382 : coefs = 'hf538;
            383 : coefs = 'h0323;
            384 : coefs = 'h04b2;
            385 : coefs = 'hf3c1;
            386 : coefs = 'h1310;
            387 : coefs = 'he743;
            388 : coefs = 'h1ced;
            389 : coefs = 'he09d;
            390 : coefs = 'h16a1;
            391 : coefs = 'he059;
            392 : coefs = 'h1e9f;
            393 : coefs = 'he313;
            394 : coefs = 'h1a9b;
            395 : coefs = 'he84a;
            396 : coefs = 'h144d;
            397 : coefs = 'hef8c;
            398 : coefs = 'h0c3f;
            399 : coefs = 'hf83a;
            400 : coefs = 'h0323;
            401 : coefs = 'h0192;
            402 : coefs = 'hf9c2;
            403 : coefs = 'h16a1;
            404 : coefs = 'he00a;
            405 : coefs = 'h1fd9;
            406 : coefs = 'he059;
            407 : coefs = 'h1f63;
            408 : coefs = 'he0f6;
            409 : coefs = 'h1e9f;
            410 : coefs = 'he1df;
            411 : coefs = 'h1d90;
            412 : coefs = 'he313;
            413 : coefs = 'h1c39;
            414 : coefs = 'he48d;
            415 : coefs = 'h1a9b;
        endcase
    end

    initial begin
        // $display("reading from: %s", COEFFILE);
        // $readmemh(COEFFILE, coefs);

        // =====================================================================
        // Simulation Only Waveform Dump (.vcd export)
        // =====================================================================
        `ifdef COCOTB_SIM
        `ifndef SCANNED
        `define SCANNED
        $dumpfile ("wave.vcd");
        $dumpvars (0, dct);
        $dumpvars (0, acc_arr[0]);
        $dumpvars (0, acc_arr[1]);
        #1;
        `endif
        `endif
    end

endmodule
