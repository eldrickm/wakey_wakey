// =============================================================================
// Module:       Configuration
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// User address space goes from 0x3000_0000 to 0x7FFF_FFFF
// TODO: Sensitize to cyc_i?
// TODO: Figure out register writes using a mux?
// =============================================================================

module cfg #(
    parameter CONV1_BANK_BW = 3,
    parameter CONV1_ADDR_BW = 3,
    parameter CONV1_VECTOR_BW = 104,
    parameter CONV2_BANK_BW = 3,
    parameter CONV2_ADDR_BW = 4,
    parameter CONV2_VECTOR_BW = 64,
    parameter FC_BANK_BW = 4,
    parameter FC_ADDR_BW = 8,
    parameter FC_BIAS_BW = 32,
    parameter WISHBONE_BASE_ADDR = 32'h30000000
)(
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,

    // wishbone slave ports (wb mi a)
    input                                   wbs_stb_i,
    input                                   wbs_cyc_i,
    input                                   wbs_we_i,
    input         [3  : 0]                  wbs_sel_i,
    input         [31 : 0]                  wbs_dat_i,
    input         [31 : 0]                  wbs_adr_i,
    output reg                              wbs_ack_o,
    output reg    [31 : 0]                  wbs_dat_o,

    // conv1 memory configuration
    output                                  conv1_rd_en_o,
    output                                  conv1_wr_en_o,
    output        [CONV1_BANK_BW - 1 : 0]   conv1_rd_wr_bank_o,
    output        [CONV1_ADDR_BW - 1 : 0]   conv1_rd_wr_addr_o,
    output signed [CONV1_VECTOR_BW - 1 : 0] conv1_wr_data_o,
    input  signed [CONV1_VECTOR_BW - 1 : 0] conv1_rd_data_i,

    // conv2 memory configuration
    output                                  conv2_rd_en_o,
    output                                  conv2_wr_en_o,
    output        [CONV2_BANK_BW - 1 : 0]   conv2_rd_wr_bank_o,
    output        [CONV2_ADDR_BW - 1 : 0]   conv2_rd_wr_addr_o,
    output signed [CONV2_VECTOR_BW - 1 : 0] conv2_wr_data_o,
    input  signed [CONV2_VECTOR_BW - 1 : 0] conv2_rd_data_i,

    // fc memory configuration
    output                                  fc_rd_en_o,
    output                                  fc_wr_en_o,
    output        [FC_BANK_BW - 1 : 0]      fc_rd_wr_bank_o,
    output        [FC_ADDR_BW - 1 : 0]      fc_rd_wr_addr_o,
    output signed [FC_BIAS_BW - 1 : 0]      fc_wr_data_o,
    input  signed [FC_BIAS_BW - 1 : 0]      fc_rd_data_i
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam ADDR   = WISHBONE_BASE_ADDR + 'h00;
    localparam CTRL   = WISHBONE_BASE_ADDR + 'h04;
    localparam DATA_0 = WISHBONE_BASE_ADDR + 'h08;
    localparam DATA_1 = WISHBONE_BASE_ADDR + 'h0C;
    localparam DATA_2 = WISHBONE_BASE_ADDR + 'h10;
    localparam DATA_3 = WISHBONE_BASE_ADDR + 'h14;

    localparam CONV1_WEIGHT0_END = 'h007;
    localparam CONV1_WEIGHT1_END = 'h00F;
    localparam CONV1_WEIGHT2_END = 'h017;
    localparam CONV1_BIAS_END    = 'h01F;
    localparam CONV1_SHIFT_END   = 'h020;

    localparam CONV2_WEIGHT0_END = 'h03F;
    localparam CONV2_WEIGHT1_END = 'h04F;
    localparam CONV2_WEIGHT2_END = 'h05F;
    localparam CONV2_BIAS_END    = 'h06F;
    localparam CONV2_SHIFT_END   = 'h070;



    // =========================================================================
    // Wishbone Addressable Registers
    // =========================================================================
    reg [31 : 0] addr;
    reg [31 : 0] ctrl;
    reg [31 : 0] data_0;
    reg [31 : 0] data_1;
    reg [31 : 0] data_2;
    reg [31 : 0] data_3;

    wire wr_active;
    wire adr_addr;
    wire adr_ctrl;
    wire adr_data_0;
    wire adr_addr_1;
    wire adr_addr_2;
    wire adr_addr_3;

    assign wr_active  = wbs_stb_i && wbs_we_i;
    assign adr_addr   = wbs_adr_i == ADDR;
    assign adr_ctrl   = wbs_adr_i == CTRL;
    assign adr_data_0 = wbs_adr_i == DATA_0;
    assign adr_addr_1 = wbs_adr_i == DATA_1;
    assign adr_addr_2 = wbs_adr_i == DATA_2;
    assign adr_addr_3 = wbs_adr_i == DATA_3;

    wire conv1_sel = addr < ;
    wire conv2_sel = ;
    wire fc_sel = ;

    // =========================================================================
    // Address Register
    // =========================================================================
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            addr <= 'h0;
        end else begin
            addr <= (wr_active && adr_addr) ? wbs_dat_i : addr;
        end
    end

    // =========================================================================
    // Control Register
    // =========================================================================
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            ctrl <= 'h0;
        end else begin
            // self clearing register
            ctrl <= (wr_active && adr_ctrl) ? wbs_dat_i : 0;
        end
    end

    // =========================================================================
    // Data Registers
    // =========================================================================
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            data_0 <= 'h0;
        end else begin
            data_0 <= (wr_active && adr_data_0) ? wbs_dat_i : 0;
        end
    end

    // =========================================================================
    // Wishbone Write
    // =========================================================================
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            addr   <= 'h0;
            ctrl   <= 'h0;
            data_0 <= 'h0;
            data_1 <= 'h0;
            data_2 <= 'h0;
            data_3 <= 'h0;
        end else begin
            if ((wbs_stb_i) && (wbs_we_i)) begin
                case (wbs_adr_i)
                    ADDR: begin
                        addr   <= wbs_dat_i;
                        ctrl   <= ctrl;
                        data_0 <= data_0;
                        data_1 <= data_1;
                        data_2 <= data_2;
                        data_3 <= data_3;
                    end
                    CTRL: begin
                        addr   <= addr;
                        ctrl   <= wbs_dat_i;
                        data_0 <= data_0;
                        data_1 <= data_1;
                        data_2 <= data_2;
                        data_3 <= data_3;
                    end
                    DATA_0: begin
                        addr   <= addr;
                        ctrl   <= ctrl;
                        data_0 <= wbs_dat_i;
                        data_1 <= data_1;
                        data_2 <= data_2;
                        data_3 <= data_3;
                    end
                    DATA_1: begin
                        addr   <= addr;
                        ctrl   <= ctrl;
                        data_0 <= data_0;
                        data_1 <= wbs_dat_i;
                        data_2 <= data_2;
                        data_3 <= data_3;
                    end
                    DATA_2: begin
                        addr   <= addr;
                        ctrl   <= ctrl;
                        data_0 <= data_0;
                        data_1 <= data_1;
                        data_2 <= wbs_dat_i;
                        data_3 <= data_3;
                    end
                    DATA_3: begin
                        addr   <= addr;
                        ctrl   <= ctrl;
                        data_0 <= data_0;
                        data_1 <= data_1;
                        data_2 <= data_2;
                        data_3 <= wbs_dat_i;
                    end
                    default: begin
                        addr   <= addr;
                        ctrl   <= ctrl;
                        data_0 <= data_0;
                        data_1 <= data_1;
                        data_2 <= data_2;
                        data_3 <= data_3;
                    end
                endcase
            end
        end
    end

    // =========================================================================
    // Wishbone Read
    // =========================================================================
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            wbs_dat_o <= 'h0;
        end else begin
            if ((wbs_stb_i) && (~wbs_we_i)) begin
                case (wbs_adr_i)
                    ADDR: begin
                        wbs_dat_o <= addr;
                    end
                    CTRL: begin
                        wbs_dat_o <= ctrl;
                    end
                    DATA_0: begin
                        wbs_dat_o <= data_0;
                    end
                    DATA_1: begin
                        wbs_dat_o <= data_1;
                    end
                    DATA_2: begin
                        wbs_dat_o <= data_2;
                    end
                    DATA_3: begin
                        wbs_dat_o <= data_3;
                    end
                    default: begin
                        wbs_dat_o <= 'h0;
                    end
                endcase
            end
        end
    end

    // =========================================================================
    // Wishbone Acknowledge
    // =========================================================================
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            o_wb_ack <= 1'b0;
        end else begin
            o_wb_ack <= i_wb_stb;
    end

    // ctrl should be self clearing

    // handle store instruction

    // handle load instruction

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, cfg);
      #1;
    end
    `endif

endmodule
