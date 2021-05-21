// =============================================================================
// Module:       Packing
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        
//
// Packs 13 serial bytes into one parallel packet with the first sample in the
// highest order bits and the last sample in the lowest order bits.
// =============================================================================

module packing (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input  signed [I_BW - 1 : 0]            data_i,
    input                                   valid_i,
    input                                   last_i,

    // streaming output
    output  signed [O_BW - 1 : 0]           data_o,
    output                                  valid_o,
    output                                  last_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam I_BW         = 8;
    localparam N_COEF       = 13;
    localparam COUNTER_BW   = $clog2(N_COEF);
    localparam O_BW         = I_BW * N_COEF;

    // =========================================================================
    // Counter
    // =========================================================================
    reg [COUNTER_BW - 1 : 0] counter;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            counter <= 'd0;
        end else begin
            if (last_elem) begin
                counter <= 'd0;
            end else if (valid_i) begin
                counter <= counter + 'd1;
            end else begin
                counter <= 'd0;
            end
        end
    end
    wire last_elem = (counter == N_COEF - 1);
    reg last_elem_q;  // emit result after packing all data
    always @(posedge clk_i) begin
        last_elem_q <= last_elem;
    end

    // =========================================================================
    // Packing data
    // =========================================================================
    reg [I_BW - 1 : 0] packed_arr [N_COEF - 1 : 0];
    genvar i;
    for (i = 0; i < N_COEF; i = i + 1) begin: packed_data
        always @(posedge clk_i) begin
            if (!rst_n_i | !en_i) begin
                packed_arr[i] <= 'd0;
            end else if (valid_i & (counter == i)) begin
                packed_arr[i] <= data_i;
            end else if (valid_i) begin
                packed_arr[i] <= packed_arr[i];
            end else begin
                packed_arr[i] <= 'd0;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o = {packed_arr[0], packed_arr[1], packed_arr[2], packed_arr[3],
                     packed_arr[4], packed_arr[5], packed_arr[6], packed_arr[7],
                     packed_arr[8], packed_arr[9], packed_arr[10],
                     packed_arr[11], packed_arr[12]};
    assign valid_o = (en_i & last_elem_q);
    assign last_o  = last_elem_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    integer j;
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, packing);
        for (j = 0; j < N_COEF; j = j + 1) begin
            $dumpvars (0, packed_arr[j]);
        end
        #1;
    end
    `endif
    `endif

endmodule
