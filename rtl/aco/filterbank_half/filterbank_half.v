// =============================================================================
// Module:       Filterbank Half
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        Takes in an input power spectrum and multiplies it by half 
//               (even or odd only) MFCC overlapping triangular windows.
//               Deassertions of valid are not permitted.
// =============================================================================

module filterbank_half # (
    parameter COEFFILE          = "coef_even.hex",
    parameter BOUNDARYFILE      = "boundary_even.hex"
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
    output         [O_BW - 1 : 0]           data_o,
    output                                  valid_o,
    output                                  last_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam I_BW         = 32;
    localparam INTERNAL_BW  = 64;   // 48 would be sufficient but why not
    localparam O_BW         = 32;
    localparam COEF_BW      = 16;   // bitwidth of the filterbank coefficients
    localparam INPUT_LEN    = 129;  // length of the power spectrum
    localparam NUM_BOUNDARY = 16;   // number of triangle boundary indices
                                    // Signals when a MFCC coefficient is done
    localparam BOUNDARY_BW  = 8;

    // =========================================================================
    // Element counter
    // =========================================================================
    reg [BOUNDARY_BW - 1 : 0] elem_counter;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            elem_counter <= 'd0;
        end else begin
            if (last_i) begin
                elem_counter <= 'd0;
            end else if (valid_i) begin
                elem_counter <= elem_counter + 'd1;
            end else begin
                elem_counter <= 'd0;
            end
        end
    end

    // =========================================================================
    // Boundary counter
    // =========================================================================
    reg [BOUNDARY_BW - 1 : 0] boundary_counter;
    // wire at_boundary = (boundary[boundary_counter] == elem_counter);
    wire at_boundary = (boundary == elem_counter);
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            boundary_counter <= 'd0;
        end else begin
            if (last_i) begin
                boundary_counter <= 'd0;
            end else if (at_boundary & (boundary_counter == NUM_BOUNDARY - 1)) begin
                boundary_counter <= 'd0;
            end else if (at_boundary) begin
                boundary_counter <= boundary_counter + 'd1;
            end else begin
                boundary_counter <= boundary_counter;
            end
        end
    end

    // =========================================================================
    // Running sum
    // =========================================================================
    // Stores the running sum for an output coefficient up to but not
    // including the last element.
    reg [INTERNAL_BW - 1 : 0] sum;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            sum <= 'd0;
        end else begin
            if (at_boundary) begin  // reset the running sum at boundaries
                sum <= 'd0;
            end else if (valid_i) begin
                // sum <= sum + (data_i * coef[elem_counter]);
                sum <= sum + (data_i * coef);
            end else begin
                sum <= 'd0;
            end
        end
    end

    // wire [INTERNAL_BW - 1 : 0] sum_result = sum + (data_i * coef[elem_counter]);
    wire [INTERNAL_BW - 1 : 0] sum_result = sum + (data_i * coef);

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & at_boundary);
    assign data_o = sum_result >> COEF_BW;
    assign last_o = last_i;

    // =========================================================================
    // ROM Memories for filterbank coefficients and boundary indices
    // =========================================================================
    // reg [COEF_BW - 1 : 0] coef [0 : INPUT_LEN - 1];  // filters 0,2,...30 (even)
    //                                                  // or      1,3,...31 (odd)
    // reg [BOUNDARY_BW - 1 : 0] boundary [0 : NUM_BOUNDARY - 1];  // boundaries
    reg [COEF_BW - 1 : 0] coef;  // filters 0,2,...30 (even)
                                                     // or      1,3,...31 (odd)
    reg [BOUNDARY_BW - 1 : 0] boundary;  // boundaries

    if (COEFFILE == "coef_even.hex") begin
        always @(*) begin
            case(elem_counter)
                0   : coef = 'h0000;
                1   : coef = 'h0000;
                2   : coef = 'h0000;
                3   : coef = 'h0000;
                4   : coef = 'h0000;
                5   : coef = 'hffff;
                6   : coef = 'h7fff;
                7   : coef = 'h0000;
                8   : coef = 'hffff;
                9   : coef = 'h0000;
                10  : coef = 'h7fff;
                11  : coef = 'hffff;
                12  : coef = 'h0000;
                13  : coef = 'h7fff;
                14  : coef = 'hffff;
                15  : coef = 'h0000;
                16  : coef = 'h7fff;
                17  : coef = 'hffff;
                18  : coef = 'h7fff;
                19  : coef = 'h0000;
                20  : coef = 'h7fff;
                21  : coef = 'hffff;
                22  : coef = 'haaaa;
                23  : coef = 'h5555;
                24  : coef = 'h0000;
                25  : coef = 'h7fff;
                26  : coef = 'hffff;
                27  : coef = 'h7fff;
                28  : coef = 'h0000;
                29  : coef = 'h5555;
                30  : coef = 'haaaa;
                31  : coef = 'hffff;
                32  : coef = 'haaaa;
                33  : coef = 'h5555;
                34  : coef = 'h0000;
                35  : coef = 'h5555;
                36  : coef = 'haaaa;
                37  : coef = 'hffff;
                38  : coef = 'hbfff;
                39  : coef = 'h7fff;
                40  : coef = 'h3fff;
                41  : coef = 'h0000;
                42  : coef = 'h5555;
                43  : coef = 'haaaa;
                44  : coef = 'hffff;
                45  : coef = 'hbfff;
                46  : coef = 'h7fff;
                47  : coef = 'h3fff;
                48  : coef = 'h0000;
                49  : coef = 'h3fff;
                50  : coef = 'h7fff;
                51  : coef = 'hbfff;
                52  : coef = 'hffff;
                53  : coef = 'hbfff;
                54  : coef = 'h7fff;
                55  : coef = 'h3fff;
                56  : coef = 'h0000;
                57  : coef = 'h3333;
                58  : coef = 'h6666;
                59  : coef = 'h9999;
                60  : coef = 'hcccc;
                61  : coef = 'hffff;
                62  : coef = 'hcccc;
                63  : coef = 'h9999;
                64  : coef = 'h6666;
                65  : coef = 'h3333;
                66  : coef = 'h0000;
                67  : coef = 'h3333;
                68  : coef = 'h6666;
                69  : coef = 'h9999;
                70  : coef = 'hcccc;
                71  : coef = 'hffff;
                72  : coef = 'hd554;
                73  : coef = 'haaaa;
                74  : coef = 'h7fff;
                75  : coef = 'h5555;
                76  : coef = 'h2aaa;
                77  : coef = 'h0000;
                78  : coef = 'h2aaa;
                79  : coef = 'h5555;
                80  : coef = 'h7fff;
                81  : coef = 'haaaa;
                82  : coef = 'hd554;
                83  : coef = 'hffff;
                84  : coef = 'hd554;
                85  : coef = 'haaaa;
                86  : coef = 'h7fff;
                87  : coef = 'h5555;
                88  : coef = 'h2aaa;
                89  : coef = 'h0000;
                90  : coef = 'h2492;
                91  : coef = 'h4924;
                92  : coef = 'h6db6;
                93  : coef = 'h9248;
                94  : coef = 'hb6da;
                95  : coef = 'hdb6c;
                96  : coef = 'hffff;
                97  : coef = 'hdb6c;
                98  : coef = 'hb6da;
                99  : coef = 'h9248;
                100 : coef = 'h6db6;
                101 : coef = 'h4924;
                102 : coef = 'h2492;
                103 : coef = 'h0000;
                104 : coef = 'h1fff;
                105 : coef = 'h3fff;
                106 : coef = 'h5fff;
                107 : coef = 'h7fff;
                108 : coef = 'h9fff;
                109 : coef = 'hbfff;
                110 : coef = 'hdfff;
                111 : coef = 'hffff;
                112 : coef = 'hdfff;
                113 : coef = 'hbfff;
                114 : coef = 'h9fff;
                115 : coef = 'h7fff;
                116 : coef = 'h5fff;
                117 : coef = 'h3fff;
                118 : coef = 'h1fff;
                119 : coef = 'h0000;
                120 : coef = 'h0000;
                121 : coef = 'h0000;
                122 : coef = 'h0000;
                123 : coef = 'h0000;
                124 : coef = 'h0000;
                125 : coef = 'h0000;
                126 : coef = 'h0000;
                127 : coef = 'h0000;
                128 : coef = 'h0000;
            endcase
        end
    end else begin
        always @(*) begin
            case(elem_counter)
                0   : coef = 'h0000;
                1   : coef = 'h0000;
                2   : coef = 'h0000;
                3   : coef = 'h0000;
                4   : coef = 'h0000;
                5   : coef = 'h0000;
                6   : coef = 'h7fff;
                7   : coef = 'hffff;
                8   : coef = 'h0000;
                9   : coef = 'hffff;
                10  : coef = 'h7fff;
                11  : coef = 'h0000;
                12  : coef = 'hffff;
                13  : coef = 'h7fff;
                14  : coef = 'h0000;
                15  : coef = 'hffff;
                16  : coef = 'h7fff;
                17  : coef = 'h0000;
                18  : coef = 'h7fff;
                19  : coef = 'hffff;
                20  : coef = 'h7fff;
                21  : coef = 'h0000;
                22  : coef = 'h5555;
                23  : coef = 'haaaa;
                24  : coef = 'hffff;
                25  : coef = 'h7fff;
                26  : coef = 'h0000;
                27  : coef = 'h7fff;
                28  : coef = 'hffff;
                29  : coef = 'haaaa;
                30  : coef = 'h5555;
                31  : coef = 'h0000;
                32  : coef = 'h5555;
                33  : coef = 'haaaa;
                34  : coef = 'hffff;
                35  : coef = 'haaaa;
                36  : coef = 'h5555;
                37  : coef = 'h0000;
                38  : coef = 'h3fff;
                39  : coef = 'h7fff;
                40  : coef = 'hbfff;
                41  : coef = 'hffff;
                42  : coef = 'haaaa;
                43  : coef = 'h5555;
                44  : coef = 'h0000;
                45  : coef = 'h3fff;
                46  : coef = 'h7fff;
                47  : coef = 'hbfff;
                48  : coef = 'hffff;
                49  : coef = 'hbfff;
                50  : coef = 'h7fff;
                51  : coef = 'h3fff;
                52  : coef = 'h0000;
                53  : coef = 'h3fff;
                54  : coef = 'h7fff;
                55  : coef = 'hbfff;
                56  : coef = 'hffff;
                57  : coef = 'hcccc;
                58  : coef = 'h9999;
                59  : coef = 'h6666;
                60  : coef = 'h3333;
                61  : coef = 'h0000;
                62  : coef = 'h3333;
                63  : coef = 'h6666;
                64  : coef = 'h9999;
                65  : coef = 'hcccc;
                66  : coef = 'hffff;
                67  : coef = 'hcccc;
                68  : coef = 'h9999;
                69  : coef = 'h6666;
                70  : coef = 'h3333;
                71  : coef = 'h0000;
                72  : coef = 'h2aaa;
                73  : coef = 'h5555;
                74  : coef = 'h7fff;
                75  : coef = 'haaaa;
                76  : coef = 'hd554;
                77  : coef = 'hffff;
                78  : coef = 'hd554;
                79  : coef = 'haaaa;
                80  : coef = 'h7fff;
                81  : coef = 'h5555;
                82  : coef = 'h2aaa;
                83  : coef = 'h0000;
                84  : coef = 'h2aaa;
                85  : coef = 'h5555;
                86  : coef = 'h7fff;
                87  : coef = 'haaaa;
                88  : coef = 'hd554;
                89  : coef = 'hffff;
                90  : coef = 'hdb6c;
                91  : coef = 'hb6da;
                92  : coef = 'h9248;
                93  : coef = 'h6db6;
                94  : coef = 'h4924;
                95  : coef = 'h2492;
                96  : coef = 'h0000;
                97  : coef = 'h2492;
                98  : coef = 'h4924;
                99  : coef = 'h6db6;
                100 : coef = 'h9248;
                101 : coef = 'hb6da;
                102 : coef = 'hdb6c;
                103 : coef = 'hffff;
                104 : coef = 'hdfff;
                105 : coef = 'hbfff;
                106 : coef = 'h9fff;
                107 : coef = 'h7fff;
                108 : coef = 'h5fff;
                109 : coef = 'h3fff;
                110 : coef = 'h1fff;
                111 : coef = 'h0000;
                112 : coef = 'h1fff;
                113 : coef = 'h3fff;
                114 : coef = 'h5fff;
                115 : coef = 'h7fff;
                116 : coef = 'h9fff;
                117 : coef = 'hbfff;
                118 : coef = 'hdfff;
                119 : coef = 'hffff;
                120 : coef = 'he38d;
                121 : coef = 'hc71b;
                122 : coef = 'haaaa;
                123 : coef = 'h8e38;
                124 : coef = 'h71c6;
                125 : coef = 'h5555;
                126 : coef = 'h38e3;
                127 : coef = 'h1c71;
                128 : coef = 'h0000;
            endcase
        end
    end

    if (BOUNDARYFILE == "boundary_even.hex") begin
        always @(*) begin
            case(boundary_counter)
                0   : boundary = 'h07;
                1   : boundary = 'h09;
                2   : boundary = 'h0c;
                3   : boundary = 'h0f;
                4   : boundary = 'h13;
                5   : boundary = 'h18;
                6   : boundary = 'h1c;
                7   : boundary = 'h22;
                8   : boundary = 'h29;
                9   : boundary = 'h30;
                10  : boundary = 'h38;
                11  : boundary = 'h42;
                12  : boundary = 'h4d;
                13  : boundary = 'h59;
                14  : boundary = 'h67;
                15  : boundary = 'h77;
            endcase
        end
    end else begin
        always @(*) begin
            case(boundary_counter)
                0   : boundary = 'h08;
                1   : boundary = 'h0b;
                2   : boundary = 'h0e;
                3   : boundary = 'h11;
                4   : boundary = 'h15;
                5   : boundary = 'h1a;
                6   : boundary = 'h1f;
                7   : boundary = 'h25;
                8   : boundary = 'h2c;
                9   : boundary = 'h34;
                10  : boundary = 'h3d;
                11  : boundary = 'h47;
                12  : boundary = 'h53;
                13  : boundary = 'h60;
                14  : boundary = 'h6f;
                15  : boundary = 'h80;
            endcase
        end
    end

    initial begin
        // $display("reading from: %s", COEFFILE);
        // $display("reading from: %s", BOUNDARYFILE);
        // $readmemh(COEFFILE, coef);
        // $readmemh(BOUNDARYFILE, boundary);

        // =====================================================================
        // Simulation Only Waveform Dump (.vcd export)
        // =====================================================================
        `ifdef COCOTB_SIM
        `ifndef SCANNED
        `define SCANNED
        $dumpfile ("wave.vcd");
        $dumpvars (0, filterbank_half);
        #1;
        `endif
        `endif
    end

endmodule
