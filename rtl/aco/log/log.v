// =============================================================================
// Module:       Log
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Very simple log, implemented as a leading ones place detector
// Implementation based on leading zeros counter from:
// https://electronics.stackexchange.com/questions/196914/verilog-synthesize-high-speed-leading-zero-count
// =============================================================================

module log (
    // clock and reset
    input                       clk_i,
    input                       rst_n_i,
    input                       en_i,

    // streaming input
    input [I_BW - 1 : 0]        data_i,
    input                       valid_i,
    input                       last_i,

    // streaming output
    output [O_BW - 1 :0]        data_o,
    output                      valid_o,
    output                      last_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam I_BW = 32;
    localparam O_BW = 8;

    // =========================================================================
    // Encoding
    // =========================================================================
    wire [I_BW - 1 : 0] e;
    genvar i;
    generate
        for (i = 0; i < I_BW / 2; i = i + 1) begin: encoding
            enc enc_inst (
                .d(data_i[i*2 + 1 : i*2]),
                .q(e[i*2 + 1 : i*2])
            );
        end
    endgenerate

    // =========================================================================
    // Merging
    // =========================================================================
    // stage a input  vector length: 16 x 2b
    // stage b input  vector length:  8 x 3b
    // stage c input  vector length:  4 x 4b
    // stage d input  vector length:  2 x 5b
    // stage d output vector length:  1 x 6b
    wire [8*3 - 1 : 0] a;  // 24, 8 = 32/4
    wire [4*4 - 1 : 0] b;  // 16, 4 = 24/6
    wire [2*5 - 1 : 0] c;  // 10, 2 = 16/8
    wire [1*6 - 1 : 0] d;  // 6,  1 = 10/10
    generate
        for (i = 0; i < 8; i = i + 1) begin: merge1
            clzi #(
                .N(2)
            ) clzi_1_inst (
                .d(e[i*4 + 3 : i*4]),
                .q(a[i*3 + 2 : i*3])
            );
        end
    endgenerate
    generate
        for (i = 0; i < 4; i = i + 1) begin: merge2
            clzi #(
                .N(3)
            ) clzi_2_inst (
                .d(a[i*6 + 5 : i*6]),
                .q(b[i*4 + 3 : i*4])
            );
        end
    endgenerate
    generate
        for (i = 0; i < 2; i = i + 1) begin: merge3
            clzi #(
                .N(4)
            ) clzi_3_inst (
                .d(b[i*8 + 7 : i*8]),
                .q(c[i*5 + 4 : i*5])
            );
        end
    endgenerate
    clzi #(
        .N(5)
    ) clzi_4_inst (
        .d(c),
        .q(d)
    );
    
    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & valid_i);
    assign data_o  = 'd32 - d;  // leading ones place
    assign last_o  = last_i;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, log);
        #1;
    end
    `endif

endmodule // log

// Encode bits in pairs
module enc
(
   input wire     [1:0]       d,
   output logic   [1:0]       q
);

    // original source:
    // always_comb begin
        // case (d[1:0])
            // 2'b00    :  q = 2'b10;
            // 2'b01    :  q = 2'b01;
            // default  :  q = 2'b00;
        // endcase
    // end
    assign q = (d == 2'b00) ? 2'b10
                            : ((d == 2'b01) ? 2'b01
                                            : 2'b00);

endmodule // enc

// Merge vectors of bits together
module clzi #
(
   // external parameter
   parameter   N = 2,
   // internal parameters
   parameter   WI = 2 * N,
   parameter   WO = N + 1
)
(
   input wire     [WI-1:0]    d,
   output logic   [WO-1:0]    q
);

    // original source:
    // always_comb begin
        // if (d[N - 1 + N] == 1'b0) begin
            // q[WO-1] = (d[N-1+N] & d[N-1]);
            // q[WO-2] = 1'b0;
            // q[WO-3:0] = d[(2*N)-2 : N];
        // end else begin
            // q[WO-1] = d[N-1+N] & d[N-1];
            // q[WO-2] = ~d[N-1];
            // q[WO-3:0] = d[N-2 : 0];
        // end
    // end

    wire leading_zero = (d[N - 1 + N] == 1'b0);
    assign q[WO-1]   = d[N-1+N] & d[N-1];
    assign q[WO-2]   = (leading_zero) ? 1'b0
                                      : ~d[N-1];
    assign q[WO-3:0] = (leading_zero) ? d[(2*N)-2 : N]
                                      : d[N-2 : 0];

endmodule // clzi
