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
    wire at_boundary = (boundary[boundary_counter] == elem_counter);
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
                sum <= sum + (data_i * coef[elem_counter]);
            end else begin
                sum <= 'd0;
            end
        end
    end

    wire [INTERNAL_BW - 1 : 0] sum_result = sum + (data_i * coef[elem_counter]);

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & at_boundary);
    assign data_o = sum_result >> COEF_BW;
    assign last_o = last_i;

    // =========================================================================
    // ROM Memories for filterbank coefficients and boundary indices
    // =========================================================================
    reg [COEF_BW - 1 : 0] coef [0 : INPUT_LEN - 1];  // filters 0,2,...30 (even)
                                                     // or      1,3,...31 (odd)
    reg [BOUNDARY_BW - 1 : 0] boundary [0 : NUM_BOUNDARY - 1];  // boundaries
    initial begin
        $display("reading from: %s", COEFFILE);
        $display("reading from: %s", BOUNDARYFILE);
        $readmemh(COEFFILE, coef);
        $readmemh(BOUNDARYFILE, boundary);

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
