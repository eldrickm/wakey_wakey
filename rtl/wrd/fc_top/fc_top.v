// ============================================================================
// Module:       Fully Connected Layer
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Assumes BIAS_BW > BW
// ============================================================================

module fc_top #(
    parameter I_BW        = 8,
    parameter BIAS_BW     = 16,
    parameter O_BW        = 24,
    parameter FRAME_LEN   = 208,
    parameter NUM_CLASSES = 3,

    // ========================================================================
    // Local Parameters - Do Not Edit
    // ========================================================================
    parameter VECTOR_O_BW = O_BW * NUM_CLASSES,
    parameter ADDR_BW     = $clog2(FRAME_LEN),
    parameter BANK_BW     = $clog2(NUM_CLASSES * 2)
) (
    // clock and reset
    input                               clk_i,
    input                               rst_n_i,

    // streaming input
    input  signed [I_BW - 1 : 0]        data_i,
    input                               valid_i,
    input                               last_i,
    output                              ready_o,

    // streaming output
    output signed [VECTOR_O_BW - 1 : 0] data_o,
    output                              valid_o,
    output                              last_o,
    input                               ready_i,

    // memory configuration
    input                               rd_en_i,
    input                               wr_en_i,
    input         [BANK_BW - 1 : 0]     rd_wr_bank_i,
    input         [ADDR_BW - 1 : 0]     rd_wr_addr_i,
    input  signed [BIAS_BW - 1 : 0]     wr_data_i,
    output signed [BIAS_BW - 1 : 0]     rd_data_o
);

    genvar i;

    // ========================================================================
    // Local Parameters
    // ========================================================================
    // Bitwidth Definitions
    localparam VECTOR_I_BW = I_BW * NUM_CLASSES;
    localparam VECTOR_BIAS_BW = BIAS_BW * NUM_CLASSES;

    // Number of weight banks + bias bank per class
    localparam FRAME_COUNTER_BW = $clog2(FRAME_LEN);
    // ========================================================================

    // ========================================================================
    // Parameter Memory
    // ========================================================================
    wire [VECTOR_I_BW - 1 : 0] fc_mem_data_w;
    wire [VECTOR_BIAS_BW - 1 : 0] fc_mem_data_b;
    wire fc_mem_valid;
    wire fc_mem_last;
    wire fc_mem_ready;

    fc_mem #(
        .BW(I_BW),
        .BIAS_BW(BIAS_BW),
        .FRAME_LEN(FRAME_LEN),
        .NUM_CLASSES(NUM_CLASSES)
    ) fc_mem_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .cycle_en_i(valid_i),

        .rd_en_i(rd_en_i),
        .wr_en_i(wr_en_i),
        .rd_wr_bank_i(rd_wr_bank_i),
        .rd_wr_addr_i(rd_wr_addr_i),
        .wr_data_i(wr_data_i),
        .rd_data_o(rd_data_o),

        .data_w_o(fc_mem_data_w),
        .data_b_o(fc_mem_data_b),
        .valid_o(fc_mem_valid),
        .last_o(fc_mem_last),
        .ready_i(fc_mem_ready)
    );

    // ========================================================================
    // MAC Array
    // ========================================================================
    wire mac_ready0;

    // register stream input array to give fc_mem 1 cycle to ready outputs
    reg signed [I_BW - 1 : 0]        data_i_q;
    reg                              valid_i_q;
    reg                              last_i_q;
    reg                              mac_ready0_q;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            data_i_q  <= 0;
            valid_i_q <= 0;
            mac_ready0_q <= 0;
            last_i_q  <= 0;
        end else begin
            data_i_q  <= data_i;
            valid_i_q <= valid_i;
            mac_ready0_q <= mac_ready0;
            last_i_q  <= last_i;
        end
    end

    mac #(
        .I_BW(I_BW),
        .O_BW(O_BW),
        .BIAS_BW(BIAS_BW),
        .NUM_CLASSES(NUM_CLASSES)
    ) mac_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data0_i(data_i_q),
        .valid0_i(valid_i_q),
        .last0_i(last_i_q),
        .ready0_o(mac_ready0),

        .data1_w_i(fc_mem_data_w),
        .data1_b_i(fc_mem_data_b),
        .valid1_i(fc_mem_valid),
        .last1_i(fc_mem_last),
        .ready1_o(fc_mem_ready),

        .data_o(data_o),
        .valid_o(valid_o),
        .last_o(last_o),
        .ready_i(ready_i)
    );

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, fc_top);
        #1;
    end
    `endif
    `endif

endmodule
