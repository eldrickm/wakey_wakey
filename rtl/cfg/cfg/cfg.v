// =============================================================================
// Module:       Configuration
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// User address space goes from 0x3000_0000 to 0x7FFF_FFFF
// TODO: Sensitize to cyc_i?
// TODO: Adjust wishbone ack for Store and Load on CTRL?
// =============================================================================

module cfg #(
    parameter CONV1_BANK_BW = 3,
    parameter CONV1_ADDR_BW = 3,
    parameter CONV1_VECTOR_BW = 104,
    parameter CONV2_BANK_BW = 3,
    parameter CONV2_ADDR_BW = 4,
    parameter CONV2_VECTOR_BW = 64,
    parameter FC_BANK_BW = 2,
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
    // Wishbone Address Space
    // =========================================================================
    localparam ADDR   = WISHBONE_BASE_ADDR + 'h00;
    localparam CTRL   = WISHBONE_BASE_ADDR + 'h04;
    localparam DATA_0 = WISHBONE_BASE_ADDR + 'h08;
    localparam DATA_1 = WISHBONE_BASE_ADDR + 'h0C;
    localparam DATA_2 = WISHBONE_BASE_ADDR + 'h10;
    localparam DATA_3 = WISHBONE_BASE_ADDR + 'h14;


    // =========================================================================
    // Wakey Wakey Address Space
    // =========================================================================
    localparam CONV1_WEIGHT0_START = 'h000;
    localparam CONV1_WEIGHT0_END   = 'h007;
    localparam CONV1_WEIGHT1_START = 'h010;
    localparam CONV1_WEIGHT1_END   = 'h017;
    localparam CONV1_WEIGHT2_START = 'h020;
    localparam CONV1_WEIGHT2_END   = 'h027;
    localparam CONV1_BIAS_START    = 'h030;
    localparam CONV1_BIAS_END      = 'h037;
    localparam CONV1_SHIFT_START   = 'h040;
    localparam CONV1_SHIFT_END     = 'h040;

    localparam CONV2_WEIGHT0_START = 'h050;
    localparam CONV2_WEIGHT0_END   = 'h05F;
    localparam CONV2_WEIGHT1_START = 'h060;
    localparam CONV2_WEIGHT1_END   = 'h06F;
    localparam CONV2_WEIGHT2_START = 'h070;
    localparam CONV2_WEIGHT2_END   = 'h07F;
    localparam CONV2_BIAS_START    = 'h080;
    localparam CONV2_BIAS_END      = 'h08F;
    localparam CONV2_SHIFT_START   = 'h090;
    localparam CONV2_SHIFT_END     = 'h090;

    localparam FC_WEIGHT0_START    = 'h100;
    localparam FC_WEIGHT0_END      = 'h1CF;
    localparam FC_WEIGHT1_START    = 'h200;
    localparam FC_WEIGHT1_END      = 'h2CF;
    localparam FC_BIAS_0_START     = 'h300;
    localparam FC_BIAS_0_END       = 'h300;
    localparam FC_BIAS_1_START     = 'h400;
    localparam FC_BIAS_1_END       = 'h400;


    // =========================================================================
    // Wishbone Addressable Registers
    // =========================================================================
    reg [31 : 0] addr;
    reg [31 : 0] ctrl;
    reg [31 : 0] data_0;
    reg [31 : 0] data_1;
    reg [31 : 0] data_2;
    reg [31 : 0] data_3;


    // =========================================================================
    // Wishbone Addressing Logic
    // =========================================================================
    // shorthand for this peripheral is selected and we're writing
    wire wr_active  = wbs_stb_i && wbs_we_i;

    // shorthand for wishbone addressable registers being addressed
    wire adr_addr   = wbs_adr_i == ADDR;
    wire adr_ctrl   = wbs_adr_i == CTRL;
    wire adr_data_0 = wbs_adr_i == DATA_0;
    wire adr_data_1 = wbs_adr_i == DATA_1;
    wire adr_data_2 = wbs_adr_i == DATA_2;
    wire adr_data_3 = wbs_adr_i == DATA_3;


    // =========================================================================
    // Module Selection Logic
    // =========================================================================
    wire conv1_sel = (addr >= CONV1_WEIGHT0_START) && (addr <= CONV1_SHIFT_END);
    wire conv2_sel = (addr >= CONV2_WEIGHT0_START) && (addr <= CONV2_SHIFT_END);
    wire fc_sel    = (addr >= FC_WEIGHT0_START)    && (addr <= FC_BIAS_1_END);


    // =========================================================================
    // Bank Selection Logic
    // =========================================================================
    // conv1 address space is laid out so we can use the upper 4 bits in the
    // LSB to select the bank
    assign conv1_rd_wr_bank_o = addr[6:4];

    // conv2 address space is laid out so we can use the upper 4 bits in the
    // LSB, minus 5, to select the bank
    assign conv2_rd_wr_bank_o = addr[6:4] - 3'd5;

    // fc address space is laid out so we can use the lower 4 bits in the 2nd
    // byte, minus 1, to select the bank
    assign fc_rd_wr_bank_o = addr[11:8] - 4'd1;


    // =========================================================================
    // Address Assignment
    // =========================================================================
    assign conv1_rd_wr_addr_o = addr[2:0];
    assign conv2_rd_wr_addr_o = addr[3:0];
    assign fc_rd_wr_addr_o    = addr[7:0];

    // =========================================================================
    // Data Assignment
    // =========================================================================
    assign conv1_wr_data_o = {data_3[7:0], data_2, data_1, data_0};
    assign conv2_wr_data_o =                      {data_1, data_0};
    assign fc_wr_data_o    =                              {data_0};

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
    // Wishbone Read
    // =========================================================================
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            wbs_dat_o <= 'h0;
        end else begin
            if (wbs_stb_i) begin
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
            wbs_ack_o <= 1'b0;
        end else begin
            wbs_ack_o <= wbs_stb_i;
        end
    end


    // =========================================================================
    // Store
    // =========================================================================
    assign conv1_wr_en_o = (ctrl == 'h1) && (conv1_sel);
    assign conv2_wr_en_o = (ctrl == 'h1) && (conv2_sel);
    assign fc_wr_en_o    = (ctrl == 'h1) && (fc_sel);


    // =========================================================================
    // Load
    // =========================================================================
    assign conv1_rd_en_o = (ctrl == 'h2) && (conv1_sel);
    assign conv2_rd_en_o = (ctrl == 'h2) && (conv2_sel);
    assign fc_rd_en_o    = (ctrl == 'h2) && (fc_sel);

    reg conv1_rd_en_d;
    reg conv2_rd_en_d;
    reg fc_rd_en_d;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            conv1_rd_en_d <= 1'b0;
            conv2_rd_en_d <= 1'b0;
            fc_rd_en_d    <= 1'b0;
        end else begin
            conv1_rd_en_d <= conv1_rd_en_o;
            conv2_rd_en_d <= conv2_rd_en_o;
            fc_rd_en_d    <= fc_rd_en_o;
        end
    end


    // =========================================================================
    // Data Registers
    // =========================================================================
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            data_0 <= 'h0;
            data_1 <= 'h0;
            data_2 <= 'h0;
            data_3 <= 'h0;
        end else begin
            data_0 <= (wr_active && adr_data_0) ?   wbs_dat_i:
                      (conv1_rd_en_d) ? conv1_rd_data_i[31:0]:
                      (conv2_rd_en_d) ? conv2_rd_data_i[31:0]:
                      (fc_rd_en_d)    ?    fc_rd_data_i[31:0]:
                      data_0;
            data_1 <= (wr_active && adr_data_1) ?    wbs_dat_i:
                      (conv1_rd_en_d) ? conv1_rd_data_i[63:32]:
                      (conv2_rd_en_d) ? conv2_rd_data_i[63:32]:
                      // (fc_rd_en_d)    ? 'h0:
                      data_1;
            data_2 <= (wr_active && adr_data_2) ?    wbs_dat_i:
                      (conv1_rd_en_d) ? conv1_rd_data_i[95:64]:
                      // (conv2_rd_en_d) ? 'h0:
                      // (fc_rd_en_d)    ? 'h0:
                      data_2;
            data_3 <= (wr_active && adr_data_3) ?     wbs_dat_i:
                      (conv1_rd_en_d) ? {24'b0, conv1_rd_data_i[103:96]}:
                      // (conv2_rd_en_d) ? 'h0:
                      // (fc_rd_en_d)    ? 'h0:
                      data_3;
        end
    end


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
