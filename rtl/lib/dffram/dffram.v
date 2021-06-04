// ============================================================================
// Single Port RW DFF RAM
// Design: Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// ============================================================================

module dffram #(
    parameter WIDTH = 32,
    parameter DEPTH = 256
) (
    input                    clk_i,

    input                    wr_en_i,
    input                    en_i,

    input  [ADDR_BW - 1 : 0] addr_i,
    input  [WIDTH - 1 : 0]   data_i,
    output [WIDTH - 1 : 0]   data_o
);

    localparam ADDR_BW = $clog2(DEPTH);

    reg [WIDTH - 1 : 0] read_data;
    reg [WIDTH - 1 : 0] mem [DEPTH - 1 : 0];

    always @(posedge clk_i) begin
        if (en_i) begin
            read_data <= mem[addr_i];
            if (wr_en_i) begin
                mem[addr_i] <= data_i;
            end
        end
    end

    assign data_o = read_data;

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, dffram);
        #1;
    end
    `endif
    `endif
    // ========================================================================

endmodule
