// =============================================================================
// Module:       Wakey Wakey
// Design:       Eldrick Millares & Matthew Pauly
// Verification: Eldrick Millares & Matthew Pauly
// Notes:
// =============================================================================

module wakey_wakey (
    // clock and reset
    input           clk_i,
    input           rst_n_i,

    // wishbone slave ports (wb mi a)
    input           wbs_stb_i,
    input           wbs_cyc_i,
    input           wbs_we_i,
    input  [3  : 0] wbs_sel_i,
    input  [31 : 0] wbs_dat_i,
    input  [31 : 0] wbs_adr_i,
    output          wbs_ack_o,
    output [31 : 0] wbs_dat_o,

    // microphone i/o
    input           pdm_data_i,
    output          pdm_clk_o,
    input           vad_i,  // voice activity detection

    // wake output
    output wake_o
);
    localparam F_SYSTEM_CLK = 16000000;

    // =========================================================================
    // CFG - System Configuration
    // =========================================================================
    localparam CONV1_BANK_BW = 3;
    localparam CONV1_ADDR_BW = 3;
    localparam CONV1_VECTOR_BW = 104;
    localparam CONV2_BANK_BW = 3;
    localparam CONV2_ADDR_BW = 4;
    localparam CONV2_VECTOR_BW = 64;
    localparam FC_BANK_BW = 2;
    localparam FC_ADDR_BW = 8;
    localparam FC_BIAS_BW = 32;
    localparam WISHBONE_BASE_ADDR = 32'h30000000;

    // conv1 memory configuration
    wire                                  conv1_rd_en;
    wire                                  conv1_wr_en;
    wire        [CONV1_BANK_BW - 1 : 0]   conv1_rd_wr_bank;
    wire        [CONV1_ADDR_BW - 1 : 0]   conv1_rd_wr_addr;
    wire signed [CONV1_VECTOR_BW - 1 : 0] conv1_wr_data;
    wire signed [CONV1_VECTOR_BW - 1 : 0] conv1_rd_data;

    // conv2 memory configuration
    wire                                  conv2_rd_en;
    wire                                  conv2_wr_en;
    wire        [CONV2_BANK_BW - 1 : 0]   conv2_rd_wr_bank;
    wire        [CONV2_ADDR_BW - 1 : 0]   conv2_rd_wr_addr;
    wire signed [CONV2_VECTOR_BW - 1 : 0] conv2_wr_data;
    wire signed [CONV2_VECTOR_BW - 1 : 0] conv2_rd_data;

    // fc memory configuration
    wire                                  fc_rd_en;
    wire                                  fc_wr_en;
    wire        [FC_BANK_BW - 1 : 0]      fc_rd_wr_bank;
    wire        [FC_ADDR_BW - 1 : 0]      fc_rd_wr_addr;
    wire signed [FC_BIAS_BW - 1 : 0]      fc_wr_data;
    wire signed [FC_BIAS_BW - 1 : 0]      fc_rd_data;

    // cfg #(
    //     .CONV1_BANK_BW(CONV1_BANK_BW),
    //     .CONV1_ADDR_BW(CONV1_ADDR_BW),
    //     .CONV1_VECTOR_BW(CONV1_VECTOR_BW),
    //     .CONV2_BANK_BW(CONV2_BANK_BW),
    //     .CONV2_ADDR_BW(CONV2_ADDR_BW),
    //     .CONV2_VECTOR_BW(CONV2_VECTOR_BW),
    //     .FC_BANK_BW(FC_BANK_BW),
    //     .FC_ADDR_BW(FC_ADDR_BW),
    //     .FC_BIAS_BW(FC_BIAS_BW),
    //     .WISHBONE_BASE_ADDR(WISHBONE_BASE_ADDR)
    // ) cfg_inst (
    //     // clock and reset
    //     .clk_i(clk_i),
    //     .rst_n_i(rst_n_i),
    //
    //     // wishbone slave ports (wb mi a)
    //     .wbs_stb_i(wbs_stb_i),
    //     .wbs_cyc_i(wbs_cyc_i),
    //     .wbs_we_i(wbs_we_i),
    //     .wbs_sel_i(wbs_sel_i),
    //     .wbs_dat_i(wbs_dat_i),
    //     .wbs_adr_i(wbs_adr_i),
    //     .wbs_ack_o(wbs_ack_o),
    //     .wbs_dat_o(wbs_dat_o),
    //
    //     // conv1 memory configuration
    //     .conv1_rd_en_o(conv1_rd_en),
    //     .conv1_wr_en_o(conv1_wr_en),
    //     .conv1_rd_wr_bank_o(conv1_rd_wr_bank),
    //     .conv1_rd_wr_addr_o(conv1_rd_wr_addr),
    //     .conv1_wr_data_o(conv1_wr_data),
    //     .conv1_rd_data_i(conv1_rd_data),
    //
    //     // conv2 memory configuration
    //     .conv2_rd_en_o(conv2_rd_en),
    //     .conv2_wr_en_o(conv2_wr_en),
    //     .conv2_rd_wr_bank_o(conv2_rd_wr_bank),
    //     .conv2_rd_wr_addr_o(conv2_rd_wr_addr),
    //     .conv2_wr_data_o(conv2_wr_data),
    //     .conv2_rd_data_i(conv2_rd_data),
    //
    //     // fc memory configuration
    //     .fc_rd_en_o(fc_rd_en),
    //     .fc_wr_en_o(fc_wr_en),
    //     .fc_rd_wr_bank_o(fc_rd_wr_bank),
    //     .fc_rd_wr_addr_o(fc_rd_wr_addr),
    //     .fc_wr_data_o(fc_wr_data),
    //     .fc_rd_data_i(fc_rd_data)
    // );

    // =========================================================================
    // CTL - Pipeline control
    // =========================================================================
    wire pipeline_en;
    wire wake_valid;  // driven by WRD

    ctl #(
        .F_SYSTEM_CLK(F_SYSTEM_CLK)
    ) ctl_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .vad_i(vad_i),

        .wake_valid_i(wake_valid),

        .en_o(pipeline_en)
    );

    assign wake_o = pipeline_en;

    // =========================================================================
    // DFE - Digital Front End
    // =========================================================================
    localparam DFE_OUTPUT_BW = 8;

    wire [DFE_OUTPUT_BW - 1 : 0] dfe_data;
    wire                         dfe_valid;

    // dfe dfe_inst (
    //     // clock, reset, and enable
    //     .clk_i(clk_i),
    //     .rst_n_i(rst_n_i),
    //     // TODO: Activate Pin hooks up here
    //     .en_i(pipeline_en),
    //
    //     // pdm input
    //     .pdm_data_i(pdm_data_i),
    //
    //     // pdm clock output
    //     .pdm_clk_o(pdm_clk_o),
    //
    //     // streaming output
    //     .data_o(dfe_data),
    //     .valid_o(dfe_valid)
    // );

    // =========================================================================
    // ACO - Acoustic Featurizer
    // =========================================================================
    localparam ACO_OUTPUT_BW = 8 * 13;

    wire [ACO_OUTPUT_BW - 1 : 0] aco_data;
    wire                         aco_valid;
    wire                         aco_last;

    // aco aco_inst (
    //     // clock, reset, and enable
    //     .clk_i(clk_i),
    //     .rst_n_i(rst_n_i),
    //     .en_i(pipeline_en),
    //
    //     // streaming input
    //     .data_i(dfe_data),
    //     .valid_i(dfe_valid),
    //
    //     // streaming output
    //     .data_o(aco_data),
    //     .valid_o(aco_valid),
    //     .last_o(aco_last)
    // );

    // =========================================================================
    // WRD - Word Recognition DNN Accelerator Module
    // =========================================================================
    wire wrd_ready;

    // wrd wrd_inst (
    //     // clock and reset
    //     .clk_i(clk_i),
    //     .rst_n_i(rst_n_i & pipeline_en),
    //
    //     // streaming input
    //     .data_i(aco_data),
    //     .valid_i(aco_valid),
    //     .last_i(aco_last),
    //     .ready_o(wrd_ready),
    //
    //     // wake pin
    //     .wake_o(wake_o),
    //     .wake_valid(wake_valid),
    //
    //     // conv1 memory configuration
    //     .conv1_rd_en_i(conv1_rd_en),
    //     .conv1_wr_en_i(conv1_wr_en),
    //     .conv1_rd_wr_bank_i(conv1_rd_wr_bank),
    //     .conv1_rd_wr_addr_i(conv1_rd_wr_addr),
    //     .conv1_wr_data_i(conv1_wr_data),
    //     .conv1_rd_data_o(conv1_rd_data),
    //
    //     // conv2 memory configuration
    //     .conv2_rd_en_i(conv2_rd_en),
    //     .conv2_wr_en_i(conv2_wr_en),
    //     .conv2_rd_wr_bank_i(conv2_rd_wr_bank),
    //     .conv2_rd_wr_addr_i(conv2_rd_wr_addr),
    //     .conv2_wr_data_i(conv2_wr_data),
    //     .conv2_rd_data_o(conv2_rd_data),
    //
    //     // fc memory configuration
    //     .fc_rd_en_i(fc_rd_en),
    //     .fc_wr_en_i(fc_wr_en),
    //     .fc_rd_wr_bank_i(fc_rd_wr_bank),
    //     .fc_rd_wr_addr_i(fc_rd_wr_addr),
    //     .fc_wr_data_i(fc_wr_data),
    //     .fc_rd_data_o(fc_rd_data)
    // );

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, wakey_wakey);
      #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Configuration
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// User address space goes from 0x3000_0000 to 0x7FFF_FFFF
// TODO: Sensitize to cyc_i?
// TODO: Adjust wishbone ack for Store and Load on CTRL?
// TODO: Remove technically unecessary mux to zeros in Data Registers
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
                      (fc_rd_en_d)    ? 'h0:
                      data_1;
            data_2 <= (wr_active && adr_data_2) ?    wbs_dat_i:
                      (conv1_rd_en_d) ? conv1_rd_data_i[95:64]:
                      (conv2_rd_en_d) ? 'h0:
                      (fc_rd_en_d)    ? 'h0:
                      data_2;
            data_3 <= (wr_active && adr_data_3) ?     wbs_dat_i:
                      (conv1_rd_en_d) ? {24'b0, conv1_rd_data_i[103:96]}:
                      (conv2_rd_en_d) ? 'h0:
                      (fc_rd_en_d)    ? 'h0:
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
// =============================================================================
// Module:       CTL
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Top level module for pipeline control.
// =============================================================================

module ctl # (
    parameter F_SYSTEM_CLK = 100  // 100 is used for unit test bench
) (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,

    // voice activity input 
    input                                   vad_i,

    // wake valid
    input                                   wake_valid_i,

    // enable output
    output                                  en_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam COUNT_CYCLES   = $rtoi(0.05 * F_SYSTEM_CLK);
    localparam COUNTER_BW     = $clog2(COUNT_CYCLES + 1);

    // =========================================================================
    // State Machine
    //
    // STATE_IDLE:              Waiting for voice activity on vad_i.
    // STATE_ON:                Wait for a falling edge on wake_valid_i
    //                            indicating that an inference just finished.
    // STATE_TIMEOUT:           Wait until 50ms has passed after turning off
    //                            pipeline and pdm clk before checking VAD
    //                            again.
    // =========================================================================
    localparam STATE_IDLE               = 2'd0,
               STATE_ON                 = 2'd1,
               STATE_TIMEOUT            = 2'd2;

    reg [1 : 0] state;
    reg [COUNTER_BW - 1 : 0] counter;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            state <= STATE_IDLE;
            counter <= 'd0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    state   <= (vad_i) ? STATE_ON : STATE_IDLE;
                    counter <= 'd0;
                end
                STATE_ON: begin
                    state   <= (wake_valid_falling_edge) ? STATE_TIMEOUT
                                                         : STATE_ON;
                    counter <= 'd0;
                end
                STATE_TIMEOUT: begin
                    state   <= (counter >= COUNT_CYCLES) ? STATE_IDLE
                                                         : STATE_TIMEOUT;
                    counter <= counter + 'd1;
                end
                default: begin
                    state   <= STATE_IDLE;
                    counter <= 'd0;
                end
            endcase
        end
    end

    // =========================================================================
    // Falling Edge Detection for wake_valid_i
    // =========================================================================
    reg wake_valid_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            wake_valid_q <= 'd0;
        end else begin
            wake_valid_q <= wake_valid_i;
        end
    end
    wire wake_valid_falling_edge = (wake_valid_q & !wake_valid_i);

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign en_o = (state == STATE_ON) ? 'd1 : 'd0;

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, ctl);
        #1;
    end
    `endif
    `endif

endmodule
// ============================================================================
// Module:       Maximum
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// TODO: Hard coded for 2 elements - can we parameterize the one-hot compare?
// ============================================================================

module argmax #(
    parameter I_BW = 24
) (
    // clock and reset
    input                                       clk_i,
    input                                       rst_n_i,

    // streaming input
    input  signed [(VECTOR_LEN * I_BW) - 1 : 0] data_i,
    input                                       valid_i,
    input                                       last_i,
    output                                      ready_o,

    // streaming output
    output signed [VECTOR_LEN - 1 : 0]          data_o,
    output                                      valid_o,
    output                                      last_o,
    input                                       ready_i
);

    genvar i;

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam VECTOR_LEN = 2;

    // =========================================================================
    // Input Unpacking
    // =========================================================================
    wire signed [I_BW - 1 : 0] data_arr [VECTOR_LEN - 1 : 0];
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: unpack_inputs
        assign data_arr[i] = data_i[(i + 1) * I_BW - 1 : i * I_BW];
    end

    // =========================================================================
    // Max
    // =========================================================================
    wire [VECTOR_LEN - 1 : 0] argmax_one_hot;
    reg  [VECTOR_LEN - 1 : 0] argmax_one_hot_q;

    assign argmax_one_hot = (data_arr[0] > data_arr[1]) ? 'b01 : 'b10;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            argmax_one_hot_q <= 'd0;
        end else begin
            argmax_one_hot_q <= argmax_one_hot;
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    // register all outputs
    reg valid_q, last_q, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q <= 'b0;
            last_q  <= 'b0;
            ready_q <= 'b0;
        end else begin
            valid_q <= valid_i;
            last_q  <= last_i;
            ready_q <= ready_i;
        end
    end

    assign data_o   = argmax_one_hot_q;
    assign valid_o  = valid_q;
    assign last_o   = last_q;
    assign ready_o  = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, argmax);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Convolution Memory
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// TODO: Implement rd_data_o for reading memories
//
// Stores weights, biases, and shifts in different banks, numbered like so:
// [0, NUM_FILTERS-1] : Kernel weights for nth output channel
// [NUM_FILTERS]      : Bias terms for each kernel
// [NUM_FILTERS+1]    : Global shift applied to all outputs of this convolution
// =============================================================================

module conv_mem #(
    parameter BW          = 8,
    parameter BIAS_BW     = 32,
    parameter SHIFT_BW    = $clog2(BIAS_BW),
    parameter FRAME_LEN   = 50,
    parameter VECTOR_LEN  = 13,
    parameter NUM_FILTERS = 8
) (
    // clock and reset
    input                             clk_i,
    input                             rst_n_i,

    // control
    input                             cycle_en_i,

    // memory configuration
    input                             rd_en_i,
    input                             wr_en_i,
    input         [BANK_BW - 1 : 0]   rd_wr_bank_i,
    input         [ADDR_BW - 1 : 0]   rd_wr_addr_i,
    input  signed [VECTOR_BW - 1 : 0] wr_data_i,
    output signed [VECTOR_BW - 1 : 0] rd_data_o,

    // streaming output
    output signed [VECTOR_BW - 1 : 0] data0_o,
    output signed [VECTOR_BW - 1 : 0] data1_o,
    output signed [VECTOR_BW - 1 : 0] data2_o,
    output signed [BIAS_BW - 1 : 0]   bias_o,
    output        [SHIFT_BW - 1 : 0]  shift_o,
    output                            valid_o,
    output                            last_o,
    input                             ready_i
);

    genvar i;

    // =========================================================================
    // Local Parameters
    // =========================================================================
    // This unit is hard coded for width 3 filters
    localparam FILTER_LEN = 3;

    // Bitwidth Definitions
    localparam VECTOR_BW = VECTOR_LEN * BW;
    localparam ADDR_BW   = $clog2(NUM_FILTERS);
    // Number of weight banks + bias bank + shift bank
    localparam BANK_BW   = $clog2(FILTER_LEN + 2);
    localparam FRAME_COUNTER_BW = $clog2(FRAME_LEN);
    localparam FILTER_COUNTER_BW = $clog2(NUM_FILTERS);

    // ========================================================================
    // Convolution Memory Controller
    // ========================================================================
    // Define States
    reg [FRAME_COUNTER_BW - 1 : 0] frame_counter;
    reg [FILTER_COUNTER_BW - 1 : 0] filter_counter;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            frame_counter <= 0;
            filter_counter <= 0;
        end else begin
            if (cycle_en_i) begin
                frame_counter <= (frame_counter < FRAME_LEN - 1) ?
                                  frame_counter + 'd1 : 'd0;
                filter_counter <= (frame_counter == FRAME_LEN - 1) ?
                                    ((filter_counter < NUM_FILTERS - 1) ?
                                     filter_counter + 1 : 'd0)
                                  : filter_counter;
            end else begin
                frame_counter <= frame_counter;
                filter_counter <= filter_counter;
            end
        end
    end

    // ========================================================================
    // Weight Memories
    // ========================================================================
    wire weight_en;
    wire                     weight_wr_en    [NUM_FILTERS - 1 : 0];
    wire [VECTOR_BW - 1 : 0] weight_data_in;
    wire [ADDR_BW - 1 : 0]   weight_addr;
    wire [VECTOR_BW - 1 : 0] weight_data_out [NUM_FILTERS - 1 : 0];

    assign weight_en      = (wr_en_i | rd_en_i | cycle_en_i);
    for (i = 0; i < FILTER_LEN; i = i + 1) begin: weight_banks_wr_en
        assign weight_wr_en[i] = (wr_en_i) & (rd_wr_bank_i == i);
    end
    assign weight_data_in = (wr_en_i) ? wr_data_i : 'd0;
    assign weight_addr    = (wr_en_i | rd_en_i) ? rd_wr_addr_i : filter_counter;

    for (i = 0; i < FILTER_LEN; i = i + 1) begin: weight_banks
        dffram #(
            .WIDTH(VECTOR_BW),
            .DEPTH(NUM_FILTERS)
        ) weight_ram_inst (
            .clk_i(clk_i),

            .wr_en_i(weight_wr_en[i]),
            .en_i(weight_en),

            .addr_i(weight_addr),
            .data_i(weight_data_in),
            .data_o(weight_data_out[i])
        );
    end

    // ========================================================================
    // Bias Memory
    // ========================================================================
    wire bias_en;
    wire                   bias_wr_en;
    wire [BIAS_BW - 1 : 0] bias_data_in;
    wire [ADDR_BW - 1 : 0] bias_addr;
    wire [BIAS_BW - 1 : 0] bias_data_out;

    assign bias_en      = (wr_en_i | rd_en_i | cycle_en_i);
    assign bias_wr_en   = (wr_en_i) & (rd_wr_bank_i == FILTER_LEN);
    assign bias_data_in = (wr_en_i) ? wr_data_i[BIAS_BW - 1 : 0] : 'd0;
    assign bias_addr    = (wr_en_i | rd_en_i) ? rd_wr_addr_i : filter_counter;

    dffram #(
        .WIDTH(BIAS_BW),
        .DEPTH(NUM_FILTERS)
    ) bias_ram_inst (
        .clk_i(clk_i),

        .wr_en_i(bias_wr_en),
        .en_i(bias_en),

        .addr_i(bias_addr),
        .data_i(bias_data_in),
        .data_o(bias_data_out)
    );

    // ========================================================================
    // Shift Memory
    // ========================================================================
    // wire shift_en;
    wire                   shift_wr_en;
    wire [SHIFT_BW - 1 : 0] shift_data_in;
    reg [SHIFT_BW - 1 : 0] shift_data_out;

    // assign shift_en      = (wr_en_i | rd_en_i | cycle_en_i);
    assign shift_wr_en   = (wr_en_i) & (rd_wr_bank_i == FILTER_LEN + 1);
    assign shift_data_in = (wr_en_i) ? wr_data_i[SHIFT_BW - 1 : 0] : 'd0;

    always @(posedge clk_i) begin
        if (shift_wr_en) begin
            shift_data_out <= shift_data_in;
        end else begin
            shift_data_out <= shift_data_out;
        end
    end

    // ========================================================================
    // Read Data Assignment
    // ========================================================================
    reg [BANK_BW - 1 : 0] rd_wr_bank_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            rd_wr_bank_q <= 'b0;
        end else begin
            rd_wr_bank_q <= rd_wr_bank_i;
        end
    end

    // build array of all the output data, properly padded, to mux to rd_data_o
    wire [VECTOR_BW - 1 : 0] out_data_arr [FILTER_LEN + 1 : 0];

    for (i = 0; i < FILTER_LEN; i = i + 1) begin: weight_banks_out_data_arr
        assign out_data_arr[i] = weight_data_out[i];
    end
    assign out_data_arr[FILTER_LEN] = {{{VECTOR_BW - BIAS_BW}{1'b0}},
                                       bias_data_out};
    assign out_data_arr[FILTER_LEN + 1] = {{{VECTOR_BW - SHIFT_BW}{1'b0}},
                                           shift_data_out};

    assign rd_data_o = out_data_arr[rd_wr_bank_q];

    // ========================================================================
    // Output Assignment
    // ========================================================================
    reg cycle_en_i_q;
    always @(posedge clk_i) begin
        cycle_en_i_q <= cycle_en_i;
    end

    reg frame_last;
    always @(posedge clk_i) begin
        frame_last <= (frame_counter == FRAME_LEN - 1);
    end

    assign data0_o = weight_data_out[0];
    assign data1_o = weight_data_out[1];
    assign data2_o = weight_data_out[2];
    assign bias_o  = bias_data_out;
    assign shift_o  = shift_data_out;
    assign valid_o = cycle_en_i_q;
    assign last_o  = valid_o & frame_last;

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, conv_mem);
        #1;
    end
    `endif

endmodule
// ============================================================================
// Module:       Convolution Serial In, Parallel Out
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// TODO: Handle Full and Empty
// ============================================================================

module conv_sipo #(
    parameter BW         = 8,
    parameter FRAME_LEN  = 50,
    parameter VECTOR_LEN = 8
) (
    // clock and reset
    input                      clk_i,
    input                      rst_n_i,

    // streaming input
    input  signed [BW - 1 : 0] data_i,
    input                      valid_i,
    input                      last_i,
    output                     ready_o,
 
    // streaming output
    output [VECTOR_BW - 1 : 0] data_o,
    output                     valid_o,
    output                     last_o,
    input                      ready_i
);

    genvar i;

    // ========================================================================
    // Local Parameters
    // ========================================================================
    // Bitwidth Definitions
    localparam VECTOR_BW  = VECTOR_LEN * BW;
    localparam COUNTER_BW = $clog2(FRAME_LEN);

    // =========================================================================
    // Control Logic
    // =========================================================================
    localparam STATE_IDLE   = 2'd0,
               STATE_OUTPUT = 2'd1;

    reg [1:0] state;
    reg [COUNTER_BW - 1 : 0] counter;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            counter <= 'd0;
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    counter <= 'd0;
                    state   <= ((fifo_sel == {{VECTOR_LEN - 1{1'b0}}, 1'b1})
                               && (last_i)) ? STATE_OUTPUT : STATE_IDLE;
                end
                STATE_OUTPUT: begin
                    counter <= counter + 'd1;
                    state   <= (counter == FRAME_LEN - 1) ? STATE_IDLE :
                                                            STATE_OUTPUT;
                end
                default: begin
                    counter <= 'd0;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

    reg [VECTOR_LEN - 1 : 0] fifo_sel;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            fifo_sel <= {1'b1, {VECTOR_LEN - 1{1'b0}}};
        end else begin
            fifo_sel <= (last_i & valid_i) ?
                        {fifo_sel[0], fifo_sel[VECTOR_LEN - 1 : 1]}
                        : fifo_sel;
        end
    end

    // =========================================================================
    // FIFO Banks
    // =========================================================================
    wire [BW - 1 : 0]         fifo_din;
    wire [BW - 1 : 0]         fifo_dout [VECTOR_LEN - 1 : 0];
    wire [VECTOR_LEN - 1 : 0] fifo_enq;
    wire fifo_deq;

    assign fifo_din = data_i;
    assign fifo_deq = (state == STATE_OUTPUT);
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: create_sipo_fifo
        assign fifo_enq[i] = fifo_sel[i] && valid_i;
        fifo #(
            .DATA_WIDTH(BW),
            .FIFO_DEPTH(FRAME_LEN)
        ) fifo_inst (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            .enq_i(fifo_enq[i]),
            .deq_i(fifo_deq),

            .din_i(fifo_din),
            .dout_o(fifo_dout[i]),

            .full_o_n(),
            .empty_o_n()
        );
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    // register all outputs
    reg ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            ready_q <= 'b0;
        end else begin
            ready_q <= ready_i;
        end
    end

    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: pack_output
        assign data_o[(i + 1) * BW - 1 : i * BW] = fifo_dout[i];
    end

    assign valid_o = (state == STATE_OUTPUT);
    assign ready_o = ready_q;
    assign last_o  = (counter == FRAME_LEN - 1);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, conv_sipo);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       1D Convolution
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Constraint: FRAME_LEN > FILTER_LEN
// Constraint: FILTER_LEN == 3
// TODO: Deal with ready's / backpressure
// =============================================================================

module conv_top #(
    parameter FRAME_LEN   = 50,  // output frame length
    parameter VECTOR_LEN  = 13,
    parameter NUM_FILTERS = 8
) (
    // clock and reset
    input                             clk_i,
    input                             rst_n_i,

    // streaming input
    input  signed [VECTOR_BW - 1 : 0] data_i,
    input                             valid_i,
    input                             last_i,
    output                            ready_o,

    // streaming output
    output signed [BW - 1 : 0]        data_o,
    output                            valid_o,
    output                            last_o,
    input                             ready_i,

    // memory configuration
    input                             rd_en_i,
    input                             wr_en_i,
    input         [BANK_BW - 1 : 0]   rd_wr_bank_i,
    input         [ADDR_BW - 1 : 0]   rd_wr_addr_i,
    input  signed [VECTOR_BW - 1 : 0] wr_data_i,
    output signed [VECTOR_BW - 1 : 0] rd_data_o
);

    genvar i;

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam FILTER_LEN = 3;
    localparam MAX_CYCLES = NUM_FILTERS * FRAME_LEN;

    // bitwidth definitions
    localparam BW                = 8;
    localparam MUL_BW            = 16;
    localparam ADD_BW            = 18;
    localparam BIAS_BW           = 32;
    localparam VECTOR_BW         = VECTOR_LEN * BW;
    localparam MUL_VECTOR_BW     = VECTOR_LEN * MUL_BW;
    localparam ADD_VECTOR_BW     = VECTOR_LEN * ADD_BW;
    localparam ADDR_BW           = $clog2(NUM_FILTERS);
    localparam BANK_BW           = $clog2(FILTER_LEN + 2);
    localparam FRAME_COUNTER_BW  = $clog2(FRAME_LEN);
    localparam FILTER_COUNTER_BW = $clog2(NUM_FILTERS);
    localparam SHIFT_BW          = $clog2(BIAS_BW);

    // =========================================================================
    // Recycler
    // =========================================================================
    wire [VECTOR_BW - 1 : 0] recycler_data0;
    wire [VECTOR_BW - 1 : 0] recycler_data1;
    wire [VECTOR_BW - 1 : 0] recycler_data2;
    wire                     recycler_valid;
    wire                     recycler_last;
    wire                     recycler_ready;

    recycler #(
        .BW(BW),
        .FRAME_LEN(FRAME_LEN),
        .VECTOR_LEN(VECTOR_LEN),
        .NUM_FILTERS(NUM_FILTERS)
    ) recycler_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data_i(data_i),
        .valid_i(valid_i),
        .last_i(last_i),
        .ready_o(recycler_ready),

        .data0_o(recycler_data0),
        .data1_o(recycler_data1),
        .data2_o(recycler_data2),
        .valid_o(recycler_valid),
        .last_o(recycler_last),
        .ready_i(vec_mul_ready0[0])
    );

    reg [VECTOR_BW - 1 : 0] recycler_data_q [FILTER_LEN - 1 : 0];
    reg                     recycler_valid_q;
    reg                     recycler_last_q;

    always @(posedge clk_i) begin
        recycler_data_q[0] <= recycler_data0;
        recycler_data_q[1] <= recycler_data1;
        recycler_data_q[2] <= recycler_data2;
        recycler_valid_q   <= recycler_valid;
        recycler_last_q    <= recycler_last;
    end

    // =========================================================================
    // Parameter Memory
    // =========================================================================
    wire [VECTOR_BW - 1 : 0] conv_mem_weight [FILTER_LEN - 1 : 0];
    wire [BIAS_BW - 1 : 0]   conv_mem_bias;
    wire [SHIFT_BW - 1 : 0]  conv_mem_shift;
    wire                     conv_mem_valid;
    wire                     conv_mem_last;

    conv_mem #(
        .BW(BW),
        .BIAS_BW(BIAS_BW),
        .SHIFT_BW(SHIFT_BW),
        .FRAME_LEN(FRAME_LEN),
        .VECTOR_LEN(VECTOR_LEN),
        .NUM_FILTERS(NUM_FILTERS)
    ) conv_mem_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .cycle_en_i(recycler_valid),

        .rd_en_i(rd_en_i),
        .wr_en_i(wr_en_i),
        .rd_wr_bank_i(rd_wr_bank_i),
        .rd_wr_addr_i(rd_wr_addr_i),
        .wr_data_i(wr_data_i),
        .rd_data_o(rd_data_o),

        .data0_o(conv_mem_weight[0]),
        .data1_o(conv_mem_weight[1]),
        .data2_o(conv_mem_weight[2]),
        .bias_o(conv_mem_bias),
        .shift_o(conv_mem_shift),
        .valid_o(conv_mem_valid),
        .last_o(conv_mem_last),
        .ready_i(vec_mul_ready1[0])
    );

    // Delay the bias term to align with the output of the multipliers,
    // vector addition, and reduction addition
    reg [BIAS_BW - 1 : 0] conv_mem_bias_q,
                          conv_mem_bias_q2,
                          conv_mem_bias_q3;

    reg                   conv_mem_valid_q,
                          conv_mem_valid_q2,
                          conv_mem_valid_q3;

    reg                   conv_mem_last_q,
                          conv_mem_last_q2,
                          conv_mem_last_q3;
    always @(posedge clk_i) begin
        conv_mem_bias_q  <= conv_mem_bias;
        conv_mem_bias_q2 <= conv_mem_bias_q;
        conv_mem_bias_q3 <= conv_mem_bias_q2;

        conv_mem_valid_q  <= conv_mem_valid;
        conv_mem_valid_q2 <= conv_mem_valid_q;
        conv_mem_valid_q3 <= conv_mem_valid_q2;

        conv_mem_last_q  <= conv_mem_last;
        conv_mem_last_q2 <= conv_mem_last_q;
        conv_mem_last_q3 <= conv_mem_last_q2;
    end

    // =========================================================================
    // Vector Multiplication
    // =========================================================================
    wire [MUL_VECTOR_BW - 1 : 0] vec_mul_data   [FILTER_LEN - 1 : 0];
    wire                         vec_mul_valid  [FILTER_LEN - 1 : 0];
    wire                         vec_mul_last   [FILTER_LEN - 1 : 0];
    wire                         vec_mul_ready0 [FILTER_LEN - 1 : 0];
    wire                         vec_mul_ready1 [FILTER_LEN - 1 : 0];

    for (i = 0; i < FILTER_LEN; i = i + 1) begin: vector_multiply
        vec_mul #(
            .I_BW(BW),
            .O_BW(MUL_BW),
            .VECTOR_LEN(VECTOR_LEN)
        ) vec_mul_inst (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            .data0_i(recycler_data_q[i]),
            .valid0_i(recycler_valid_q),
            .last0_i(recycler_last_q),
            .ready0_o(vec_mul_ready0[i]),

            .data1_i(conv_mem_weight[i]),
            .valid1_i(conv_mem_valid),
            .last1_i(conv_mem_last),
            .ready1_o(vec_mul_ready1[i]),

            .data_o(vec_mul_data[i]),
            .valid_o(vec_mul_valid[i]),
            .last_o(vec_mul_last[i]),
            .ready_i(vec_add_ready[i])
        );
    end

    // =========================================================================
    // Vector Addition
    // =========================================================================
    wire [ADD_VECTOR_BW - 1 : 0] vec_add_data;
    wire                         vec_add_valid;
    wire                         vec_add_last;
    wire                         vec_add_ready [FILTER_LEN - 1 : 0];

    vec_add #(
        .I_BW(MUL_BW),
        .O_BW(ADD_BW),
        .VECTOR_LEN(VECTOR_LEN)
    ) vec_add_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data0_i(vec_mul_data[0]),
        .valid0_i(vec_mul_valid[0]),
        .last0_i(vec_mul_last[0]),
        .ready0_o(vec_add_ready[0]),

        .data1_i(vec_mul_data[1]),
        .valid1_i(vec_mul_valid[1]),
        .last1_i(vec_mul_last[1]),
        .ready1_o(vec_add_ready[0]),

        .data2_i(vec_mul_data[2]),
        .valid2_i(vec_mul_valid[2]),
        .last2_i(vec_mul_last[2]),
        .ready2_o(vec_add_ready[0]),

        .data_o(vec_add_data),
        .valid_o(vec_add_valid),
        .last_o(vec_add_last),
        .ready_i(red_add_ready[0])
    );

    // =========================================================================
    // Reduction Addition
    // =========================================================================
    wire [BIAS_BW - 1 : 0] red_add_data;
    wire                   red_add_valid;
    wire                   red_add_last;
    wire [0:0]             red_add_ready; // [0:0] needed to avoid undecl. error

    red_add #(
        .I_BW(ADD_BW),
        .O_BW(BIAS_BW),
        .VECTOR_LEN(VECTOR_LEN)
    ) red_add_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data_i(vec_add_data),
        .valid_i(vec_add_valid),
        .last_i(vec_add_last),
        .ready_o(red_add_ready),

        .data_o(red_add_data),
        .valid_o(red_add_valid),
        .last_o(red_add_last),
        .ready_i(bias_add_ready[1])
    );

    // =========================================================================
    // Bias Addition
    // =========================================================================
    wire [BIAS_BW - 1 : 0] bias_add_data;
    wire                   bias_add_valid;
    wire                   bias_add_last;
    wire                   bias_add_ready [FILTER_LEN - 1 : 0];

    vec_add #(
        .I_BW(BIAS_BW),
        .O_BW(BIAS_BW),
        .VECTOR_LEN(1)
    ) bias_add_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // bias term
        .data0_i(conv_mem_bias_q3),
        .valid0_i(conv_mem_valid_q3),
        .last0_i(conv_mem_last_q3),
        .ready0_o(bias_add_ready[0]),

        // reduced sum
        .data1_i(red_add_data),
        .valid1_i(red_add_valid),
        .last1_i(red_add_last),
        .ready1_o(bias_add_ready[1]),

        // unused
        .data2_i({BIAS_BW{1'b0}}),
        .valid2_i(1'd1),
        .last2_i(1'd0),
        .ready2_o(bias_add_ready[2]),

        .data_o(bias_add_data),
        .valid_o(bias_add_valid),
        .last_o(bias_add_last),
        .ready_i(relu_ready[0])
    );

    // =========================================================================
    // ReLU Layer
    // =========================================================================
    wire [BIAS_BW - 1 : 0] relu_data;
    wire                   relu_valid;
    wire                   relu_last;
    wire [0:0]             relu_ready;

    relu #(
        .BW(BIAS_BW)
    ) relu_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data_i(bias_add_data),
        .valid_i(bias_add_valid),
        .last_i(bias_add_last),
        .ready_o(relu_ready),

        .data_o(relu_data),
        .valid_o(relu_valid),
        .last_o(relu_last),
        .ready_i(quantizer_ready[0])
    );

    // =========================================================================
    // Quantization Layer
    // =========================================================================
    wire [BW - 1 : 0] quantizer_data;
    wire              quantizer_valid;
    wire              quantizer_last;
    wire [0:0]        quantizer_ready;

    quantizer #(
        .I_BW(BIAS_BW),
        .O_BW(BW),
        .SHIFT_BW(SHIFT_BW)
    ) quantizer_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .shift_i(conv_mem_shift),

        .data_i(relu_data),
        .valid_i(relu_valid),
        .last_i(relu_last),
        .ready_o(quantizer_ready),

        .data_o(quantizer_data),
        .valid_o(quantizer_valid),
        .last_o(quantizer_last),
        .ready_i(ready_i)
    );

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = quantizer_data;
    assign valid_o = quantizer_valid;
    assign ready_o = recycler_ready;
    assign last_o  = quantizer_last;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, conv_top);
      #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Fully Connected Memory
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Constraint: BIAS_BW > BW
// TODO: Implement rd_data_o for reading memories
// =============================================================================

module fc_mem #(
    parameter BW          = 8,
    parameter BIAS_BW     = 16,
    parameter FRAME_LEN   = 208,
    parameter NUM_CLASSES = 2
) (
    // clock and reset
    input                                           clk_i,
    input                                           rst_n_i,

    // control
    input                                           cycle_en_i,

    // memory configuration
    input                                           rd_en_i,
    input                                           wr_en_i,
    input         [BANK_BW - 1 : 0]                 rd_wr_bank_i,
    input         [ADDR_BW - 1 : 0]                 rd_wr_addr_i,
    input  signed [BIAS_BW - 1 : 0]                 wr_data_i,
    output signed [BIAS_BW - 1 : 0]                 rd_data_o,

    // streaming output
    output signed [(BW * NUM_CLASSES) - 1 : 0]      data_w_o,
    output signed [(BIAS_BW * NUM_CLASSES) - 1 : 0] data_b_o,
    output                                          valid_o,
    output                                          last_o,
    input                                           ready_i
);

    genvar i;

    // ========================================================================
    // Local Parameters
    // ========================================================================
    // Bitwidth Definitions
    localparam ADDR_BW   = $clog2(FRAME_LEN);
    // Number of weight banks + bias bank per class
    localparam BANK_BW          = $clog2(NUM_CLASSES * 2);
    localparam FRAME_COUNTER_BW = $clog2(FRAME_LEN);

    // ========================================================================
    // Frame Counter
    // ========================================================================
    reg [FRAME_COUNTER_BW - 1 : 0] frame_counter;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            frame_counter <= 0;
        end else begin
            if (cycle_en_i) begin
                frame_counter <= (frame_counter < FRAME_LEN - 1) ?
                                  frame_counter + 'd1 : 'd0;
            end else begin
                frame_counter <= frame_counter;
            end
        end
    end

    // ========================================================================
    // Weight Memories
    // ========================================================================
    wire                    weight_wr_en    [NUM_CLASSES - 1 : 0];
    wire                    weight_en;
    wire [BW - 1 : 0]       weight_data_in;
    wire [ADDR_BW - 1 : 0]  weight_addr;
    wire [BW - 1 : 0]       weight_data_out [NUM_CLASSES - 1 : 0];

    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: weight_banks_wr_en
        assign weight_wr_en[i] = (wr_en_i) & (rd_wr_bank_i == i);
    end
    assign weight_en      = (wr_en_i | rd_en_i | cycle_en_i);
    assign weight_data_in = (wr_en_i) ? wr_data_i[BW - 1 : 0] : 'd0;
    assign weight_addr    = (wr_en_i | rd_en_i) ? rd_wr_addr_i : frame_counter;

    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: weight_banks
        dffram #(
            .WIDTH(BW),
            .DEPTH(FRAME_LEN)
        ) weight_ram_inst (
            .clk_i(clk_i),

            .wr_en_i(weight_wr_en[i]),
            .en_i(weight_en),

            .addr_i(weight_addr),
            .data_i(weight_data_in),
            .data_o(weight_data_out[i])
        );
    end

    // ========================================================================
    // Bias Memories
    // ========================================================================
    wire                   bias_wr_en [NUM_CLASSES - 1 : 0];
    wire                   bias_en;
    wire [BIAS_BW - 1 : 0] bias_data_in;
    // required to be 2 bits for dffram
    wire [1:0]             bias_addr;
    wire [BIAS_BW - 1 : 0] bias_data_out [NUM_CLASSES - 1 : 0];

    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: bias_banks_wr_en
        assign bias_wr_en[i] = (wr_en_i) & (rd_wr_bank_i == i + NUM_CLASSES);
    end
    assign bias_en      = (wr_en_i | rd_en_i | cycle_en_i);
    assign bias_data_in = (wr_en_i) ? wr_data_i : 'd0;
    assign bias_addr    = 'b0;

    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: bias_banks
        dffram #(
            .WIDTH(BIAS_BW),
            .DEPTH(1)
        ) bias_ram_inst (
            .clk_i(clk_i),

            .wr_en_i(bias_wr_en[i]),
            .en_i(bias_en),

            .addr_i(bias_addr),
            .data_i(bias_data_in),
            .data_o(bias_data_out[i])
        );
    end

    // ========================================================================
    // Read Data Assignment
    // ========================================================================
    reg [BANK_BW - 1 : 0] rd_wr_bank_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            rd_wr_bank_q <= 'b0;
        end else begin
            rd_wr_bank_q <= rd_wr_bank_i;
        end
    end

    // build array of all the output data, properly padded, to mux to rd_data_o
    wire [BIAS_BW - 1 : 0] out_data_arr [(NUM_CLASSES * 2) - 1 : 0];

    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: weight_banks_out_data_arr
        assign out_data_arr[i] = {{{BIAS_BW - BW}{1'b0}}, weight_data_out[i]};
    end
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: bias_banks_out_data_arr
        assign out_data_arr[i + NUM_CLASSES] = bias_data_out[i];
    end

    assign rd_data_o = out_data_arr[rd_wr_bank_q];

    // ========================================================================
    // Output Assignment
    // ========================================================================
    reg cycle_en_i_q;
    always @(posedge clk_i) begin
        cycle_en_i_q <= cycle_en_i;
    end

    reg frame_last;
    always @(posedge clk_i) begin
        frame_last <= (frame_counter == FRAME_LEN - 1);
    end

    // pack multiplication results
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: pack_output
        assign data_w_o[(i + 1) * BW - 1 : i * BW] = weight_data_out[i];
        assign data_b_o[(i + 1) * BIAS_BW - 1 : i * BIAS_BW] = bias_data_out[i];
    end
    assign valid_o = cycle_en_i_q;
    assign last_o  = valid_o & frame_last;

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, fc_mem);
        #1;
    end
    `endif

endmodule
// ============================================================================
// Module:       Fully Connected Layer
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Assumes BIAS_BW > BW
// TODO: Implement rd_data_o for reading memories
// TODO: Calculate O_BW from NUM_CLASSES?
// ============================================================================

module fc_top #(
    parameter I_BW        = 8,
    parameter BIAS_BW     = 16,
    parameter O_BW        = 24,
    parameter FRAME_LEN   = 208,
    parameter NUM_CLASSES = 3
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
    localparam ADDR_BW   = $clog2(FRAME_LEN);
    localparam VECTOR_I_BW = I_BW * NUM_CLASSES;
    localparam VECTOR_BIAS_BW = BIAS_BW * NUM_CLASSES;
    localparam VECTOR_O_BW = O_BW * NUM_CLASSES;

    // Number of weight banks + bias bank per class
    localparam BANK_BW          = $clog2(NUM_CLASSES * 2);
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

    wire mac_ready0;

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
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, fc_top);
        #1;
    end
    `endif

endmodule
// ============================================================================
// Module:       Multiply Accumulate
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Assumes that biases have 2x bitwidth of weights, and outputs are 3x bitwidth
// Also assumes that packet lengths are > 3 (which is the propogation length of
// the bias out to the output, since it is pipelined).
//
// TODO: Check which signals have to be signed
// ============================================================================

module mac #(
    parameter I_BW        = 8,          // input bitwidth
    parameter O_BW        = I_BW * 3,   // output bitwidth
    parameter BIAS_BW     = I_BW * 2,   // bias bitwidth
    parameter NUM_CLASSES = 3           // number of output classes
) (
    // clock and reset
    input                                           clk_i,
    input                                           rst_n_i,

    // streaming input
    input  signed [I_BW - 1: 0]                     data0_i,
    input                                           valid0_i,
    input                                           last0_i,
    output                                          ready0_o,

    // streaming input
    input  signed [(NUM_CLASSES * I_BW) - 1 : 0]    data1_w_i,
    input  signed [(NUM_CLASSES * BIAS_BW) - 1 : 0] data1_b_i,
    input                                           valid1_i,
    input                                           last1_i,
    output                                          ready1_o,

    // streaming output
    output signed [(NUM_CLASSES * O_BW) - 1 : 0]    data_o,
    output                                          valid_o,
    output                                          last_o,
    input                                           ready_i
);

    localparam VALID_TIMEOUT_CYCLES         = 8;  // num cycles to reset after
    localparam VALID_TIMEOUT_BW             = $clog2(VALID_TIMEOUT_CYCLES + 1);

    genvar i;

    // =========================================================================
    // Delay Lines
    // =========================================================================
    // add 2 cycle bias delay line to account for multiplier and accumulator
    reg signed [(NUM_CLASSES * BIAS_BW) - 1 : 0] data1_b_q, data1_b_q2;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            data1_b_q  <= 0;
            data1_b_q2 <= 0;
        end else begin
            data1_b_q  <= data1_b_i;
            data1_b_q2 <= data1_b_q;
        end
    end

    // =========================================================================
    // Input Unpacking
    // =========================================================================
    // unpacked arrays
    wire signed [I_BW - 1 : 0]    weight_arr [NUM_CLASSES - 1 : 0];
    wire signed [BIAS_BW - 1 : 0] bias_arr   [NUM_CLASSES - 1 : 0];

    // unpack data input
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: unpack_inputs
        assign weight_arr[i] = data1_w_i[(i + 1) * I_BW - 1 : i * I_BW];
        assign bias_arr[i]   = data1_b_q2[(i + 1) * BIAS_BW - 1 : i * BIAS_BW];
    end

    // =========================================================================
    // Vector Multiplication
    // =========================================================================
    // registered multiplication of input and bias
    reg signed [(I_BW * 2) - 1: 0] mult_arr [NUM_CLASSES - 1 : 0];
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: fc_multiply
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                mult_arr[i] <= 'd0;
            end else begin
                mult_arr[i] <= data0_i * weight_arr[i];
            end
        end
    end

    // =========================================================================
    // Accumulation Buffer
    // =========================================================================
    // clear the accumulation buffer when valid has a rising edge
    // wire valid_i_pos_edge;
    // assign valid_i_pos_edge = valid0_i & (!valid_q);

    // clear the accumulation buffer if no valid data has been passed in for
    // VALID_TIMEOUT_CYCLES cycles
    wire valid_timeout;
    reg [VALID_TIMEOUT_BW - 1: 0] valid_timeout_counter;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_timeout_counter <= 'd0;
        end else begin
            if (valid0_i) begin  // reset counter on valid data
                valid_timeout_counter <= 'd0;
            end else if (valid_timeout_counter == VALID_TIMEOUT_CYCLES) begin
                valid_timeout_counter <= valid_timeout_counter;
            end else begin
                valid_timeout_counter <= valid_timeout_counter + 'd1;
            end
        end
    end
    assign valid_timeout = (valid_timeout_counter == VALID_TIMEOUT_CYCLES);

    reg signed [O_BW - 1: 0] acc_arr [NUM_CLASSES - 1 : 0];
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: fc_accumulate
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                acc_arr[i] <= 'd0;
            end else begin
                if (last_q2 | valid_timeout) begin
                    acc_arr[i] <= 'd0;
                end else if (valid_q) begin
                    acc_arr[i] <= mult_arr[i] + acc_arr[i];
                end else begin
                    acc_arr[i] <= acc_arr[i];
                end
            end
        end
    end

    // =========================================================================
    // Bias Addition
    // =========================================================================
    reg signed [O_BW - 1: 0] add_arr [NUM_CLASSES - 1 : 0];
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: fc_bias
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                add_arr[i] <= 'd0;
            end else begin
                add_arr[i] <= acc_arr[i] + bias_arr[i];
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: pack_output
        assign data_o[(i + 1) * O_BW - 1 : i * O_BW] = add_arr[i];
    end

    // register all outputs
    reg valid_q, valid_q2, valid_q3;
    reg last_q, last_q2, last_q3;
    reg ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q  <= 'b0;
            valid_q2 <= 'b0;
            valid_q3 <= 'b0;
            last_q   <= 'b0;
            last_q2  <= 'b0;
            last_q3  <= 'b0;
            ready_q  <= 'b0;
        end else begin
            valid_q  <= valid0_i && valid1_i;
            valid_q2 <= valid_q;
            valid_q3 <= valid_q2;
            // last_q   <= last0_i | last1_i;
            last_q   <= last1_i;
            last_q2  <= last_q;
            last_q3  <= last_q2;
            ready_q  <= ready_i;
        end
    end


    assign valid_o  = valid_q3 && last_q3;
    assign last_o   = last_q3;
    assign ready0_o = ready_q;
    assign ready1_o = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, mac);
        // reg [7:0] idx; // need integer for loop
        $dumpvars(0, mult_arr[0]);
        $dumpvars(0, acc_arr[0]);
        $dumpvars(0, add_arr[0]);
        $dumpvars(0, mult_arr[1]);
        $dumpvars(0, acc_arr[1]);
        $dumpvars(0, add_arr[1]);
        #1;
    end
    `endif

endmodule
// ============================================================================
// Max Pool
// Design: Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// ============================================================================

module max_pool #(
    parameter BW = 8
) (
    // clock and reset
    input                      clk_i,
    input                      rst_n_i,

    // streaming input
    input  signed [BW - 1 : 0] data_i,
    input                      valid_i,
    input                      last_i,
    output                     ready_o,

    // streaming output
    output signed [BW - 1 : 0] data_o,
    output                     valid_o,
    output                     last_o,
    input                      ready_i
);

    localparam STATE_IDLE   = 2'd0,
               STATE_LOAD_1 = 2'd1,
               STATE_LOAD_2 = 2'd2,
               STATE_VALID  = 2'd3;
    reg [1:0] state;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            state <= STATE_IDLE;
        end else begin
            case(state)
                STATE_IDLE: begin
                    state <= (valid_i) ? STATE_LOAD_1 : STATE_IDLE;
                end
                STATE_LOAD_1: begin
                    state <= (valid_i) ? STATE_LOAD_2 : STATE_IDLE;
                end
                STATE_LOAD_2: begin
                    state <= STATE_VALID;
                end
                STATE_VALID: begin
                    state <= (valid_q) ?
                             ((last_q) ? STATE_VALID : STATE_LOAD_2) :
                             STATE_IDLE;
                end
                default: begin
                end
            endcase
        end
    end


    // register all outputs
    reg signed [BW - 1 : 0] data_q, data_q2, max;

    reg valid_q, valid_q2, valid_q3, last_q, last_q2, last_q3, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q  <= 'b0;
            valid_q2 <= 'b0;
            valid_q3 <= 'b0;
            last_q   <= 'b0;
            last_q2  <= 'b0;
            last_q3  <= 'b0;
            ready_q  <= 'b0;
            data_q   <= 'b0;
            data_q2  <= 'b0;
            max      <= 'b0;
        end else begin
            valid_q  <= valid_i;
            valid_q2 <= valid_q;
            valid_q3 <= valid_q2;
            last_q   <= last_i;
            last_q2  <= last_q;
            last_q3  <= last_q2;
            ready_q  <= ready_i;
            data_q   <= data_i;
            data_q2  <= data_q;
            max      <= (state == STATE_VALID) ? 
                          data_q  // if 2 new data are not ready yet just
                                  // output the first one
                          : ((data_q > data_q2) ? data_q : data_q2);
        end
    end

    // positive edge detector to emit initial 0
    wire valid_i_pos_edge  = valid_i  & (!valid_q);

    // negative edge detectors to extend valid_o, emit last 0
    wire valid_q_neg_edge  = valid_q2 & (!valid_q);
    wire valid_q2_neg_edge = valid_q3 & (!valid_q2);

    assign data_o  = max;
    // assign valid_o = valid_q | valid_q_neg_edge | valid_q2_neg_edge;
    assign valid_o = (state == STATE_VALID);
    assign last_o  = last_q2;
    assign ready_o = ready_q;

    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, max_pool);
        #1;
    end
    `endif

endmodule
// ============================================================================
// Quantizer
// Design: Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// TODO: Can we synthesize a variable arithmetic right shift?
// TODO: Does this need to be signed? Guess is no since it is after ReLU
// ============================================================================

module quantizer #(
    parameter I_BW     = 32,
    parameter O_BW     = 8,
    parameter SHIFT_BW = $clog2(I_BW)
) (
    input                    clk_i,
    input                    rst_n_i,

    input [SHIFT_BW - 1 : 0] shift_i,

    input [I_BW - 1 : 0]     data_i,
    input                    valid_i,
    input                    last_i,
    output                   ready_o,

    output [O_BW - 1 : 0]    data_o,
    output                   valid_o,
    output                   last_o,
    input                    ready_i
);

    localparam [O_BW - 1 : 0] saturate_point = {1'b0, {O_BW - 1{1'b1}}};

    reg [I_BW - 1 : 0] shifted;

    always @(posedge clk_i) begin
        shifted <= (data_i >> shift_i);
    end

    wire [O_BW - 1 : 0] truncated;
    assign truncated = shifted[O_BW - 1 : 0];

    // register all outputs
    reg valid_q, last_q, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q <= 'b0;
            last_q  <= 'b0;
            ready_q <= 'b0;
        end else begin
            valid_q <= valid_i;
            last_q  <= last_i;
            ready_q <= ready_i;
        end
    end

    assign data_o  = (shifted > saturate_point) ? saturate_point :
                                                  shifted[O_BW - 1 : 0];
    assign valid_o = valid_q;
    assign last_o  = last_q;
    assign ready_o = ready_q;

    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, quantizer);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Recycler
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Constraint: FRAME_LEN > FILTER_LEN
// Constraint: FILTER_LEN == 3
// In order to change filter size, you'll have to parameterize the vec_add
// unit.
// TODO: Fix initial deque errors
// TODO: Handle deassertions of valid midstream
// TODO: Handle Full and Empty
// =============================================================================

module recycler #(
    parameter BW          = 8,
    parameter FRAME_LEN   = 50,
    parameter VECTOR_LEN  = 13,
    parameter NUM_FILTERS = 8
) (
    // clock and reset
    input                             clk_i,
    input                             rst_n_i,

    // streaming input
    input  signed [VECTOR_BW - 1 : 0] data_i,
    input                             valid_i,
    input                             last_i,
    output                            ready_o,

    // streaming output
    output signed [VECTOR_BW - 1 : 0] data0_o,
    output signed [VECTOR_BW - 1 : 0] data1_o,
    output signed [VECTOR_BW - 1 : 0] data2_o,
    output                            valid_o,
    output                            last_o,
    input                             ready_i
);

    genvar i;

    // =========================================================================
    // Local Parameters
    // =========================================================================
    // This unit is hard coded for width 3 filters
    localparam FILTER_LEN = 3;
    // Need to account for cycles where the ends of the featuremap wrap
    // through the shift registers, hence the extra "+ NUM_FILTERS - 1"
    localparam CYCLE_PERIOD = (FRAME_LEN + FILTER_LEN - 1);
    localparam MAX_CYCLES = NUM_FILTERS * CYCLE_PERIOD;
    // Number of cycles where we want to requeue data into the FIFO. For last
    // filter want to drop all the data and leave the FIFO empty.
    localparam MAX_CYCLES_REQUEUE = (NUM_FILTERS - 1) * CYCLE_PERIOD;

    // bitwidth definitions
    localparam VECTOR_BW  = VECTOR_LEN * BW;
    localparam COUNTER_BW = $clog2(MAX_CYCLES);
    localparam FRAME_COUNTER_BW = $clog2(FRAME_LEN + FILTER_LEN - 1);

    // ========================================================================
    // Recycler Controller
    // ========================================================================
    // Define States
    localparam STATE_IDLE    = 2'd0,
               STATE_PRELOAD = 2'd1,
               STATE_LOAD    = 2'd2,
               STATE_CYCLE   = 2'd3;

    reg [1:0] state;
    reg [COUNTER_BW - 1 : 0] counter;
    // frame_counter is used to determine when the output is invalid due to
    // having the ends of the featuremap both in the shift registers
    reg [FRAME_COUNTER_BW - 1 : 0] frame_counter;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            counter <= 'd0;
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    // FIFO State only transitions to PRELOAD on valid input
                    counter <= 'd0;
                    frame_counter <= 'd0;
                    state   <= (valid_i) ? STATE_PRELOAD : STATE_IDLE;
                end
                STATE_PRELOAD: begin
                    // In PRELOAD, we're shifting the first FILTER_LEN - 1
                    // elements into our shift register, then transition
                    // to regular LOAD where the shift register is not active
                    counter <= counter + 'd1;
                    frame_counter <= 'd0;
                    state   <= (counter == FILTER_LEN) ? STATE_LOAD :
                                                         STATE_PRELOAD;
                end
                STATE_LOAD: begin
                    // In LOAD we're just shifting enough elements until
                    // last_i is asserted
                    counter <= 'd0;
                    frame_counter <= 'd0;
                    state   <= (last_i) ? STATE_CYCLE: STATE_LOAD;
                end
                STATE_CYCLE: begin
                    // In CYCLE, we begin cycling MAX_CYCLE times.
                    // If valid_i is high, we transition straight into
                    // PRELOAD again since a new frame is immediately
                    // available.
                    // If valid_i is deasserted, we transition into IDLE
                    // and wait on the next input blocks to come in
                    counter <= counter + 'd1;
                    frame_counter <= (frame_counter < FRAME_LEN + FILTER_LEN - 1)
                                        ? frame_counter + 'd1
                                        : 'd1;
                    state   <= (counter < MAX_CYCLES - 1) ? STATE_CYCLE :
                               ((valid_i) ? STATE_PRELOAD : STATE_IDLE);
                end
                default: begin
                    counter <= 'd0;
                    frame_counter <= 'd0;
                    state   <= STATE_IDLE;
                end
            endcase
        end
    end

    // ========================================================================
    // Recycling FIFO
    // ========================================================================
    // Needed to ensure we do not drop data_i the first cycle "valid"
    // is asserted
    reg [VECTOR_BW - 1: 0] data_i_q;
    always @(posedge clk_i) begin
        data_i_q <= data_i;
    end

    // Delayed by 1 cycle since data_i_q is delayed by one cycle
    reg fifo_recycle;
    always @(posedge clk_i) begin
        fifo_recycle <= (state == STATE_CYCLE);
    end

    // Assign din to input if loading, otherwise feedback output to recycle
    wire [VECTOR_BW - 1 : 0] fifo_din;
    assign fifo_din = fifo_recycle ? fifo_out_sr[FILTER_LEN - 1] : data_i_q;

    // Always enqueue if FIFO is not idle
    wire fifo_enq;
    assign fifo_enq = (!(state == STATE_IDLE) & (counter <= MAX_CYCLES_REQUEUE));

    // Dequeue the FIFO when we begin recycling
    // or dequeue the FIFO exactly FILTER_LEN - 1 times when Preloading
    wire fifo_deq;
    assign fifo_deq = ((state == STATE_CYCLE) |
                       ((state == STATE_PRELOAD) &
                        (counter < FILTER_LEN - 1)));

    wire [VECTOR_BW - 1 : 0] fifo_dout;

    fifo #(
        .DATA_WIDTH(VECTOR_BW),
        .FIFO_DEPTH(FRAME_LEN)
    ) fifo_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .enq_i(fifo_enq),
        .deq_i(fifo_deq),

        .din_i(fifo_din),
        .dout_o(fifo_dout),

        .full_o_n(),
        .empty_o_n()
    );

    // FIFO Output Shift Register Enable
    wire sr_en;
    assign sr_en = (fifo_recycle | (state == STATE_PRELOAD));

    // FIFO Output Shift Register
    reg [VECTOR_BW - 1 : 0] fifo_out_sr [FILTER_LEN - 1 : 0];
    always @(posedge clk_i) begin
        if (sr_en) begin
            fifo_out_sr[0] <= fifo_dout;
        end
    end
    for (i = 1; i < FILTER_LEN; i = i + 1) begin: create_fifo_out_sr
        always @(posedge clk_i) begin
            if (sr_en) begin
                fifo_out_sr[i] <= fifo_out_sr[i-1];
            end
        end
    end

    // FIFO Output Valid Shift Register
    reg fifo_out_valid;
    always @(posedge clk_i) begin
        fifo_out_valid <= (state == STATE_CYCLE);
    end

    // ========================================================================
    // Output Assignment
    // ========================================================================
    assign data0_o = fifo_out_sr[0];
    assign data1_o = fifo_out_sr[1];
    assign data2_o = fifo_out_sr[2];
    // Output is not valid when both ends of the featuremap are in the shift
    // register
    assign valid_o = fifo_out_valid & (frame_counter <= FRAME_LEN);
    assign ready_o = ready_i;
    assign last_o  = last_i;

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, recycler);
        #1;
    end
    `endif

endmodule
// ============================================================================
// Module:       Reduction Addition
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// TODO: Can we make elements in sum minimum length?
// ============================================================================

module red_add #(
    parameter I_BW = 18,
    parameter O_BW = 32,
    parameter VECTOR_LEN = 2
) (
    // clock and reset
    input                                       clk_i,
    input                                       rst_n_i,

    // streaming input
    input  signed [(VECTOR_LEN * I_BW) - 1 : 0] data_i,
    input                                       valid_i,
    input                                       last_i,
    output                                      ready_o,

    // streaming output
    output signed [O_BW - 1 : 0]                data_o,
    output                                      valid_o,
    output                                      last_o,
    input                                       ready_i
);

    genvar i;

    // =========================================================================
    // Input Unpacking
    // =========================================================================
    // unpacked arrays
    wire signed [I_BW - 1 : 0] data_arr [VECTOR_LEN - 1 : 0];
    wire signed [O_BW - 1 : 0] sum      [VECTOR_LEN - 1 : 0];
    reg  signed [O_BW - 1 : 0] final_sum_q;

    // unpack data input
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: unpack_inputs
        assign data_arr[i] = data_i[(i + 1) * I_BW - 1 : i * I_BW];
    end

    // =========================================================================
    // Reduction Addition
    // =========================================================================
    for (i = 1; i < VECTOR_LEN; i = i + 1) begin: reduction_sum
         if (i == 1) begin
             assign sum[i] = data_arr[i] + data_arr[i-1];
         end else begin
             assign sum[i] = sum[i-1] + data_arr[i];
         end
    end

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            final_sum_q <= 'd0;
        end else begin
            final_sum_q <= sum[VECTOR_LEN - 1];
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    // register all outputs
    reg valid_q, last_q, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q <= 'b0;
            last_q  <= 'b0;
            ready_q <= 'b0;
        end else begin
            valid_q <= valid_i;
            last_q  <= last_i;
            ready_q <= ready_i;
        end
    end

    assign data_o   = final_sum_q;
    assign valid_o  = valid_q;
    assign last_o   = last_q;
    assign ready_o = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, red_add);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       ReLU (Rectified Linear Unit)
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// =============================================================================

module relu #(
    parameter BW = 32
) (
    input                      clk_i,
    input                      rst_n_i,

    input  signed [BW - 1 : 0] data_i,
    input                      valid_i,
    input                      last_i,
    output                     ready_o,

    output signed [BW - 1 : 0] data_o,
    output                     valid_o,
    output                     last_o,
    input                      ready_i
);

    // =========================================================================
    // Rectification
    // =========================================================================
    reg [BW - 1 : 0] rectified;
    always @(posedge clk_i) begin
        rectified <= (data_i > 0) ? data_i : 0;
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    // register all outputs
    reg valid_q, last_q, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q <= 'b0;
            last_q  <= 'b0;
            ready_q <= 'b0;
        end else begin
            valid_q <= valid_i;
            last_q  <= last_i;
            ready_q <= ready_i;
        end
    end

    assign data_o  = rectified;
    assign valid_o = valid_q;
    assign last_o  = last_q;
    assign ready_o = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, relu);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Vector Adder
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// =============================================================================

module vec_add #(
    parameter I_BW = 16,
    parameter O_BW = 18,
    parameter VECTOR_LEN = 13
) (
    // clock and reset
    input                                       clk_i,
    input                                       rst_n_i,

    // streaming input
    input  signed [(VECTOR_LEN * I_BW) - 1 : 0] data0_i,
    input                                       valid0_i,
    input                                       last0_i,
    output                                      ready0_o,

    // streaming input
    input  signed [(VECTOR_LEN * I_BW) - 1 : 0] data1_i,
    input                                       valid1_i,
    input                                       last1_i,
    output                                      ready1_o,

    // streaming input
    input  signed [(VECTOR_LEN * I_BW) - 1 : 0] data2_i,
    input                                       valid2_i,
    input                                       last2_i,
    output                                      ready2_o,

    // streaming output
    output signed [(VECTOR_LEN * O_BW) - 1 : 0] data_o,
    output                                      valid_o,
    output                                      last_o,
    input                                       ready_i
);

    genvar i;

    // =========================================================================
    // Input Unpacking
    // =========================================================================
    // unpacked arrays
    wire signed [I_BW - 1 : 0] data0_arr [VECTOR_LEN - 1 : 0];
    wire signed [I_BW - 1 : 0] data1_arr [VECTOR_LEN - 1 : 0];
    wire signed [I_BW - 1 : 0] data2_arr [VECTOR_LEN - 1 : 0];
    reg  signed [O_BW - 1 : 0] out_arr   [VECTOR_LEN - 1 : 0];

    // unpack data input
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: unpack_inputs
        assign data0_arr[i] = data0_i[(i + 1) * I_BW - 1 : i * I_BW];
        assign data1_arr[i] = data1_i[(i + 1) * I_BW - 1 : i * I_BW];
        assign data2_arr[i] = data2_i[(i + 1) * I_BW - 1 : i * I_BW];
    end

    // =========================================================================
    // Vector Addition
    // =========================================================================
    // registered addition of data elements
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: vector_addition
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                out_arr[i] <= 'd0;
            end else begin
                out_arr[i] <= data0_arr[i] + data1_arr[i] + data2_arr[i];
            end
        end
    end

    // =========================================================================
    // Output Packing
    // =========================================================================
    // pack addition results
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: pack_output
        assign data_o[(i + 1) * O_BW - 1 : i * O_BW] = out_arr[i];
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    // register all outputs
    reg valid_q, last_q, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q <= 'b0;
            last_q  <= 'b0;
            ready_q <= 'b0;
        end else begin
            valid_q <= valid0_i & valid1_i & valid2_i;
            last_q  <= last0_i | last1_i | last2_i;
            ready_q <= ready_i;
        end
    end

    assign valid_o  = valid_q;
    assign last_o   = last_q;
    assign ready0_o = ready_q;
    assign ready1_o = ready_q;
    assign ready2_o = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, vec_add);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Vector Multiplier
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// =============================================================================

module vec_mul #(
    parameter I_BW = 8,
    parameter O_BW = 16,
    parameter VECTOR_LEN = 13
) (
    // clock and reset
    input                                       clk_i,
    input                                       rst_n_i,

    // streaming input
    input  signed [(VECTOR_LEN * I_BW) - 1 : 0] data0_i,
    input                                       valid0_i,
    input                                       last0_i,
    output                                      ready0_o,

    // streaming input
    input  signed [(VECTOR_LEN * I_BW) - 1 : 0] data1_i,
    input                                       valid1_i,
    input                                       last1_i,
    output                                      ready1_o,

    // streaming output
    output signed [(VECTOR_LEN * O_BW) - 1 : 0] data_o,
    output                                      valid_o,
    output                                      last_o,
    input                                       ready_i
);

    genvar i;

    // =========================================================================
    // Input Unpacking
    // =========================================================================
    // unpacked arrays
    wire signed [I_BW - 1 : 0] data0_arr [VECTOR_LEN - 1 : 0];
    wire signed [I_BW - 1 : 0] data1_arr [VECTOR_LEN - 1 : 0];
    reg  signed [O_BW - 1 : 0] out_arr   [VECTOR_LEN - 1 : 0];

    // unpack data input
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: unpack_inputs
        assign data0_arr[i] = data0_i[(i + 1) * I_BW - 1 : i * I_BW];
        assign data1_arr[i] = data1_i[(i + 1) * I_BW - 1 : i * I_BW];
    end

    // =========================================================================
    // Vector Multiplication
    // =========================================================================
    // registered multiplication of data elements
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: vector_multiply
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                out_arr[i] <= 'd0;
            end else begin
                out_arr[i] <= data0_arr[i] * data1_arr[i];
            end
        end
    end

    // =========================================================================
    // Output Packing
    // =========================================================================
    // pack multiplication results
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: pack_output
        assign data_o[(i + 1) * O_BW - 1 : i * O_BW] = out_arr[i];
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    // register all outputs
    reg valid_q, last_q, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q <= 'b0;
            last_q  <= 'b0;
            ready_q <= 'b0;
        end else begin
            valid_q <= valid0_i & valid1_i;
            last_q  <= last0_i | last1_i;
            ready_q <= ready_i;
        end
    end

    assign valid_o  = valid_q;
    assign last_o   = last_q;
    assign ready0_o = ready_q;
    assign ready1_o = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, vec_mul);
        #1;
    end
    `endif

endmodule
// ============================================================================
// Module:       Wake
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// TODO: Make multi-class?
// TODO: Make SUSTAIN_LEN configurable?
// ============================================================================

module wake #(
    parameter NUM_CLASSES = 3
) (
    // clock and reset
    input                       clk_i,
    input                       rst_n_i,

    // streaming input
    input [NUM_CLASSES - 1 : 0] data_i,
    input                       valid_i,
    input                       last_i,
    output                      ready_o,

    // wake output
    output                      wake_o,
    output                      valid_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam SUSTAIN_LEN = 1024;  // TODO: increase sustain len
    localparam COUNTER_BW = $clog2(SUSTAIN_LEN);

    // =========================================================================
    // Control Logic
    // =========================================================================
    localparam STATE_IDLE = 1'd0,
               STATE_WAKE = 1'd1;

    reg [COUNTER_BW - 1 : 0] counter;
    reg state;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            counter <= 'd0;
            state   <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    counter <= 'd0;
                    state <= (data_i[0] & valid_i) ? STATE_WAKE : STATE_IDLE;
                end
                STATE_WAKE: begin
                    counter <= counter + 'd1;
                    state <= (counter == SUSTAIN_LEN - 1) ? STATE_IDLE :
                                                            STATE_WAKE;
                end
                default: begin
                    counter <= 'd0;
                    state   <= STATE_IDLE;
                end
            endcase
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign wake_o = (state == STATE_WAKE);
    assign valid_o = (valid_i | wake_o);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, wake);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Word Recognition Top Module
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// =============================================================================

module wrd (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,

    // streaming input
    input  signed [CONV1_VECTOR_BW - 1 : 0] data_i,
    input                                   valid_i,
    input                                   last_i,
    output                                  ready_o,

    // wake pin
    output                                  wake_o,
    output                                  wake_valid,

    // conv1 memory configuration
    input                                   conv1_rd_en_i,
    input                                   conv1_wr_en_i,
    input         [CONV1_BANK_BW - 1 : 0]   conv1_rd_wr_bank_i,
    input         [CONV1_ADDR_BW - 1 : 0]   conv1_rd_wr_addr_i,
    input  signed [CONV1_VECTOR_BW - 1 : 0] conv1_wr_data_i,
    output signed [CONV1_VECTOR_BW - 1 : 0] conv1_rd_data_o,

    // conv2 memory configuration
    input                                   conv2_rd_en_i,
    input                                   conv2_wr_en_i,
    input         [CONV2_BANK_BW - 1 : 0]   conv2_rd_wr_bank_i,
    input         [CONV2_ADDR_BW - 1 : 0]   conv2_rd_wr_addr_i,
    input  signed [CONV2_VECTOR_BW - 1 : 0] conv2_wr_data_i,
    output signed [CONV2_VECTOR_BW - 1 : 0] conv2_rd_data_o,

    // fc memory configuration
    input                                   fc_rd_en_i,
    input                                   fc_wr_en_i,
    input         [FC_BANK_BW - 1 : 0]      fc_rd_wr_bank_i,
    input         [FC_ADDR_BW - 1 : 0]      fc_rd_wr_addr_i,
    input  signed [FC_BIAS_BW - 1 : 0]      fc_wr_data_i,
    output signed [FC_BIAS_BW - 1 : 0]      fc_rd_data_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    // input parameters
    localparam I_BW         = 8;
    localparam I_FRAME_LEN  = 50;
    localparam I_VECTOR_LEN = 13;

    // zero_pad1 module parameters
    localparam ZERO_PAD1_BW         = I_BW;         // 8
    localparam ZERO_PAD1_VECTOR_LEN = I_VECTOR_LEN; // 13
    // zero_pad1 helper parameters
    localparam ZERO_PAD1_VECTOR_BW = ZERO_PAD1_BW * ZERO_PAD1_VECTOR_LEN; // 104

    // conv1 module parameters
    localparam CONV1_FRAME_LEN   = I_FRAME_LEN;  // 50
    localparam CONV1_VECTOR_LEN  = I_VECTOR_LEN; // 13
    localparam CONV1_NUM_FILTERS = 8;
    // conv1 helper parameters
    localparam CONV1_BW         = ZERO_PAD1_BW; // 8
    localparam CONV1_FILTER_LEN = 3;
    localparam CONV1_VECTOR_BW  = CONV1_BW * CONV1_VECTOR_LEN; // 104
    // conv1 memory configuration parameters
    localparam CONV1_BANK_BW = $clog2(CONV1_FILTER_LEN + 2); // 3
    localparam CONV1_ADDR_BW = $clog2(CONV1_NUM_FILTERS);    // 3

    // max_pool1 module parameters
    localparam MAX_POOL1_BW = CONV1_BW; // 8

    // conv_sipo module parameters
    localparam CONV_SIPO_BW         = MAX_POOL1_BW;                    // 8
    localparam CONV_SIPO_FRAME_LEN  = $rtoi($ceil(I_FRAME_LEN / 2.0)); // 25
    localparam CONV_SIPO_VECTOR_LEN = CONV1_NUM_FILTERS;               // 8
    // conv_sipo helper parameters
    localparam CONV_SIPO_VECTOR_BW = CONV_SIPO_BW * CONV_SIPO_VECTOR_LEN; // 64

    // zero_pad2 module parameters
    localparam ZERO_PAD2_BW         = I_BW;              // 8
    localparam ZERO_PAD2_VECTOR_LEN = CONV1_NUM_FILTERS; // 8
    // zero_pad2 helper parameters
    localparam ZERO_PAD2_VECTOR_BW = ZERO_PAD2_BW * ZERO_PAD2_VECTOR_LEN; // 128

    // conv2 module parameters
    localparam CONV2_FRAME_LEN   = CONV_SIPO_FRAME_LEN; // 25
    localparam CONV2_VECTOR_LEN  = CONV1_NUM_FILTERS;   // 8
    localparam CONV2_NUM_FILTERS = 16;
    // conv2 helper parameters
    localparam CONV2_BW         = CONV_SIPO_BW;                // 8
    localparam CONV2_FILTER_LEN = 3;
    localparam CONV2_VECTOR_BW  = CONV2_BW * CONV2_VECTOR_LEN; // 64
    // conv2 memory configuration parameters
    localparam CONV2_BANK_BW = $clog2(CONV2_FILTER_LEN + 2); // 3
    localparam CONV2_ADDR_BW = $clog2(CONV2_NUM_FILTERS);    // 4

    // max_pool2 module parameters
    localparam MAX_POOL2_BW        = CONV_SIPO_BW; // 8
    localparam MAX_POOL2_FRAME_LEN = $rtoi($ceil(CONV_SIPO_FRAME_LEN / 2.0)); //13

    // fc module parameters
    localparam FC_I_BW        = I_BW; // 8
    localparam FC_BIAS_BW     = 32;
    localparam FC_O_BW        = 32;
    localparam FC_FRAME_LEN   = MAX_POOL2_FRAME_LEN * CONV2_NUM_FILTERS; // 208
    localparam FC_NUM_CLASSES = 2;
    // fc helper parameters
    localparam FC_VECTOR_O_BW = FC_O_BW * FC_NUM_CLASSES; // 64
    // fc memory configuration parameters
    localparam FC_BANK_BW = $clog2(FC_NUM_CLASSES * 2);
    // TODO: Yosys will not resolve FC_FRAME_LEN, need to hard code
    // localparam FC_ADDR_BW = $clog2(FC_FRAME_LEN);
    localparam FC_ADDR_BW = $clog2(208);

    // argmax module parameters
    localparam ARGMAX_I_BW = FC_O_BW; // 24
    // argmax helper parameters
    localparam ARGMAX_O_BW = FC_NUM_CLASSES;

    // wake module parameters
    localparam WAKE_NUM_CLASSES = FC_NUM_CLASSES; // 2

    // =========================================================================
    // zero_pad1
    // =========================================================================
    wire [ZERO_PAD1_VECTOR_BW - 1 : 0] zero_pad1_data;
    wire                               zero_pad1_valid;
    wire                               zero_pad1_last;

    zero_pad #(
        .BW(ZERO_PAD1_BW),
        .VECTOR_LEN(ZERO_PAD1_VECTOR_LEN)
    ) zero_pad1 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(data_i),
        .valid_i(valid_i),
        .last_i(last_i),
        .ready_o(ready_o),

        // streaming output
        .data_o(zero_pad1_data),
        .valid_o(zero_pad1_valid),
        .last_o(zero_pad1_last),
        .ready_i(conv1_ready[0])
    );

    // =========================================================================
    // conv1
    // =========================================================================
    wire [CONV1_BW - 1 : 0] conv1_data;
    wire                    conv1_valid;
    wire                    conv1_last;
    wire [0:0]              conv1_ready;

    conv_top #(
        .FRAME_LEN(CONV1_FRAME_LEN),
        .VECTOR_LEN(CONV1_VECTOR_LEN),
        .NUM_FILTERS(CONV1_NUM_FILTERS)
    ) conv1 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(zero_pad1_data),
        .valid_i(zero_pad1_valid),
        .last_i(zero_pad1_last),
        .ready_o(conv1_ready),

        // streaming output
        .data_o(conv1_data),
        .valid_o(conv1_valid),
        .last_o(conv1_last),
        .ready_i(max_pool1_ready[0]),

        // memory configuration
        .rd_en_i(conv1_rd_en_i),
        .wr_en_i(conv1_wr_en_i),
        .rd_wr_bank_i(conv1_rd_wr_bank_i),
        .rd_wr_addr_i(conv1_rd_wr_addr_i),
        .wr_data_i(conv1_wr_data_i),
        .rd_data_o(conv1_rd_data_o)
    );

    // =========================================================================
    // max_pool1
    // =========================================================================
    wire [MAX_POOL1_BW - 1 : 0] max_pool1_data;
    wire                        max_pool1_valid;
    wire                        max_pool1_last;
    wire [0:0]                  max_pool1_ready;

    max_pool #(
        .BW(MAX_POOL1_BW)
    ) max_pool1 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(conv1_data),
        .valid_i(conv1_valid),
        .last_i(conv1_last),
        .ready_o(max_pool1_ready),

        // streaming output
        .data_o(max_pool1_data),
        .valid_o(max_pool1_valid),
        .last_o(max_pool1_last),
        .ready_i(conv_sipo_ready[0])
    );

    // =========================================================================
    // conv_sipo
    // =========================================================================
    wire [CONV_SIPO_VECTOR_BW - 1 : 0] conv_sipo_data;
    wire                               conv_sipo_valid;
    wire                               conv_sipo_last;
    wire [0:0]                         conv_sipo_ready;

    conv_sipo #(
        .BW(CONV_SIPO_BW),
        .FRAME_LEN(CONV_SIPO_FRAME_LEN),
        .VECTOR_LEN(CONV_SIPO_VECTOR_LEN)
    ) conv_sipo_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(max_pool1_data),
        .valid_i(max_pool1_valid),
        .last_i(max_pool1_last),
        .ready_o(conv_sipo_ready),

        // streaming output
        .data_o(conv_sipo_data),
        .valid_o(conv_sipo_valid),
        .last_o(conv_sipo_last),
        .ready_i(zero_pad2_ready[0])
    );

    // =========================================================================
    // zero_pad2
    // =========================================================================
    wire [ZERO_PAD2_VECTOR_BW - 1 : 0] zero_pad2_data;
    wire                               zero_pad2_valid;
    wire                               zero_pad2_last;
    wire [0:0]                         zero_pad2_ready;

    zero_pad #(
        .BW(ZERO_PAD2_BW),
        .VECTOR_LEN(ZERO_PAD2_VECTOR_LEN)
    ) zero_pad2 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(conv_sipo_data),
        .valid_i(conv_sipo_valid),
        .last_i(conv_sipo_last),
        .ready_o(ready_o),

        // streaming output
        .data_o(zero_pad2_data),
        .valid_o(zero_pad2_valid),
        .last_o(zero_pad2_last),
        .ready_i(conv2_ready[0])
    );

    // =========================================================================
    // conv2
    // =========================================================================
    wire [CONV2_BW - 1 : 0] conv2_data;
    wire                    conv2_valid;
    wire                    conv2_last;
    wire [0:0]              conv2_ready;

    conv_top #(
        .FRAME_LEN(CONV2_FRAME_LEN),
        .VECTOR_LEN(CONV2_VECTOR_LEN),
        .NUM_FILTERS(CONV2_NUM_FILTERS)
    ) conv2 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(zero_pad2_data),
        .valid_i(zero_pad2_valid),
        .last_i(zero_pad2_last),
        .ready_o(conv2_ready),

        // streaming output
        .data_o(conv2_data),
        .valid_o(conv2_valid),
        .last_o(conv2_last),
        .ready_i(max_pool2_ready[0]),

        // memory configuration
        .rd_en_i(conv2_rd_en_i),
        .wr_en_i(conv2_wr_en_i),
        .rd_wr_bank_i(conv2_rd_wr_bank_i),
        .rd_wr_addr_i(conv2_rd_wr_addr_i),
        .wr_data_i(conv2_wr_data_i),
        .rd_data_o(conv2_rd_data_o)
    );

    // =========================================================================
    // max_pool2
    // =========================================================================
    wire [MAX_POOL2_BW - 1 : 0] max_pool2_data;
    wire                        max_pool2_valid;
    wire                        max_pool2_last;
    wire [0:0]                  max_pool2_ready;

    max_pool #(
        .BW(MAX_POOL2_BW)
    ) max_pool2 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(conv2_data),
        .valid_i(conv2_valid),
        .last_i(conv2_last),
        .ready_o(max_pool2_ready),

        // streaming output
        .data_o(max_pool2_data),
        .valid_o(max_pool2_valid),
        .last_o(max_pool2_last),
        .ready_i(fc_ready[0])
    );

    // =========================================================================
    // fc
    // =========================================================================
    wire [FC_VECTOR_O_BW - 1 : 0] fc_data;
    wire                          fc_valid;
    wire                          fc_last;
    wire [0:0]                    fc_ready;

    fc_top #(
        .I_BW(FC_I_BW),
        .BIAS_BW(FC_BIAS_BW),
        .O_BW(FC_O_BW),
        .FRAME_LEN(FC_FRAME_LEN),
        .NUM_CLASSES(FC_NUM_CLASSES)
    ) fc_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(max_pool2_data),
        .valid_i(max_pool2_valid),
        .last_i(max_pool2_last),
        .ready_o(fc_ready),

        // streaming output
        .data_o(fc_data),
        .valid_o(fc_valid),
        .last_o(fc_last),
        .ready_i(argmax_ready[0]),

        // memory configuration
        .rd_en_i(fc_rd_en_i),
        .wr_en_i(fc_wr_en_i),
        .rd_wr_bank_i(fc_rd_wr_bank_i),
        .rd_wr_addr_i(fc_rd_wr_addr_i),
        .wr_data_i(fc_wr_data_i),
        .rd_data_o(fc_rd_data_o)
    );

    // =========================================================================
    // argmax
    // =========================================================================
    wire [ARGMAX_O_BW - 1 : 0] argmax_data;
    wire                       argmax_valid;
    wire                       argmax_last;
    wire [0:0]                 argmax_ready;

    argmax #(
        .I_BW(ARGMAX_I_BW)
    ) argmax_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(fc_data),
        .valid_i(fc_valid),
        .last_i(fc_last),
        .ready_o(argmax_ready),

        // streaming output
        .data_o(argmax_data),
        .valid_o(argmax_valid),
        .last_o(argmax_last),
        .ready_i(wake_ready[0])
    );

    // =========================================================================
    // wake
    // =========================================================================
    wire [0:0] wake_ready;

    wake #(
        .NUM_CLASSES(WAKE_NUM_CLASSES)
    ) wake_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(argmax_data),
        .valid_i(argmax_valid),
        .last_i(argmax_last),
        .ready_o(wake_ready),

        // wake output
        .wake_o(wake_o),
        .valid_o(wake_valid)
    );

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, wrd);
      #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Zero Pad
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Adds 1 leading and 1 trailing zero to stream
//
// Minimum dead time between frames is 2 clock cycles.
// This increased dead-time is needed because we reduce latency in this
// module to just 1 cycle.
//
// TODO: Gate registers with valid
// =============================================================================

module zero_pad #(
    parameter BW         = 8,
    parameter VECTOR_LEN = 13
) (
    // clock and reset
    input                             clk_i,
    input                             rst_n_i,

    // streaming input
    input  signed [VECTOR_BW - 1 : 0] data_i,
    input                             valid_i,
    input                             last_i,
    output                            ready_o,

    // streaming output
    output signed [VECTOR_BW - 1 : 0] data_o,
    output                            valid_o,
    output                            last_o,
    input                             ready_i
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam VECTOR_BW = VECTOR_LEN * BW;

    // =========================================================================
    // Delay Lines
    // =========================================================================
    reg signed [VECTOR_BW - 1 : 0] data_q, data_q2;
    reg valid_q, valid_q2, valid_q3, last_q, last_q2, last_q3, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q  <= 'b0;
            valid_q2 <= 'b0;
            valid_q3 <= 'b0;
            last_q   <= 'b0;
            last_q2  <= 'b0;
            last_q3  <= 'b0;
            ready_q  <= 'b0;
            data_q   <= 'b0;
            data_q2  <= 'b0;
        end else begin
            valid_q  <= valid_i;
            valid_q2 <= valid_q;
            valid_q3 <= valid_q2;
            last_q   <= last_i;
            last_q2  <= last_q;
            last_q3  <= last_q2;
            ready_q  <= ready_i;
            data_q   <= (valid_i) ? data_i : 0;
            data_q2  <= (valid_q) ? data_q : 0;
        end
    end

    // =========================================================================
    // Edge Detectors
    // =========================================================================
    // positive edge detector to emit initial 0
    wire valid_i_pos_edge  = valid_i  & (!valid_q);

    // negative edge detectors to extend valid_o, emit last 0
    wire valid_q_neg_edge  = valid_q2 & (!valid_q);
    wire valid_q2_neg_edge = valid_q3 & (!valid_q2);

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = (valid_q2_neg_edge | valid_i_pos_edge) ? 0 : data_q2;
    assign valid_o = valid_q | valid_q_neg_edge | valid_q2_neg_edge;
    assign last_o  = last_q3;
    assign ready_o = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, zero_pad);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Comb
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Comb element of the integrator-comb filter. Produces the input delayed by
// WINDOW_LEN subtracted from the input.
// =============================================================================

module comb (
    // clock and reset
    input               clk_i,
    input               rst_n_i,

    // streaming input
    input               en_i,
    input               data_i,
    input               valid_i,

    // streaming output
    output signed [1:0] data_o,
    output              valid_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam WINDOW_LEN = 250;

    // =========================================================================
    // Delay Block
    // =========================================================================
    reg [WINDOW_LEN - 1 : 0] reg_fifo;
    // First register
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            reg_fifo[0] <= 'd0;
        end else begin
            if (valid_i) begin
                reg_fifo[0] <= data_i;
            end else begin
                reg_fifo[0] <= reg_fifo[0];
            end
        end
    end
    // Subsequent registers
    genvar i;
    generate
        for (i = 1; i < WINDOW_LEN; i = i + 1) begin
            always @(posedge clk_i) begin
                if (!rst_n_i | !en_i) begin
                    reg_fifo[i] <= 'd0;
                end else begin
                    if (valid_i) begin
                        reg_fifo[i] <= reg_fifo[i-1];
                    end else begin
                        reg_fifo[i] <= reg_fifo[i];
                    end
                end
            end
        end
    endgenerate
    
    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & valid_i);
    assign data_o  = data_i - reg_fifo[WINDOW_LEN - 1];

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, comb);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Decimator
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Decimates input by a given rate. This component is used after the integrator-
// comb filter
// =============================================================================

module decimator (
    // clock and reset
    input                       clk_i,
    input                       rst_n_i,

    // streaming input
    input                       en_i,
    input [DATA_BW - 1 : 0]     data_i,
    input                       valid_i,

    // streaming output
    output [DATA_BW - 1 : 0]    data_o,
    output                      valid_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam DATA_BW = 8;
    localparam DECIM_FACTOR = 250;
    localparam COUNTER_BW = $clog2(DECIM_FACTOR);

    // =========================================================================
    // Counter
    // =========================================================================
    reg [COUNTER_BW - 1 : 0] counter;  // counts 0 to 249
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            counter <= 'd0;
        end else begin
            if (valid_i & (counter == DECIM_FACTOR - 1)) begin
                counter <= 'd0;
            end else if (valid_i) begin
                counter <= counter + 'd1;
            end else begin
                counter <= counter;
            end
        end
    end
    
    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = data_i;
    assign valid_o = (en_i & valid_i & (counter == 'd0));

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, decimator);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       DFE
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Top level module of the digital front end. Contains PDM clock generation,
// PDM sampling, and PDM filtering. Produces a 8b 16kHz audio stream which is
// sent to ACO.
// =============================================================================

module dfe (
    // clock, reset, and enable
    input                               clk_i,
    input                               rst_n_i,
    input                               en_i,

    // pdm input
    input                               pdm_data_i,

    // pdm clock output
    output                              pdm_clk_o,

    // streaming output
    output signed [OUTPUT_BW - 1 : 0]   data_o,
    output                              valid_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    // These are not parameterized in the downstream modules; they are only
    // here for readability
    localparam OUTPUT_BW = 8;

    // =========================================================================
    // PDM Clock Generator
    // =========================================================================
    pdm_clk comb_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .pdm_clk_o(pdm_clk_o)
    );
    
    // =========================================================================
    // Sampler
    // =========================================================================
    wire sampler_data_o;
    wire sampler_valid_o;
    sampler sampler_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .pdm_clk_i(pdm_clk_o),
        .data_i(pdm_data_i),

        .data_o(sampler_data_o),
        .valid_o(sampler_valid_o)
    );

    // =========================================================================
    // Filter
    // =========================================================================
    wire [OUTPUT_BW - 1 : 0] filter_data_o;
    wire filter_valid_o;
    filter filter_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(sampler_data_o),
        .valid_i(sampler_valid_o),

        .data_o(filter_data_o),
        .valid_o(filter_valid_o)
    );

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = filter_data_o;
    assign valid_o = filter_valid_o;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, dfe);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Filter
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Single stage integrator-comb filter with decimation and DC cancel. Converts
// a 4MHz PDM input signal into a 8b 16kHz signal.
// =============================================================================

module filter (
    // clock and reset
    input                               clk_i,
    input                               rst_n_i,

    // input
    input                               en_i,
    input                               data_i,
    input                               valid_i,

    // streaming output
    output signed [OUTPUT_BW - 1 : 0]   data_o,
    output                              valid_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    // These are not parameterized in the downstream modules; they are only
    // here for readability
    localparam OUTPUT_BW = 8;
    localparam COMB_O_BW = 2;
    localparam INTEGRATOR_O_BW = 8;
    localparam DECIMATOR_O_BW = 8;
    localparam DC_CANCEL_O_BW = 8;
    localparam DC_CANCEL_OFFSET = 'd125;

    // =========================================================================
    // Comb
    // =========================================================================
    wire signed [COMB_O_BW - 1 : 0] comb_data_o;
    wire comb_valid_o;
    comb comb_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(data_i),
        .valid_i(valid_i),

        .data_o(comb_data_o),
        .valid_o(comb_valid_o)
    );
    
    // =========================================================================
    // Integrator
    // =========================================================================
    wire [INTEGRATOR_O_BW - 1 : 0] integrator_data_o;
    wire integrator_valid_o;
    integrator integrator_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(comb_data_o),
        .valid_i(comb_valid_o),

        .data_o(integrator_data_o),
        .valid_o(integrator_valid_o)
    );

    // =========================================================================
    // Decimation
    // =========================================================================
    wire [DECIMATOR_O_BW - 1 : 0] decimator_data_o;
    wire decimator_valid_o;
    decimator decimator_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(integrator_data_o),
        .valid_i(integrator_valid_o),

        .data_o(decimator_data_o),
        .valid_o(decimator_valid_o)
    );
    
    // =========================================================================
    // DC Cancel
    // =========================================================================
    wire signed [DC_CANCEL_O_BW - 1 : 0] dc_cancel_data_o;
    wire dc_cancel_valid_o;
    assign dc_cancel_data_o = decimator_data_o - DC_CANCEL_OFFSET;
    assign dc_cancel_valid_o = decimator_valid_o;

    // =========================================================================
    // Ignore First Value
    // =========================================================================
    // First output value is garbage, so ignore it.
    reg first_value;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            first_value <= 'd1;
        end else begin
            if (dc_cancel_valid_o) begin
                first_value <= 'd0;
            end else begin
                first_value <= first_value;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = dc_cancel_data_o;
    assign valid_o = (!first_value & dc_cancel_valid_o);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, filter);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Integrator
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Integrator element of the integrator-comb filter. Outputs the input added to
// the previous output. Input is either -1, 0, or 1. An input of -2 will be
// misinterpreted as a -1, so it is not allowed.
// =============================================================================

module integrator (
    // clock and reset
    input                               clk_i,
    input                               rst_n_i,

    // streaming input
    input                               en_i,
    input signed [1:0]                  data_i,
    input                               valid_i,

    // streaming output
    output [OUTPUT_BW - 1 : 0]          data_o,
    output                              valid_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam OUTPUT_BW = 8;

    // =========================================================================
    // Accumulation Register
    // =========================================================================
    reg [OUTPUT_BW - 1 : 0] accumulated;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            accumulated <= 'd0;
        end else begin
            if (valid_i) begin
                accumulated <= data_o;
            end else begin
                accumulated <= accumulated;
            end
        end
    end
    
    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = (data_i[1]) ? accumulated - 'd1
                                 : accumulated + data_i[0];
    assign valid_o = (en_i & valid_i);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, integrator);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       PDM Clock
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Generates a 4MHz glock used to drive the microphone PDM interface.
// When en_i is low, the clock output is low which keeps the mic in low power
// mode.
// =============================================================================

module pdm_clk (
    // clock and reset
    input               clk_i,
    input               rst_n_i,

    // input
    input               en_i,

    // output
    output              pdm_clk_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam F_SYSTEM_CLK   = 16000000;  // 16 MHz
    localparam COUNTER_PERIOD = F_SYSTEM_CLK / 4000000;  // 4 cycles
    localparam HALF_PERIOD    = COUNTER_PERIOD / 2;      // 2 cycles
    localparam COUNTER_BW     = $clog2(COUNTER_PERIOD);  // 2 bits

    // =========================================================================
    // Counter
    // =========================================================================
    reg [COUNTER_BW - 1 : 0] counter;  // counts 0 to 3
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            counter <= 'd0;
        end else begin
            if (counter == COUNTER_PERIOD - 1) begin
                counter <= 'd0;
            end else begin
                counter <= counter + 'd1;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    // set pdm_clk_o to high when counter is 2 and 3:
    assign pdm_clk_o = (counter >= HALF_PERIOD);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, pdm_clk);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       Sampler
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Samples data coming from the microphone on the positive edge of the PDM
// clock. If timing is not being met, the PDM data transition phase can be
// shifted by 180 degrees by switching the microphone's left/right
// configuration.
// =============================================================================

module sampler (
    // clock and reset
    input                       clk_i,
    input                       rst_n_i,

    // input
    input                       en_i,
    input                       pdm_clk_i,
    input                       data_i,

    // streaming output
    output                      data_o,
    output                      valid_o
);

    // =========================================================================
    // PDM Clock Positive Edge Detection
    // =========================================================================
    reg pdm_clk_q;  // counts 0 to 3
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            pdm_clk_q <= 'd0;
        end else begin
            pdm_clk_q <= pdm_clk_i;
        end
    end
    wire pdm_posedge = (pdm_clk_i & !pdm_clk_q);

    // =========================================================================
    // Data Sampling
    // =========================================================================
    reg data_q, valid_q;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            data_q <= 'd0;
            valid_q <= 'd0;
        end else begin
            if (pdm_posedge) begin
                data_q <= data_i;
                valid_q <= 'd1;
            end else begin
                data_q <= 'd0;
                valid_q <= 'd0;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = data_q;
    assign valid_o = valid_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, sampler);
        #1;
    end
    `endif

endmodule
// =============================================================================
// Module:       ACO
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Top level module for the acoustic featurization pipeline.
// =============================================================================

module aco (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input signed  [I_BW - 1 : 0]            data_i,
    input                                   valid_i,

    // streaming output
    output         [O_BW - 1 : 0]           data_o,
    output                                  valid_o,
    output                                  last_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam PREEMPH_I_BW             = 8;
    localparam I_BW                     = PREEMPH_I_BW;
    localparam PREEMPH_O_BW             = 9;

    localparam FFT_FRAMING_I_BW         = 9;
    localparam FFT_FRAMING_O_BW         = 16;
    localparam FFT_FRAME_LEN            = 256;
    localparam FFT_FRAMING_CADENCE      = 1;
                                          // take 256 samples every 20ms:
    localparam FFT_FRAMING_SKIP_ELEMS   = 320 - FFT_FRAME_LEN;

    localparam FFT_I_BW                 = 16;
    localparam FFT_O_BW                 = 21 * 2;

    localparam POWER_SPECTRUM_I_BW      = 21 * 2;
    localparam POWER_SPECTRUM_O_BW      = 32;

    localparam FILTERBANK_I_BW          = 32;
    localparam FILTERBANK_O_BW          = 32;

    localparam LOG_I_BW                 = 32;
    localparam LOG_O_BW                 = 8;

    localparam DCT_FRAMING_I_BW         = 8;
    localparam DCT_FRAMING_O_BW         = 8;
    localparam DCT_FRAME_LEN            = 32;
    localparam DCT_FRAMING_CADENCE      = 13;  // hold each value for 13 cycles
    localparam DCT_FRAMING_SKIP_ELEMS   = 0;

    localparam DCT_I_BW                 = 8;
    localparam DCT_COEFS                = 13;
    localparam DCT_O_BW                 = 16;

    localparam QUANT_I_BW               = 16;
    localparam QUANT_O_BW               = 8;

    localparam PACKING_I_BW             = 8;
    localparam PACKING_O_BW             = PACKING_I_BW * DCT_COEFS;

    localparam WRD_FRAMING_I_BW         = PACKING_O_BW;
    localparam WRD_FRAMING_O_BW         = PACKING_O_BW;
    localparam WRD_FRAME_LEN            = 50;
    localparam WRD_FRAMING_CADENCE      = 1;
    localparam WRD_FRAMING_SKIP_ELEMS   = 0;

    localparam O_BW                     = WRD_FRAMING_O_BW;

    // =========================================================================
    // Preemphasis
    // =========================================================================
    wire signed [PREEMPH_O_BW - 1 : 0]  preemph_data_o;
    wire                                preemph_valid_o;
    preemphasis preemphasis_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(data_i),
        .valid_i(valid_i),

        .data_o(preemph_data_o),
        .valid_o(preemph_valid_o)
    );

    // =========================================================================
    // Framing for FFT
    // =========================================================================
    wire signed [FFT_FRAMING_O_BW - 1 : 0]      fft_framing_data_o;
    wire                                        fft_framing_valid_o;
    wire                                        fft_framing_last_o;
    framing #(
        .I_BW(FFT_FRAMING_I_BW),
        .O_BW(FFT_FRAMING_O_BW),
        .FRAME_LEN(FFT_FRAME_LEN),
        .CADENCE_CYC(FFT_FRAMING_CADENCE),
        .SKIP_ELEMS(FFT_FRAMING_SKIP_ELEMS)
    ) fft_framing_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(preemph_data_o),
        .valid_i(preemph_valid_o),

        .data_o(fft_framing_data_o),
        .valid_o(fft_framing_valid_o),
        .last_o(fft_framing_last_o)
    );

    // =========================================================================
    // FFT
    // =========================================================================
    wire signed [FFT_O_BW - 1 : 0]      fft_data_o;
    wire                                fft_valid_o;
    wire                                fft_last_o;
    fft_wrapper fft_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(fft_framing_data_o),
        .valid_i(fft_framing_valid_o),
        .last_i(fft_framing_last_o),

        .data_o(fft_data_o),
        .valid_o(fft_valid_o),
        .last_o(fft_last_o)
    );

    // =========================================================================
    // Power Spectrum
    // =========================================================================
    wire [POWER_SPECTRUM_O_BW - 1 : 0]  power_spectrum_data_o;
    wire                                power_spectrum_valid_o;
    wire                                power_spectrum_last_o;
    power_spectrum power_spectrum_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(fft_data_o),
        .valid_i(fft_valid_o),
        .last_i(fft_last_o),

        .data_o(power_spectrum_data_o),
        .valid_o(power_spectrum_valid_o),
        .last_o(power_spectrum_last_o)
    );

    // =========================================================================
    // MFCC Filterbank
    // =========================================================================
    wire [FILTERBANK_O_BW - 1 : 0]      filterbank_data_o;
    wire                                filterbank_valid_o;
    wire                                filterbank_last_o;
    filterbank filterbank_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(power_spectrum_data_o),
        .valid_i(power_spectrum_valid_o),
        .last_i(power_spectrum_last_o),

        .data_o(filterbank_data_o),
        .valid_o(filterbank_valid_o),
        .last_o(filterbank_last_o)
    );

    // =========================================================================
    // Log
    // =========================================================================
    wire [LOG_O_BW - 1 : 0]             log_data_o;
    wire                                log_valid_o;
    wire                                log_last_o;
    log log_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(filterbank_data_o),
        .valid_i(filterbank_valid_o),
        .last_i(filterbank_last_o),

        .data_o(log_data_o),
        .valid_o(log_valid_o),
        .last_o(log_last_o)
    );

    // =========================================================================
    // Framing for DCT
    // =========================================================================
    wire [DCT_FRAMING_O_BW - 1 : 0]     dct_framing_data_o;
    wire                                dct_framing_valid_o;
    wire                                dct_framing_last_o;
    framing #(
        .I_BW(DCT_FRAMING_I_BW),
        .O_BW(DCT_FRAMING_O_BW),
        .FRAME_LEN(DCT_FRAME_LEN),
        .CADENCE_CYC(DCT_FRAMING_CADENCE),
        .SKIP_ELEMS(DCT_FRAMING_SKIP_ELEMS)
    ) dct_framing_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(log_data_o),
        .valid_i(log_valid_o),

        .data_o(dct_framing_data_o),
        .valid_o(dct_framing_valid_o),
        .last_o(dct_framing_last_o)
    );

    // =========================================================================
    // DCT
    // =========================================================================
    wire signed [DCT_O_BW - 1 : 0]      dct_data_o;
    wire                                dct_valid_o;
    wire                                dct_last_o;
    dct dct_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(dct_framing_data_o),
        .valid_i(dct_framing_valid_o),
        .last_i(dct_framing_last_o),

        .data_o(dct_data_o),
        .valid_o(dct_valid_o),
        .last_o(dct_last_o)
    );

    // =========================================================================
    // Quantization
    // =========================================================================
    wire signed [QUANT_O_BW - 1 : 0]    quant_data_o;
    wire                                quant_valid_o;
    wire                                quant_last_o;
    quant quant_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(dct_data_o),
        .valid_i(dct_valid_o),
        .last_i(dct_last_o),

        .data_o(quant_data_o),
        .valid_o(quant_valid_o),
        .last_o(quant_last_o)
    );

    // =========================================================================
    // Packing
    // =========================================================================
    wire signed [PACKING_O_BW - 1 : 0]  packing_data_o;
    wire                                packing_valid_o;
    wire                                packing_last_o;
    packing packing_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(quant_data_o),
        .valid_i(quant_valid_o),
        .last_i(quant_last_o),

        .data_o(packing_data_o),
        .valid_o(packing_valid_o),
        .last_o(packing_last_o)
    );

    // =========================================================================
    // Framing for WRD
    // =========================================================================
    wire [WRD_FRAMING_O_BW - 1 : 0]     wrd_framing_data_o;
    wire                                wrd_framing_valid_o;
    wire                                wrd_framing_last_o;
    framing #(
        .I_BW(WRD_FRAMING_I_BW),
        .O_BW(WRD_FRAMING_O_BW),
        .FRAME_LEN(WRD_FRAME_LEN),
        .CADENCE_CYC(WRD_FRAMING_CADENCE),
        .SKIP_ELEMS(WRD_FRAMING_SKIP_ELEMS)
    ) wrd_framing_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(packing_data_o),
        .valid_i(packing_valid_o),

        .data_o(wrd_framing_data_o),
        .valid_o(wrd_framing_valid_o),
        .last_o(wrd_framing_last_o)
    );

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & wrd_framing_valid_o);
    assign data_o = wrd_framing_data_o;
    assign last_o = wrd_framing_last_o;

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, aco);
        #1;
    end
    `endif
    `endif

endmodule
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

module dct (
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
    localparam I_BW          = 8;
    localparam O_BW          = 16;
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
    // Element Counter
    // =========================================================================
    reg [ELEM_COUNT_BW - 1 : 0] elem_counter;
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
    wire last_elem = (elem_counter == FRAME_LEN - 1);

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
    reg signed [COEF_BW - 1 : 0] coefs;
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
// =============================================================================
// Module:       FFT IP Core Wrapper
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        Wraps the 256 sample FFT core as a 129 sample real FFT in a
//               streaming interface. De-assertions of valid_i are not
//               permitted. Operates in a low duty-cycle manner. Only one frame
//               can be processed at a time. This is OK since we need it to
//               operate at 50 Hz minimum, and one full use of the core with
//               reset takes under 1000 clock cycles.
//
//
// On first valid unset the reset, enable the fft clock, and start streaming data
// On sync, count the number of data points up until 128, then emit last and
//      reset the fft core, keeping it reset until the next valid frame
// =============================================================================

module fft_wrapper (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input  signed [I_BW - 1 : 0]            data_i,
    input                                   valid_i,
    input                                   last_i,

    // streaming output
    output  signed [O_BW - 1 : 0]           data_o,  // real in higher bits
    output                                  valid_o,
    output                                  last_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam I_BW         = 16;  // real input
    localparam O_BW         = 21 * 2;  // complex output

    // output sample counter for holding valid_o
    localparam FFT_LEN                  = 256;
    localparam RFFT_LEN                 = $rtoi(FFT_LEN / 2 + 1);
    localparam OUTPUT_COUNTER_BW        = $clog2(RFFT_LEN);

    // =========================================================================
    // FFT Enable Logic
    // =========================================================================
    // Latch valid starting with the first valid input and resetting after
    // the last valid output. This is used to enable the FFT core.
    reg valid_i_latch;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            valid_i_latch <= 'd0;
        end else begin
            if (last_o) begin  // reset after final valid output sample
                valid_i_latch <= 'd0;
            end else if (valid_i) begin  // set to high after first valid input
                valid_i_latch <= 'd1;
            end else begin
                valid_i_latch <= valid_i_latch;
            end
        end
    end
    wire fft_en = (en_i & (valid_i | valid_i_latch));

    // =========================================================================
    // FFT Core
    // =========================================================================
    wire sync;
    wire [2 * I_BW - 1 : 0] fft_data_in = {data_i, {I_BW{1'b0}}};
    fftmain fft_inst (
        .i_clk(clk_i),
        .i_reset(!fft_en),
        .i_ce(fft_en),

        .i_sample(fft_data_in),
        .o_result(data_o),
        .o_sync(sync)
    );

    // =========================================================================
    // Valid Output Logic
    // =========================================================================
    wire valid_o_start = sync;
    reg [OUTPUT_COUNTER_BW - 1: 0] output_counter;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            output_counter <= 'd0;
        end else begin
            if (last_o) begin
                // reset counter after a valid frame output has finished
                output_counter <= 'd0;
            end else if (valid_o) begin
                // already counting or should begin counting
                output_counter <= output_counter + 'd1;
            end else begin
                output_counter <= output_counter;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (valid_o_start | (output_counter > 'd0));
    assign last_o  = (output_counter == RFFT_LEN - 1);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, fft_wrapper);
        #1;
    end
    `endif
    `endif

endmodule
// =============================================================================
// Module:       Filterbank
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        Takes in an input power spectrum and multiplies it by MFCC
//               overlapping triangular windows.
//               Deassertions of valid are not permitted.
// =============================================================================

module filterbank (
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
    localparam O_BW         = 32;

    localparam EVEN_COEFFILE            = "coef_even.hex";
    localparam ODD_COEFFILE             = "coef_odd.hex";
    localparam EVEN_BOUNDARYFILE        = "boundary_even.hex";
    localparam ODD_BOUNDARYFILE         = "boundary_odd.hex";

    // =========================================================================
    // Even and Odd Filterbanks
    // =========================================================================
    wire [O_BW - 1 : 0] data_even;
    wire valid_even, last_even;
    filterbank_half #(
        .COEFFILE(EVEN_COEFFILE),
        .BOUNDARYFILE(EVEN_BOUNDARYFILE)
    ) even_filterbanks (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(data_i),
        .valid_i(valid_i),
        .last_i(last_i),

        .data_o(data_even),
        .valid_o(valid_even),
        .last_o(last_even)
    );

    wire [O_BW - 1 : 0] data_odd;
    wire valid_odd, last_odd;
    filterbank_half #(
        .COEFFILE(ODD_COEFFILE),
        .BOUNDARYFILE(ODD_BOUNDARYFILE)
    ) odd_filterbanks (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(data_i),
        .valid_i(valid_i),
        .last_i(last_i),

        .data_o(data_odd),
        .valid_o(valid_odd),
        .last_o(last_odd)
    );

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & (valid_even | valid_odd));
    assign data_o = valid_even ? data_even : data_odd;
    assign last_o = last_i;

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, filterbank);
        #1;
    end
    `endif
    `endif

endmodule
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

    generate
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
    endgenerate

    generate
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
    endgenerate

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
// =============================================================================
// Module:       Framing
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        Aggregates 256 samples into a FIFO and outputs them in one
//               large block.
// =============================================================================

module framing # (
    parameter I_BW         = 9,   // preemphasis input
    parameter O_BW         = 16,  // output to FFT
    parameter FRAME_LEN    = 256,
    parameter CADENCE_CYC  = 3,  // how long to hold output data before changing
                                 // Must be lower than the rate at which data
                                 // comes in.
    parameter SKIP_ELEMS   = 0   // num elements to skip after a complete frame
) (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input  signed [I_BW - 1 : 0]            data_i,
    input                                   valid_i,

    // streaming output
    output  signed [O_BW - 1 : 0]           data_o,
    output                                  valid_o,
    output                                  last_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    // localparam I_BW         = 9;   // preemphasis input
    // localparam O_BW         = 16;  // FFT output
    // localparam FRAME_LEN    = 256;
    localparam FIFO_DEPTH       = FRAME_LEN + 4;   // 4 spaces of headroom
    localparam COUNTER_BW       = $clog2(FIFO_DEPTH);
    localparam FULL_PERIOD      = FRAME_LEN + SKIP_ELEMS;
    localparam SKIP_COUNTER_BW  = $clog2(FIFO_DEPTH + SKIP_ELEMS);
    localparam CADENCE_BW       = $clog2(CADENCE_CYC);

    // =========================================================================
    // State Machine
    // =========================================================================
    localparam STATE_LOAD   = 1'd0,
               STATE_UNLOAD = 1'd1;
    reg state;
    reg [COUNTER_BW - 1 : 0] frame_elem;  // Number of frame elements outputted.
                                          // Zero-indexed counting, so last
                                          // element is FRAME_LEN - 1
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            frame_elem <= 'd0;
            state <= STATE_LOAD;
        end else begin
            case (state)
                STATE_LOAD: begin
                    frame_elem <= 'd0;
                    state      <= (fifo_count == FRAME_LEN) ? STATE_UNLOAD
                                                            : STATE_LOAD;
                end
                STATE_UNLOAD: begin
                    if (next_elem) frame_elem <= frame_elem + 'd1;
                    else frame_elem <= frame_elem;
                    state      <= (last_elem & next_elem) ? STATE_LOAD
                                                          : STATE_UNLOAD;
                end
                default: begin
                    frame_elem <= 'd0;
                    state <= STATE_LOAD;
                end
            endcase
        end
    end
    wire last_elem = (frame_elem == FRAME_LEN - 'd1);

    // =========================================================================
    // FIFO element tracking
    // =========================================================================
    reg [COUNTER_BW - 1 : 0] fifo_count;  // number of elements in the fifo
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            fifo_count <= 'd0;
        end else begin
            if (fifo_enq & !fifo_deq) begin
                fifo_count <= fifo_count + 'd1;
            end else if (!fifo_enq & fifo_deq) begin
                fifo_count <= fifo_count - 'd1;
            end else begin
                fifo_count <= fifo_count;
            end
        end
    end

    // =========================================================================
    // Skip Counter
    // =========================================================================
    // Tracks the number of elements seen across one period, including
    // elements that are to be skipped
    reg [COUNTER_BW - 1 : 0] skip_count;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            skip_count <= 'd0;
        end else begin
            if (valid_i & (skip_count == FULL_PERIOD - 'd1)) begin
                skip_count = 'd0;
            end else if (valid_i) begin
                skip_count <= skip_count + 'd1;
            end else begin
                skip_count <= skip_count;
            end
        end
    end
    wire skip = (skip_count >= FRAME_LEN);  // skip if already have FRAME_LEN
                                            // elements in the current period

    // =========================================================================
    // Cadence
    // =========================================================================
    // Determines how long to hold an output
    reg [CADENCE_BW - 1 : 0] cadence;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            cadence <= 'd0;
        end else begin
            if (next_elem) begin  // reset to 0
                cadence <= 'd0;
            end else if (state == STATE_UNLOAD) begin
                cadence <= cadence + 'd1;
            end else begin
                cadence <= 'd0;
            end
        end
    end
    wire next_elem = (cadence == CADENCE_CYC - 'd1);

    // =========================================================================
    // FIFO
    // =========================================================================
    wire signed [I_BW - 1 : 0]  fifo_dout;
    wire                        fifo_deq = ((state == STATE_UNLOAD) & next_elem);
    wire                        fifo_enq = (en_i & valid_i & !skip);
    fifo #(
        .DATA_WIDTH(I_BW),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) fifo_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i & en_i),

        .enq_i(fifo_enq),
        .din_i(data_i),

        .deq_i(fifo_deq),
        .dout_o(fifo_dout),

        .full_o_n(),
        .empty_o_n()
    );

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & (state == STATE_UNLOAD));
    assign data_o = fifo_dout;
    assign last_o = (fifo_deq & last_elem);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, framing);
        #1;
    end
    `endif
    `endif

endmodule
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
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, log);
        #1;
    end
    `endif
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
// =============================================================================
// Module:       Power Spectrum
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        Computes the power spectrum of a frequency domain signal from
//               the fft wrapper, which is the real part squared added to the
//               imaginary part squared.
// =============================================================================

module power_spectrum (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input  signed [I_BW * 2 - 1 : 0]        data_i,
    input                                   valid_i,
    input                                   last_i,

    // streaming output
    output [O_BW - 1 : 0]                   data_o,
    output                                  valid_o,
    output                                  last_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam I_BW         = 21;
    localparam O_BW         = 32;

    // =========================================================================
    // Register input to reduce long path length
    // =========================================================================
    reg signed [I_BW * 2 - 1 : 0] data_i_q;
    reg valid_i_q;
    reg last_i_q;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            data_i_q <= 'd0;
            valid_i_q <= 'd0;
            last_i_q <= 'd0;
        end else begin
            if (valid_i) begin
                data_i_q <= data_i;
                valid_i_q <= valid_i;
                last_i_q <= last_i;
            end else begin
                data_i_q <= 'd0;
                valid_i_q <= 'd0;
                last_i_q <= 'd0;
            end
        end
    end

    // =========================================================================
    // Unpacked Data
    // =========================================================================
    wire signed [I_BW - 1 : 0] real_i = data_i_q[I_BW * 2 - 1 : I_BW];
    wire signed [I_BW - 1 : 0] imag_i = data_i_q[I_BW - 1 : 0];

    // =========================================================================
    // Result
    // =========================================================================
    wire [O_BW - 1 : 0] data = (real_i * real_i) + (imag_i * imag_i);
    wire valid = valid_i_q;
    wire last = last_i_q;

    // =========================================================================
    // Register output to reduce long path length
    // =========================================================================
    reg [O_BW - 1 : 0] data_q;
    reg valid_q;
    reg last_q;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            data_q <= 'd0;
            valid_q <= 'd0;
            last_q <= 'd0;
        end else begin
            if (valid) begin
                data_q <= data;
                valid_q <= valid;
                last_q <= last;
            end else begin
                data_q <= 'd0;
                valid_q <= 'd0;
                last_q <= 'd0;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o = data_q;
    assign valid_o = valid_q;
    assign last_o = last_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, power_spectrum);
        #1;
    end
    `endif
    `endif

endmodule
// =============================================================================
// Module:       Preemphasis
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        Implements a simple high-pass filter by multiplying the
//               delayed signal by 0.97 and subtracting that from the
//               undelayed signal. The multiplication is implemented as a
//               multiplication by 31 and a right-shift by 5.
// =============================================================================

module preemphasis (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input  signed [I_BW - 1 : 0]            data_i,
    input                                   valid_i,

    // streaming output
    output  signed [O_BW - 1 : 0]           data_o,
    output                                  valid_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam I_BW         = 8;   // PCM input
    localparam O_BW         = 9;
    localparam MUL          = 31;
    localparam SHIFT        = 5;

    // =========================================================================
    // Delayed and scaled data
    // =========================================================================
    reg signed [I_BW - 1 : 0] data_q;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            data_q <= 'd0;
        end else begin
            if (valid_i) begin
                data_q <= data_i;
            end else begin
                data_q <= data_q;
            end
        end
    end
    wire signed [O_BW - 1 : 0] data_scaled = (data_q * MUL) >>> SHIFT;

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & valid_i);
    assign data_o = data_i - data_scaled;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, preemphasis);
        #1;
    end
    `endif
    `endif

endmodule
// =============================================================================
// Module:       ACO Quantizer
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        
//
// Quantize 16b values to 8b values such that they saturate if they don't fit
// within 8b.
// =============================================================================

module quant (
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
    localparam I_BW         = 16;
    localparam O_BW         = 8;
    localparam CLIP         = $pow(2, O_BW - 1) - 1;  // clip to this if larger

    wire signed [O_BW - 1 : 0] lower = data_i[O_BW - 1 : 0]; // lower O_BW bits

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o = (data_i > CLIP) ? CLIP 
                                    : ((data_i < -CLIP-1) ? -CLIP-1
                                                          : lower);
    assign valid_o = (en_i & valid_i);
    assign last_o  = last_i;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, quant);
        #1;
    end
    `endif
    `endif

endmodule

// Copyright (c) 2000-2012 Bluespec, Inc.

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// $Revision: 29755 $
// $Date: 2012-10-22 13:58:12 +0000 (Mon, 22 Oct 2012) $

`ifdef BSV_ASSIGNMENT_DELAY
`else
  `define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

`ifdef BSV_ASYNC_RESET
 `define BSV_ARESET_EDGE_META or `BSV_RESET_EDGE RST
`else
 `define BSV_ARESET_EDGE_META
`endif

`ifdef BSV_RESET_FIFO_HEAD
 `define BSV_ARESET_EDGE_HEAD `BSV_ARESET_EDGE_META
`else
 `define BSV_ARESET_EDGE_HEAD
`endif

`ifdef BSV_RESET_FIFO_ARRAY
 `define BSV_ARESET_EDGE_ARRAY `BSV_ARESET_EDGE_META
`else
 `define BSV_ARESET_EDGE_ARRAY
`endif


// Sized fifo.  Model has output register which improves timing
module SizedFIFO(CLK, RST, D_IN, ENQ, FULL_N, D_OUT, DEQ, EMPTY_N, CLR);
// synopsys sync_set_reset "RST"
   parameter               p1width = 1; // data width
   parameter               p2depth = 3;
   parameter               p3cntr_width = 1; // log(p2depth-1)
   // The -1 is allowed since this model has a fast output register
   parameter               guarded = 1;
   localparam              p2depth2 = (p2depth >= 2) ? (p2depth -2) : 0 ;

   input                   CLK;
   input                   RST;
   input                   CLR;
   input [p1width - 1 : 0] D_IN;
   input                   ENQ;
   input                   DEQ;

   output                  FULL_N;
   output                  EMPTY_N;
   output [p1width - 1 : 0] D_OUT;

   reg                      not_ring_full;
   reg                      ring_empty;

   reg [p3cntr_width-1 : 0] head;
   wire [p3cntr_width-1 : 0] next_head;

   reg [p3cntr_width-1 : 0]  tail;
   wire [p3cntr_width-1 : 0] next_tail;

   // if the depth is too small, don't create an ill-sized array;
   // instead, make a 1-sized array and let the initial block report an error
   reg [p1width - 1 : 0]     arr[0: p2depth2];

   reg [p1width - 1 : 0]     D_OUT;
   reg                       hasodata;

   wire [p3cntr_width-1:0]   depthLess2 = p2depth2[p3cntr_width-1:0] ;

   wire [p3cntr_width-1 : 0] incr_tail;
   wire [p3cntr_width-1 : 0] incr_head;

   assign                    incr_tail = tail + 1'b1 ;
   assign                    incr_head = head + 1'b1 ;

   assign    next_head = (head == depthLess2 ) ? {p3cntr_width{1'b0}} : incr_head ;
   assign    next_tail = (tail == depthLess2 ) ? {p3cntr_width{1'b0}} : incr_tail ;

   assign    EMPTY_N = hasodata;
   assign    FULL_N  = not_ring_full;

`ifdef BSV_NO_INITIAL_BLOCKS
`else // not BSV_NO_INITIAL_BLOCKS
   // synopsys translate_off
   initial
     begin : initial_block
        integer   i;
        D_OUT         = {((p1width + 1)/2){2'b10}} ;

        ring_empty    = 1'b1;
        not_ring_full = 1'b1;
        hasodata      = 1'b0;
        head          = {p3cntr_width {1'b0}} ;
        tail          = {p3cntr_width {1'b0}} ;

        for (i = 0; i <= p2depth2; i = i + 1)
          begin
             arr[i]   = D_OUT ;
          end
     end
   // synopsys translate_on
`endif // BSV_NO_INITIAL_BLOCKS


   always @(posedge CLK `BSV_ARESET_EDGE_META)
     begin
        if (RST == `BSV_RESET_VALUE)
          begin
             head <= `BSV_ASSIGNMENT_DELAY {p3cntr_width {1'b0}} ;
             tail <= `BSV_ASSIGNMENT_DELAY {p3cntr_width {1'b0}} ;
             ring_empty <= `BSV_ASSIGNMENT_DELAY 1'b1;
             not_ring_full <= `BSV_ASSIGNMENT_DELAY 1'b1;
             hasodata <= `BSV_ASSIGNMENT_DELAY 1'b0;
          end // if (RST == `BSV_RESET_VALUE)
        else
         begin

             casez ({CLR, DEQ, ENQ, hasodata, ring_empty})
               // Clear operation
               5'b1????: begin
                  head          <= `BSV_ASSIGNMENT_DELAY {p3cntr_width {1'b0}} ;
                  tail          <= `BSV_ASSIGNMENT_DELAY {p3cntr_width {1'b0}} ;
                  ring_empty    <= `BSV_ASSIGNMENT_DELAY 1'b1;
                  not_ring_full <= `BSV_ASSIGNMENT_DELAY 1'b1;
                  hasodata      <= `BSV_ASSIGNMENT_DELAY 1'b0;
               end
               // -----------------------
               // DEQ && ENQ case -- change head and tail if added to ring
               5'b011?0: begin
                  tail          <= `BSV_ASSIGNMENT_DELAY next_tail;
                  head          <= `BSV_ASSIGNMENT_DELAY next_head;
               end
               // -----------------------
               // DEQ only and NO data is in ring
               5'b010?1: begin
                  hasodata <= `BSV_ASSIGNMENT_DELAY 1'b0;
               end
               // DEQ only and data is in ring (move the head pointer)
               5'b010?0: begin
                  head          <= `BSV_ASSIGNMENT_DELAY next_head;
                  not_ring_full <= `BSV_ASSIGNMENT_DELAY 1'b1;
                  ring_empty    <= `BSV_ASSIGNMENT_DELAY next_head == tail ;
               end
               // -----------------------
               // ENQ only when empty
               5'b0010?: begin
                  hasodata      <= `BSV_ASSIGNMENT_DELAY 1'b1;
                  end
               // ENQ only when not empty
               5'b0011?: begin
                  if ( not_ring_full ) // Drop this test to save redundant test
                    // but be warnned that with test fifo overflow causes loss of new data
                    // while without test fifo drops all but head entry! (pointer overflow)
                   begin
                      tail          <= `BSV_ASSIGNMENT_DELAY next_tail;
                      ring_empty    <= `BSV_ASSIGNMENT_DELAY 1'b0;
                      not_ring_full <= `BSV_ASSIGNMENT_DELAY ! (next_tail == head) ;
                   end
               end
             endcase
         end // else: !if(RST == `BSV_RESET_VALUE)
     end // always @ (posedge CLK)

   // Update the fast data out register
   always @(posedge CLK `BSV_ARESET_EDGE_HEAD)
     begin
`ifdef  BSV_RESET_FIFO_HEAD
        if (RST == `BSV_RESET_VALUE)
          begin
             D_OUT    <= `BSV_ASSIGNMENT_DELAY {p1width {1'b0}} ;
          end // if (RST == `BSV_RESET_VALUE)
        else
`endif
        begin
             casez ({CLR, DEQ, ENQ, hasodata, ring_empty})
               // DEQ && ENQ cases
               5'b011?0: begin D_OUT <= `BSV_ASSIGNMENT_DELAY arr[head]; end
               5'b011?1: begin D_OUT <= `BSV_ASSIGNMENT_DELAY D_IN; end
               // DEQ only and data is in ring
               5'b010?0: begin D_OUT <= `BSV_ASSIGNMENT_DELAY arr[head]; end
               // ENQ only when empty
               5'b0010?: begin D_OUT <= `BSV_ASSIGNMENT_DELAY D_IN; end
             endcase
          end // else: !if(RST == `BSV_RESET_VALUE)
     end // always @ (posedge CLK)

   // Update the memory array  reset is OFF
   always @(posedge CLK `BSV_ARESET_EDGE_ARRAY)
     begin: array
`ifdef BSV_RESET_FIFO_ARRAY
        if (RST == `BSV_RESET_VALUE)
          begin: rst_array
             integer i;
             for (i = 0; i <= p2depth2 && p2depth > 2; i = i + 1)
               begin
                   arr[i]  <= `BSV_ASSIGNMENT_DELAY {p1width {1'b0}} ;
               end
          end // if (RST == `BSV_RESET_VALUE)
        else
`endif
         begin
            if (!CLR && ENQ && ((DEQ && !ring_empty) || (!DEQ && hasodata && not_ring_full)))
              begin
                 arr[tail] <= `BSV_ASSIGNMENT_DELAY D_IN;
              end
         end // else: !if(RST == `BSV_RESET_VALUE)
     end // always @ (posedge CLK)

   // synopsys translate_off
   always@(posedge CLK)
     begin: error_checks
        reg deqerror, enqerror ;

        deqerror =  0;
        enqerror = 0;
        if (RST == ! `BSV_RESET_VALUE)
           begin
              if ( ! EMPTY_N && DEQ )
                begin
                   deqerror = 1 ;
                   $display( "Warning: SizedFIFO: %m -- Dequeuing from empty fifo" ) ;
                end
              if ( ! FULL_N && ENQ && (!DEQ || guarded) )
                begin
                   enqerror =  1 ;
                   $display( "Warning: SizedFIFO: %m -- Enqueuing to a full fifo" ) ;
                end
           end
     end // block: error_checks
   // synopsys translate_on

   // synopsys translate_off
   // Some assertions about parameter values
   initial
     begin : parameter_assertions
        integer ok ;
        ok = 1 ;

        if ( p2depth <= 1)
          begin
             ok = 0;
             $display ( "Warning SizedFIFO: %m -- depth parameter increased from %0d to 2", p2depth);
          end

        if ( p3cntr_width <= 0 )
          begin
             ok = 0;
             $display ( "ERROR SizedFIFO: %m -- width parameter must be greater than 0" ) ;
          end

        if ( ok == 0 ) $finish ;

      end // initial begin
   // synopsys translate_on

endmodule
`define BSV_ASSIGNMENT_DELAY #0

module fifo #(
  parameter DATA_WIDTH = 16,
  parameter FIFO_DEPTH = 3
)(
  input                       clk_i,
  input                       rst_n_i,

  input                       enq_i,
  input                       deq_i,

  input  [DATA_WIDTH - 1 : 0] din_i,
  output [DATA_WIDTH - 1 : 0] dout_o,

  output                      full_o_n,
  output                      empty_o_n
);

  SizedFIFO #(
    .p1width(DATA_WIDTH),
    .p2depth(FIFO_DEPTH + 1),           // +1 due to SizedFIFO implementation
    .p3cntr_width($clog2(FIFO_DEPTH))   // defined in SizedFIFO comments
  ) fifo_inst (
    .CLK(clk_i),
    .RST(rst_n_i),                      // active low, can toggle in SizedFIFO
    .D_IN(din_i),
    .ENQ(enq_i),
    .FULL_N(full_o_n),
    .D_OUT(dout_o),
    .DEQ(deq_i),
    .EMPTY_N(empty_o_n),
    .CLR(1'b0)
  );

endmodule
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
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, dffram);
        #1;
    end
    `endif
    // ========================================================================

endmodule
////////////////////////////////////////////////////////////////////////////////
//
// Filename:	fft-core/bimpy.v
// {{{
// Project:	A General Purpose Pipelined FFT Implementation
//
// Purpose:	A simple 2-bit multiply based upon the fact that LUT's allow
//		6-bits of input.  In other words, I could build a 3-bit
//	multiply from 6 LUTs (5 actually, since the first could have two
//	outputs).  This would allow multiplication of three bit digits, save
//	only for the fact that you would need two bits of carry.  The bimpy
//	approach throttles back a bit and does a 2x2 bit multiply in a LUT,
//	guaranteeing that it will never carry more than one bit.  While this
//	multiply is hardware independent (and can still run under Verilator
//	therefore), it is really motivated by trying to optimize for a
//	specific piece of hardware (Xilinx-7 series ...) that has at least
//	4-input LUT's with carry chains.
//
//
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
module	bimpy #(
		// {{{
		parameter	BW=18 // Number of bits in i_b
		// }}}
	) (
		// {{{
		input	wire			i_clk, i_reset, i_ce,
		input	wire	[(LUTB-1):0]	i_a,
		input	wire	[(BW-1):0]	i_b,
		output	reg	[(BW+LUTB-1):0]	o_r
		// }}}
	);
		localparam	LUTB=2; // Number of bits in i_a for our LUT multiply

	// Local declarations
	// {{{
	wire	[(BW+LUTB-2):0]	w_r;
	wire	[(BW+LUTB-3):1]	c;
	// }}}

	assign	w_r =  { ((i_a[1])?i_b:{(BW){1'b0}}), 1'b0 }
				^ { 1'b0, ((i_a[0])?i_b:{(BW){1'b0}}) };
	assign	c = { ((i_a[1])?i_b[(BW-2):0]:{(BW-1){1'b0}}) }
			& ((i_a[0])?i_b[(BW-1):1]:{(BW-1){1'b0}});

	// o_r
	// {{{
	initial o_r = 0;
	always @(posedge i_clk)
	if (i_reset)
		o_r <= 0;
	else if (i_ce)
		o_r <= w_r + { c, 2'b0 };
	// }}}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// Formal property section
// {{{
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
`ifdef	FORMAL
	reg	f_past_valid;

	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
	f_past_valid <= 1'b1;

`define	ASSERT	assert

	always @(posedge i_clk)
	if ((!f_past_valid)||($past(i_reset)))
	begin
		`ASSERT(o_r == 0);
	end else if ($past(i_ce))
	begin
		if ($past(i_a)==0)
		begin
			`ASSERT(o_r == 0);
		end else if ($past(i_a) == 1)
			`ASSERT(o_r == $past(i_b));

		if ($past(i_b)==0)
		begin
			`ASSERT(o_r == 0);
		end else if ($past(i_b) == 1)
			`ASSERT(o_r[(LUTB-1):0] == $past(i_a));
	end
`endif
// }}}
endmodule
////////////////////////////////////////////////////////////////////////////////
//
// Filename:	bitreverse.v
// {{{
// Project:	A General Purpose Pipelined FFT Implementation
//
// Purpose:	This module bitreverses a pipelined FFT input.  It differes
//		from the dblreverse module in that this is just a simple and
//	straightforward bitreverse, rather than one written to handle two
//	words at once.
//
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
module	bitreverse #(
		// {{{
		parameter			LGSIZE=5, WIDTH=24
		// }}}
	) (
		// {{{
		input	wire			i_clk, i_reset, i_ce,
		input	wire	[(2*WIDTH-1):0]	i_in,
		output	reg	[(2*WIDTH-1):0]	o_out,
		output	reg			o_sync
		// }}}
	);

	// Local declarations
	// {{{
	reg	[(LGSIZE):0]	wraddr;
	wire	[(LGSIZE):0]	rdaddr;

	reg	[(2*WIDTH-1):0]	brmem	[0:((1<<(LGSIZE+1))-1)];

	reg	in_reset;
	// }}}

	// bitreverse rdaddr
	// {{{
	genvar	k;
	generate for(k=0; k<LGSIZE; k=k+1)
	begin : DBL
		assign rdaddr[k] = wraddr[LGSIZE-1-k];
	end endgenerate
	assign	rdaddr[LGSIZE] = !wraddr[LGSIZE];
	// }}}

	// in_reset
	// {{{
	initial	in_reset = 1'b1;
	always @(posedge i_clk)
	if (i_reset)
		in_reset <= 1'b1;
	else if ((i_ce)&&(&wraddr[(LGSIZE-1):0]))
		in_reset <= 1'b0;
	// }}}

	// wraddr
	// {{{
	initial	wraddr = 0;
	always @(posedge i_clk)
	if (i_reset)
		wraddr <= 0;
	else if (i_ce)
	begin
		brmem[wraddr] <= i_in;
		wraddr <= wraddr + 1;
	end
	// }}}

	// o_out
	// {{{
	always @(posedge i_clk)
	if (i_ce) // If (i_reset) we just output junk ... not a problem
		o_out <= brmem[rdaddr]; // w/o a sync pulse
	// }}}

	// o_sync
	// {{{
	initial o_sync = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
		o_sync <= 1'b0;
	else if ((i_ce)&&(!in_reset))
		o_sync <= (wraddr[(LGSIZE-1):0] == 0);
	// }}}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// Formal property section
// {{{
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

`ifdef	FORMAL
`define	ASSERT	assert
`ifdef	BITREVERSE
`define	ASSUME	assume
`else
`define	ASSUME	assert
`endif

	reg	f_past_valid;
	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

	initial	`ASSUME(i_reset);
	always @(posedge i_clk)
	if ((!f_past_valid)||($past(i_reset)))
	begin
		`ASSERT(wraddr == 0);
		`ASSERT(in_reset);
		`ASSERT(!o_sync);
	end
`ifdef	BITREVERSE
	always @(posedge i_clk)
		assume((i_ce)||($past(i_ce))||($past(i_ce,2)));
`endif // BITREVERSE

	// Verilator lint_off UNDRIVEN
	(* anyconst *) reg	[LGSIZE:0]	f_const_addr;
	// Verilator lint_on  UNDRIVEN
	wire	[LGSIZE:0]	f_reversed_addr;
	reg			f_addr_loaded;
	reg	[(2*WIDTH-1):0]	f_addr_value;

	// f_reversed_addr
	// {{{
	generate for(k=0; k<LGSIZE; k=k+1)
		assign	f_reversed_addr[k] = f_const_addr[LGSIZE-1-k];
	endgenerate
	assign	f_reversed_addr[LGSIZE] = f_const_addr[LGSIZE];
	// }}}

	// f_addr_loaded
	// {{{
	initial	f_addr_loaded = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
		f_addr_loaded <= 1'b0;
	else if (i_ce)
	begin
		if (wraddr == f_const_addr)
			f_addr_loaded <= 1'b1;
		else if (rdaddr == f_const_addr)
			f_addr_loaded <= 1'b0;
	end
	// }}}

	// f_addr_value
	// {{{
	always @(posedge i_clk)
	if ((i_ce)&&(wraddr == f_const_addr))
	begin
		f_addr_value <= i_in;
		`ASSERT(!f_addr_loaded);
	end
	// }}}

	always @(posedge i_clk)
	if ((f_past_valid)&&(!$past(i_reset))
			&&($past(f_addr_loaded))&&(!f_addr_loaded))
		assert(o_out == f_addr_value);

	always @(*)
	if (o_sync)
		assert(wraddr[LGSIZE-1:0] == 1);

	always @(*)
	if ((wraddr[LGSIZE]==f_const_addr[LGSIZE])
			&&(wraddr[LGSIZE-1:0]
					<= f_const_addr[LGSIZE-1:0]))
		`ASSERT(!f_addr_loaded);

	always @(*)
	if ((rdaddr[LGSIZE]==f_const_addr[LGSIZE])&&(f_addr_loaded))
		`ASSERT(wraddr[LGSIZE-1:0]
				<= f_reversed_addr[LGSIZE-1:0]+1);

	always @(*)
	if (f_addr_loaded)
		`ASSERT(brmem[f_const_addr] == f_addr_value);


	// Make Verilator happy
	// {{{
	// Verilator lint_off UNUSED
	wire	unused_formal;
	assign	unused_formal = &{ 1'b0, f_reversed_addr[LGSIZE] };
	// Verilator lint_on  UNUSED
	// }}}
`endif	// FORMAL
// }}}
endmodule
////////////////////////////////////////////////////////////////////////////////
//
// Filename:	butterfly.v
// {{{
// Project:	A General Purpose Pipelined FFT Implementation
//
// Purpose:	This routine caculates a butterfly for a decimation
//		in frequency version of an FFT.  Specifically, given
//	complex Left and Right values together with a coefficient, the output
//	of this routine is given by:
//
//		L' = L + R
//		R' = (L - R)*C
//
//	The rest of the junk below handles timing (mostly), to make certain
//	that L' and R' reach the output at the same clock.  Further, just to
//	make certain that is the case, an 'aux' input exists.  This aux value
//	will come out of this routine synchronized to the values it came in
//	with.  (i.e., both L', R', and aux all have the same delay.)  Hence,
//	a caller of this routine may set aux on the first input with valid
//	data, and then wait to see aux set on the output to know when to find
//	the first output with valid data.
//
//	All bits are preserved until the very last clock, where any more bits
//	than OWIDTH will be quietly discarded.
//
//	This design features no overflow checking.
//
// Notes:
//	CORDIC:
//		Much as we might like, we can't use a cordic here.
//		The goal is to accomplish an FFT, as defined, and a
//		CORDIC places a scale factor onto the data.  Removing
//		the scale factor would cost two multiplies, which
//		is precisely what we are trying to avoid.
//
//
//	3-MULTIPLIES:
//		It should also be possible to do this with three multiplies
//		and an extra two addition cycles.
//
//		We want
//			R+I = (a + jb) * (c + jd)
//			R+I = (ac-bd) + j(ad+bc)
//		We multiply
//			P1 = ac
//			P2 = bd
//			P3 = (a+b)(c+d)
//		Then
//			R+I=(P1-P2)+j(P3-P2-P1)
//
//		WIDTHS:
//		On multiplying an X width number by an
//		Y width number, X>Y, the result should be (X+Y)
//		bits, right?
//		-2^(X-1) <= a <= 2^(X-1) - 1
//		-2^(Y-1) <= b <= 2^(Y-1) - 1
//		(2^(Y-1)-1)*(-2^(X-1)) <= ab <= 2^(X-1)2^(Y-1)
//		-2^(X+Y-2)+2^(X-1) <= ab <= 2^(X+Y-2) <= 2^(X+Y-1) - 1
//		-2^(X+Y-1) <= ab <= 2^(X+Y-1)-1
//		YUP!  But just barely.  Do this and you'll really want
//		to drop a bit, although you will risk overflow in so
//		doing.
//
//	20150602 -- The sync logic lines have been completely redone.  The
//		synchronization lines no longer go through the FIFO with the
//		left hand sum, but are kept out of memory.  This allows the
//		butterfly to use more optimal memory resources, while also
//		guaranteeing that the sync lines can be properly reset upon
//		any reset signal.
//
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
module	butterfly #(
		// {{{
		// Public changeable parameters ...
		// IWIDTH
		// {{{
		// This is the input data width
		parameter IWIDTH=16,
		// }}}
		// CWIDTH
		// {{{
		// This is the width of the twiddle factor, the 'coefficient'
		// if you will.
		CWIDTH=20,		// }}}
		// OWIDTH
		// {{{
		// This is the width of the final output
		OWIDTH=17,
		// }}}
		// SHIFT
		// {{{
		// The shift controls whether or not the result will be
		// left shifted by SHIFT bits, throwing the overflow
		// away.
		parameter	SHIFT=0,
		// }}}
		// CKPCE
		// {{{
		// CKPCE is the number of clocks per each i_ce.  The actual
		// number can be more, but the algorithm depends upon at least
		// this many for extra internal processing.
		parameter	CKPCE=1
		// }}}
		//
	) (
		// {{{
		input	wire	i_clk, i_reset, i_ce,
		input	wire	[(2*CWIDTH-1):0] i_coef,
		input	wire	[(2*IWIDTH-1):0] i_left, i_right,
		input	wire	i_aux,
		output	wire	[(2*OWIDTH-1):0] o_left, o_right,
		output	reg	o_aux
		// }}}
	);
		// Local/derived parameters
		// {{{
		// These are calculated from the above params.  Apart from
		// algorithmic changes below, these should not be adjusted
		//
		// MXMPYBITS
		// {{{
		// The first step is to calculate how many clocks it takes
		// our multiply to come back with an answer within.  The
		// time in the multiply depends upon the input value with
		// the fewest number of bits--to keep the pipeline depth
		// short.  So, let's find the fewest number of bits here.
		localparam MXMPYBITS =
		((IWIDTH+2)>(CWIDTH+1)) ? (CWIDTH+1) : (IWIDTH + 2);
		// }}}
		// MPYDELAY
		// {{{
		// Given this "fewest" number of bits, we can calculate
		// the number of clocks the multiply itself will take.
		localparam	MPYDELAY=((MXMPYBITS+1)/2)+2;
		// }}}
		// LCLDELAY
		// {{{
		//
		// In an environment when CKPCE > 1, the multiply delay isn't
		// necessarily the delay felt by this algorithm--measured in
		// i_ce's.  In particular, if the multiply can operate with more
		// operations per clock, it can appear to finish "faster".
		// Since most of the logic in this core operates on the
		// slower clock, we'll need to map that speed into the
		// number of slower clock ticks that it takes.
		localparam	LCLDELAY = (CKPCE == 1) ? MPYDELAY
			: (CKPCE == 2) ? (MPYDELAY/2+2)
			: (MPYDELAY/3 + 2);
		// }}}
		// LGDELAY
		// {{{
		localparam	LGDELAY = (MPYDELAY>64) ? 7
			: (MPYDELAY > 32) ? 6
			: (MPYDELAY > 16) ? 5
			: (MPYDELAY >  8) ? 4
			: (MPYDELAY >  4) ? 3
			: 2;
		// }}}
		localparam	AUXLEN=(LCLDELAY+3);
		localparam	MPYREMAINDER = MPYDELAY - CKPCE*(MPYDELAY/CKPCE);
		// }}}
		// }}}

	// Local delcarations
	// {{{
`ifdef	FORMAL
	// {{{
	localparam	F_LGDEPTH = (AUXLEN > 64) ? 7
			: (AUXLEN > 32) ? 6
			: (AUXLEN > 16) ? 5
			: (AUXLEN >  8) ? 4
			: (AUXLEN >  4) ? 3 : 2;

	localparam	F_DEPTH = AUXLEN;
	localparam	[F_LGDEPTH-1:0]	F_D = F_DEPTH[F_LGDEPTH-1:0]-1;

	reg	signed	[IWIDTH-1:0]	f_dlyleft_r  [0:F_DEPTH-1];
	reg	signed	[IWIDTH-1:0]	f_dlyleft_i  [0:F_DEPTH-1];
	reg	signed	[IWIDTH-1:0]	f_dlyright_r [0:F_DEPTH-1];
	reg	signed	[IWIDTH-1:0]	f_dlyright_i [0:F_DEPTH-1];
	reg	signed	[CWIDTH-1:0]	f_dlycoeff_r [0:F_DEPTH-1];
	reg	signed	[CWIDTH-1:0]	f_dlycoeff_i [0:F_DEPTH-1];
	reg	signed	[F_DEPTH-1:0]	f_dlyaux;

	reg	signed	[IWIDTH:0]		f_predifr, f_predifi;
	wire	signed	[IWIDTH+CWIDTH+3-1:0]	f_predifrx, f_predifix;
	reg	signed	[CWIDTH:0]		f_sumcoef;
	reg	signed	[IWIDTH+1:0]		f_sumdiff;
	reg	signed	[IWIDTH:0]		f_sumr, f_sumi;
	wire	signed	[IWIDTH+CWIDTH+3-1:0]	f_sumrx, f_sumix;
	reg	signed	[IWIDTH:0]		f_difr, f_difi;
	wire	signed	[IWIDTH+CWIDTH+3-1:0]	f_difrx, f_difix;
	wire	signed	[IWIDTH+CWIDTH+3-1:0]	f_widecoeff_r, f_widecoeff_i;

	wire	[(CWIDTH):0]	fp_one_ic, fp_two_ic, fp_three_ic, f_p3c_in;
	wire	[(IWIDTH+1):0]	fp_one_id, fp_two_id, fp_three_id, f_p3d_in;
	// }}}
`endif

	reg	[(2*IWIDTH-1):0]	r_left, r_right;
	reg	[(2*CWIDTH-1):0]	r_coef, r_coef_2;
	wire	signed	[(IWIDTH-1):0]	r_left_r, r_left_i, r_right_r, r_right_i;
	reg	signed	[(IWIDTH):0]	r_sum_r, r_sum_i, r_dif_r, r_dif_i;

	reg	[(LGDELAY-1):0]	fifo_addr;
	wire	[(LGDELAY-1):0]	fifo_read_addr;
	reg	[(2*IWIDTH+1):0]	fifo_left [ 0:((1<<LGDELAY)-1)];
	wire	signed	[(CWIDTH-1):0]	ir_coef_r, ir_coef_i;
	wire	signed	[((IWIDTH+2)+(CWIDTH+1)-1):0]	p_one, p_two, p_three;
	wire	signed	[(IWIDTH+CWIDTH):0]	fifo_i, fifo_r;

	reg		[(2*IWIDTH+1):0]	fifo_read;

	reg	signed	[(CWIDTH+IWIDTH+3-1):0]	mpy_r, mpy_i;

	wire	signed	[(OWIDTH-1):0]	rnd_left_r, rnd_left_i, rnd_right_r, rnd_right_i;

	wire	signed	[(CWIDTH+IWIDTH+3-1):0]	left_sr, left_si;
	reg	[(AUXLEN-1):0]	aux_pipeline;
	// }}}

	// Break complex registers into their real and imaginary components
	// {{{
	assign	r_left_r  = r_left[ (2*IWIDTH-1):(IWIDTH)];
	assign	r_left_i  = r_left[ (IWIDTH-1):0];
	assign	r_right_r = r_right[(2*IWIDTH-1):(IWIDTH)];
	assign	r_right_i = r_right[(IWIDTH-1):0];

	assign	ir_coef_r = r_coef_2[(2*CWIDTH-1):CWIDTH];
	assign	ir_coef_i = r_coef_2[(CWIDTH-1):0];
	// }}}

	assign	fifo_read_addr = fifo_addr - LCLDELAY[(LGDELAY-1):0];

	// r_left, r_right, r_coef, r_sum_[r|i], r_dif_[r|i], r_coef_2
	// {{{
	// Set up the input to the multiply
	always @(posedge i_clk)
	if (i_ce)
	begin
		// One clock just latches the inputs
		r_left <= i_left;	// No change in # of bits
		r_right <= i_right;
		r_coef  <= i_coef;
		// Next clock adds/subtracts
		r_sum_r <= r_left_r + r_right_r; // Now IWIDTH+1 bits
		r_sum_i <= r_left_i + r_right_i;
		r_dif_r <= r_left_r - r_right_r;
		r_dif_i <= r_left_i - r_right_i;
		// Other inputs are simply delayed on second clock
		r_coef_2<= r_coef;
	end
	// }}}

	// fifo_addr
	// {{{
	// Don't forget to record the even side, since it doesn't need
	// to be multiplied, but yet we still need the results in sync
	// with the answer when it is ready.
	initial fifo_addr = 0;
	always @(posedge i_clk)
	if (i_reset)
		fifo_addr <= 0;
	else if (i_ce)
		// Need to delay the sum side--nothing else happens
		// to it, but it needs to stay synchronized with the
		// right side.
		fifo_addr <= fifo_addr + 1;
	// }}}

	// Write into the left-side input FIFO
	// {{{
	always @(posedge i_clk)
	if (i_ce)
		fifo_left[fifo_addr] <= { r_sum_r, r_sum_i };
	// }}}

	// Notes
	// {{{
	// Multiply output is always a width of the sum of the widths of
	// the two inputs.  ALWAYS.  This is independent of the number of
	// bits in p_one, p_two, or p_three.  These values needed to
	// accumulate a bit (or two) each.  However, this approach to a
	// three multiply complex multiply cannot increase the total
	// number of bits in our final output.  We'll take care of
	// dropping back down to the proper width, OWIDTH, in our routine
	// below.

	// We accomplish here "Karatsuba" multiplication.  That is,
	// by doing three multiplies we accomplish the work of four.
	// Let's prove to ourselves that this works ... We wish to
	// multiply: (a+jb) * (c+jd), where a+jb is given by
	//	a + jb = r_dif_r + j r_dif_i, and
	//	c + jd = ir_coef_r + j ir_coef_i.
	// We do this by calculating the intermediate products P1, P2,
	// and P3 as
	//	P1 = ac
	//	P2 = bd
	//	P3 = (a + b) * (c + d)
	// and then complete our final answer with
	//	ac - bd = P1 - P2 (this checks)
	//	ad + bc = P3 - P2 - P1
	//	        = (ac + bc + ad + bd) - bd - ac
	//	        = bc + ad (this checks)
	// }}}

	// Instantiate the multiplies
	// {{{
	generate if (CKPCE <= 1)
	begin
		// {{{
		// Local declarations
		// {{{
		wire	[(CWIDTH):0]	p3c_in;
		wire	[(IWIDTH+1):0]	p3d_in;
		// }}}

		assign	p3c_in = ir_coef_i + ir_coef_r;
		assign	p3d_in = r_dif_r + r_dif_i;

		// p_one = ir_coef_r * r_dif_r
		// {{{
		// We need to pad these first two multiplies by an extra
		// bit just to keep them aligned with the third,
		// simpler, multiply.
		longbimpy #(CWIDTH+1,IWIDTH+2)
		p1(i_clk, i_ce,
				{ir_coef_r[CWIDTH-1],ir_coef_r},
				{r_dif_r[IWIDTH],r_dif_r}, p_one
`ifdef	FORMAL
				, fp_one_ic, fp_one_id
`endif
			);
		// }}}

		// p_two = ir_coef_i * r_dif_i
		// {{{
		longbimpy #(CWIDTH+1,IWIDTH+2)
		p2(i_clk, i_ce,
				{ir_coef_i[CWIDTH-1],ir_coef_i},
				{r_dif_i[IWIDTH],r_dif_i}, p_two
`ifdef	FORMAL
				, fp_two_ic, fp_two_id
`endif
			);
		// }}}

		// p_three = (ir_coef_i + ir_coef_r) * (r_dif_r + r_dif_i)
		// {{{
		longbimpy #(CWIDTH+1,IWIDTH+2)
		p3(i_clk, i_ce,
				p3c_in, p3d_in, p_three
`ifdef	FORMAL
				, fp_three_ic, fp_three_id
`endif
			);
		// }}}

		// }}}
	end else if (CKPCE == 2)
	begin : CKPCE_TWO
		// {{{
		// Local declarations
		// {{{
		// Coefficient multiply inputs
		reg		[2*(CWIDTH)-1:0]	mpy_pipe_c;
		// Data multiply inputs
		reg		[2*(IWIDTH+1)-1:0]	mpy_pipe_d;
		wire	signed	[(CWIDTH-1):0]	mpy_pipe_vc;
		wire	signed	[(IWIDTH):0]	mpy_pipe_vd;
		//
		reg	signed	[(CWIDTH+1)-1:0]	mpy_cof_sum;
		reg	signed	[(IWIDTH+2)-1:0]	mpy_dif_sum;

		reg			mpy_pipe_v;
		reg			ce_phase;

		reg	signed	[(CWIDTH+IWIDTH+3)-1:0]	mpy_pipe_out;
		reg	signed [IWIDTH+CWIDTH+3-1:0]	longmpy;
		reg	signed	[((IWIDTH+2)+(CWIDTH+1)-1):0]
					rp_one, rp_two, rp_three,
					rp2_one, rp2_two, rp2_three;

`ifdef	FORMAL
		// {{{
		wire	[CWIDTH:0]	f_past_ic;
		wire	[IWIDTH+1:0]	f_past_id;
		wire	[CWIDTH:0]	f_past_mux_ic;
		wire	[IWIDTH+1:0]	f_past_mux_id;

		reg	[CWIDTH:0]	f_rpone_ic, f_rptwo_ic, f_rpthree_ic,
					f_rp2one_ic, f_rp2two_ic, f_rp2three_ic;
		reg	[IWIDTH+1:0]	f_rpone_id, f_rptwo_id, f_rpthree_id,
					f_rp2one_id, f_rp2two_id, f_rp2three_id;
		// }}}
`endif
		// }}}

		assign	mpy_pipe_vc =  mpy_pipe_c[2*(CWIDTH)-1:CWIDTH];
		assign	mpy_pipe_vd =  mpy_pipe_d[2*(IWIDTH+1)-1:IWIDTH+1];

		// ce_phase
		// {{{
		initial	ce_phase = 1'b0;
		always @(posedge i_clk)
		if (i_reset)
			ce_phase <= 1'b0;
		else if (i_ce)
			ce_phase <= 1'b1;
		else
			ce_phase <= 1'b0;
		// }}}

		// mpy_pipe_v
		// {{{
		always @(*)
			mpy_pipe_v = (i_ce)||(ce_phase);
		// }}}

		// mpy_pipe_c, mpy_pipe_d
		// {{{
		always @(posedge i_clk)
		if (ce_phase)
		begin
			mpy_pipe_c[2*CWIDTH-1:0] <=
					{ ir_coef_r, ir_coef_i };
			mpy_pipe_d[2*(IWIDTH+1)-1:0] <=
					{ r_dif_r, r_dif_i };

			mpy_cof_sum  <= ir_coef_i + ir_coef_r;
			mpy_dif_sum <= r_dif_r + r_dif_i;

		end else if (i_ce)
		begin
			mpy_pipe_c[2*(CWIDTH)-1:0] <= {
				mpy_pipe_c[(CWIDTH)-1:0], {(CWIDTH){1'b0}} };
			mpy_pipe_d[2*(IWIDTH+1)-1:0] <= {
				mpy_pipe_d[(IWIDTH+1)-1:0], {(IWIDTH+1){1'b0}} };
		end
		// }}}

		// longmpy = mpy_cof_sum * mpy_dif_sum
		// {{{
		longbimpy #(CWIDTH+1,IWIDTH+2)
		mpy0(i_clk, mpy_pipe_v,
				mpy_cof_sum, mpy_dif_sum, longmpy
`ifdef	FORMAL
				, f_past_ic, f_past_id
`endif
			);
		// }}}

		// mpy_pipe_out = mpy_pipe_vc * mpy_pipe_vd
		// {{{
		// This is the shared multiply, but still multiplying
		// a coefficient (i.e. twiddle factor) times data
		longbimpy #(CWIDTH+1,IWIDTH+2)
		mpy1(i_clk, mpy_pipe_v,
				{ mpy_pipe_vc[CWIDTH-1], mpy_pipe_vc },
				{ mpy_pipe_vd[IWIDTH  ], mpy_pipe_vd },
				mpy_pipe_out
`ifdef	FORMAL
				, f_past_mux_ic, f_past_mux_id
`endif
			);
		// }}}

		// rp_one (from mpy_pipe_out, first round)
		// {{{
		always @(posedge i_clk)
		if (((i_ce)&&(!MPYDELAY[0]))
			||((ce_phase)&&(MPYDELAY[0])))
		begin
			rp_one <= mpy_pipe_out;
`ifdef	FORMAL
			f_rpone_ic <= f_past_mux_ic;
			f_rpone_id <= f_past_mux_id;
`endif
		end
		// }}}

		// rp_two (from mpy_pipe_out, second round)
		// {{{
		always @(posedge i_clk)
		if (((i_ce)&&(MPYDELAY[0]))
			||((ce_phase)&&(!MPYDELAY[0])))
		begin
			rp_two <= mpy_pipe_out;
`ifdef	FORMAL
			f_rptwo_ic <= f_past_mux_ic;
			f_rptwo_id <= f_past_mux_id;
`endif
		end
		// }}}

		// rp_three (from longmpy)
		// {{{
		always @(posedge i_clk)
		if (i_ce)
		begin
			rp_three <= longmpy;
`ifdef	FORMAL
			f_rpthree_ic <= f_past_ic;
			f_rpthree_id <= f_past_id;
`endif
		end
		// }}}

		// rp2_[one|two|three] -- register the outputs on i_ce
		// {{{
		// Our outputs *MUST* be set on a clock where i_ce is
		// true for the following logic to work.  Make that
		// happens here.
		always @(posedge i_clk)
		if (i_ce)
		begin
			rp2_one<= rp_one;
			rp2_two <= rp_two;
			rp2_three<= rp_three;
`ifdef	FORMAL
			f_rp2one_ic <= f_rpone_ic;
			f_rp2one_id <= f_rpone_id;

			f_rp2two_ic <= f_rptwo_ic;
			f_rp2two_id <= f_rptwo_id;

			f_rp2three_ic <= f_rpthree_ic;
			f_rp2three_id <= f_rpthree_id;
`endif
		end
		// }}}

		// Final multiply output assignments
		// {{{
		assign	p_one	= rp2_one;
		assign	p_two	= (!MPYDELAY[0])? rp2_two  : rp_two;
		assign	p_three	= ( MPYDELAY[0])? rp_three : rp2_three;
		// }}}

		// Make verilator happy
		// {{{
		// verilator lint_off UNUSED
		wire	[2*(IWIDTH+CWIDTH+3)-1:0]	unused;
		assign	unused = { rp2_two, rp2_three };
		// verilator lint_on  UNUSED
		// }}}

`ifdef	FORMAL
		// {{{
		assign fp_one_ic = f_rp2one_ic;
		assign fp_one_id = f_rp2one_id;

		assign fp_two_ic = (!MPYDELAY[0])? f_rp2two_ic : f_rptwo_ic;
		assign fp_two_id = (!MPYDELAY[0])? f_rp2two_id : f_rptwo_id;

		assign fp_three_ic= (MPYDELAY[0])? f_rpthree_ic : f_rp2three_ic;
		assign fp_three_id= (MPYDELAY[0])? f_rpthree_id : f_rp2three_id;
		// }}}
`endif
		// }}}
	end else if (CKPCE <= 3)
	begin : CKPCE_THREE
		// {{{
		// Local declarations
		// {{{
		// Coefficient multiply inputs
		reg		[3*(CWIDTH+1)-1:0]	mpy_pipe_c;
		// Data multiply inputs
		reg		[3*(IWIDTH+2)-1:0]	mpy_pipe_d;
		wire	signed	[(CWIDTH):0]	mpy_pipe_vc;
		wire	signed	[(IWIDTH+1):0]	mpy_pipe_vd;

		reg			mpy_pipe_v;
		reg		[2:0]	ce_phase;

		wire	signed	[  (CWIDTH+IWIDTH+3)-1:0]	mpy_pipe_out;

`ifdef	FORMAL
		// {{{
		wire	[CWIDTH:0]	f_past_ic;
		wire	[IWIDTH+1:0]	f_past_id;

		reg	[CWIDTH:0]	f_rpone_ic, f_rptwo_ic, f_rpthree_ic,
					f_rp2one_ic, f_rp2two_ic, f_rp2three_ic,
					f_rp3one_ic;
		reg	[IWIDTH+1:0]	f_rpone_id, f_rptwo_id, f_rpthree_id,
					f_rp2one_id, f_rp2two_id, f_rp2three_id,
					f_rp3one_id;
		// }}}
`endif
		reg	signed	[((IWIDTH+2)+(CWIDTH+1)-1):0]
				rp_one,  rp_two,  rp_three,
				rp2_one, rp2_two, rp2_three,
				rp3_one;

		// }}}
		assign	mpy_pipe_vc =  mpy_pipe_c[3*(CWIDTH+1)-1:2*(CWIDTH+1)];
		assign	mpy_pipe_vd =  mpy_pipe_d[3*(IWIDTH+2)-1:2*(IWIDTH+2)];

		// ce_phase
		// {{{
		// We're sharing our multiply hardware across three multiplies
		// ce_phase controls which of the multiplies needs to be set up
		// at each time step
		initial	ce_phase = 3'b011;
		always @(posedge i_clk)
		if (i_reset)
			ce_phase <= 3'b011;
		else if (i_ce)
			ce_phase <= 3'b000;
		else if (ce_phase != 3'b011)
			ce_phase <= ce_phase + 1'b1;
		// }}}

		// mpy_pipe_v : does the multiply have valid incoming data?
		// {{{
		always @(*)
			mpy_pipe_v = (i_ce)||(ce_phase < 3'b010);
		// }}}

		// mpy_pipe_c, mpy_pipe_d: coefficient and data inputs to mpy
		// {{{
		always @(posedge i_clk)
		if (ce_phase == 3'b000)
		begin
			// {{{
			// Second clock -- load the inputs like shift registers
			mpy_pipe_c[3*(CWIDTH+1)-1:(CWIDTH+1)] <= {
				ir_coef_r[CWIDTH-1], ir_coef_r,
				ir_coef_i[CWIDTH-1], ir_coef_i };
			mpy_pipe_c[CWIDTH:0] <= ir_coef_i + ir_coef_r;
			mpy_pipe_d[3*(IWIDTH+2)-1:(IWIDTH+2)] <= {
				r_dif_r[IWIDTH], r_dif_r,
				r_dif_i[IWIDTH], r_dif_i };
			mpy_pipe_d[(IWIDTH+2)-1:0] <= r_dif_r + r_dif_i;
			// }}}
		end else if (mpy_pipe_v)
		begin
			// {{{
			// Shift the registers to produce the next values
			mpy_pipe_c[3*(CWIDTH+1)-1:0] <= {
				mpy_pipe_c[2*(CWIDTH+1)-1:0], {(CWIDTH+1){1'b0}} };
			mpy_pipe_d[3*(IWIDTH+2)-1:0] <= {
				mpy_pipe_d[2*(IWIDTH+2)-1:0], {(IWIDTH+2){1'b0}} };
			// }}}
		end
		// }}}

		// mpy_pipe_out = mpy_pipe_vc * mpy_pipe_vd
		// {{{
		longbimpy #(CWIDTH+1,IWIDTH+2)
		mpy(i_clk, mpy_pipe_v,
				mpy_pipe_vc, mpy_pipe_vd, mpy_pipe_out
`ifdef	FORMAL
				, f_past_ic, f_past_id
`endif
			);
		// }}}

		// Register the multiply outputs into their various results
		// {{{
		always @(posedge i_clk)
		if (MPYREMAINDER == 0)
		begin
			// {{{
			if (i_ce)
			begin
				rp_two   <= mpy_pipe_out;
`ifdef	FORMAL
				f_rptwo_ic <= f_past_ic;
				f_rptwo_id <= f_past_id;
`endif
			end else if (ce_phase == 3'b000)
			begin
				rp_three <= mpy_pipe_out;
`ifdef	FORMAL
				f_rpthree_ic <= f_past_ic;
				f_rpthree_id <= f_past_id;
`endif
			end else if (ce_phase == 3'b001)
			begin
				rp_one   <= mpy_pipe_out;
`ifdef	FORMAL
				f_rpone_ic <= f_past_ic;
				f_rpone_id <= f_past_id;
`endif
			end
			// }}}
		end else if (MPYREMAINDER == 1)
		begin
			// {{{
			if (i_ce)
			begin
				rp_one   <= mpy_pipe_out;
`ifdef	FORMAL
				f_rpone_ic <= f_past_ic;
				f_rpone_id <= f_past_id;
`endif
			end else if (ce_phase == 3'b000)
			begin
				rp_two   <= mpy_pipe_out;
`ifdef	FORMAL
				f_rptwo_ic <= f_past_ic;
				f_rptwo_id <= f_past_id;
`endif
			end else if (ce_phase == 3'b001)
			begin
				rp_three <= mpy_pipe_out;
`ifdef	FORMAL
				f_rpthree_ic <= f_past_ic;
				f_rpthree_id <= f_past_id;
`endif
			end
			// }}}
		end else // if (MPYREMAINDER == 2)
		begin
			// {{{
			if (i_ce)
			begin
				rp_three <= mpy_pipe_out;
`ifdef	FORMAL
				f_rpthree_ic <= f_past_ic;
				f_rpthree_id <= f_past_id;
`endif
			end else if (ce_phase == 3'b000)
			begin
				rp_one   <= mpy_pipe_out;
`ifdef	FORMAL
				f_rpone_ic <= f_past_ic;
				f_rpone_id <= f_past_id;
`endif
			end else if (ce_phase == 3'b001)
			begin
				rp_two   <= mpy_pipe_out;
`ifdef	FORMAL
				f_rptwo_ic <= f_past_ic;
				f_rptwo_id <= f_past_id;
`endif
			end
			// }}}
		end
		// }}}

		// rp2_one, rp2_two, rp2_three, rp3_one
		// {{{
		always @(posedge i_clk)
		if (i_ce)
		begin
			rp2_one   <= rp_one;
			rp2_two   <= rp_two;
			rp2_three <= (MPYREMAINDER == 2) ? mpy_pipe_out : rp_three;
			rp3_one   <= (MPYREMAINDER == 0) ? rp2_one : rp_one;
`ifdef	FORMAL
			// {{{
			f_rp2one_ic <= f_rpone_ic;
			f_rp2one_id <= f_rpone_id;

			f_rp2two_ic <= f_rptwo_ic;
			f_rp2two_id <= f_rptwo_id;

			f_rp2three_ic <= (MPYREMAINDER==2) ? f_past_ic : f_rpthree_ic;
			f_rp2three_id <= (MPYREMAINDER==2) ? f_past_id : f_rpthree_id;
			f_rp3one_ic <= (MPYREMAINDER==0) ? f_rp2one_ic : f_rpone_ic;
			f_rp3one_id <= (MPYREMAINDER==0) ? f_rp2one_id : f_rpone_id;
			// }}}
`endif
		end
		// }}}

		// Final output assignments
		// {{{
		assign	p_one   = rp3_one;
		assign	p_two   = rp2_two;
		assign	p_three = rp2_three;

`ifdef	FORMAL
		// {{{
		assign	fp_one_ic = f_rp3one_ic;
		assign	fp_one_id = f_rp3one_id;

		assign	fp_two_ic = f_rp2two_ic;
		assign	fp_two_id = f_rp2two_id;

		assign	fp_three_ic = f_rp2three_ic;
		assign	fp_three_id = f_rp2three_id;
		// }}}
`endif

		// }}}

		// }}}
	end endgenerate
	// }}}

	// fifo_r, fifo_i
	// {{{
	// These values are held in memory and delayed during the
	// multiply.  Here, we recover them.  During the multiply,
	// values were multiplied by 2^(CWIDTH-2)*exp{-j*2*pi*...},
	// therefore, the left_x values need to be right shifted by
	// CWIDTH-2 as well.  The additional bits come from a sign
	// extension.
	assign	fifo_r = { {2{fifo_read[2*(IWIDTH+1)-1]}},
		fifo_read[(2*(IWIDTH+1)-1):(IWIDTH+1)], {(CWIDTH-2){1'b0}} };
	assign	fifo_i = { {2{fifo_read[(IWIDTH+1)-1]}},
		fifo_read[((IWIDTH+1)-1):0], {(CWIDTH-2){1'b0}} };
	// }}}

	// Rounding and shifting
	// {{{
	// Notes
	// {{{
	// Let's do some rounding and remove unnecessary bits.
	// We have (IWIDTH+CWIDTH+3) bits here, we need to drop down to
	// OWIDTH, and SHIFT by SHIFT bits in the process.  The trick is
	// that we don't need (IWIDTH+CWIDTH+3) bits.  We've accumulated
	// them, but the actual values will never fill all these bits.
	// In particular, we only need:
	//	 IWIDTH bits for the input
	//	     +1 bit for the add/subtract
	//	+CWIDTH bits for the coefficient multiply
	//	     +1 bit for the add/subtract in the complex multiply
	//	 ------
	//	 (IWIDTH+CWIDTH+2) bits at full precision.
	//
	// However, the coefficient multiply multiplied by a maximum value
	// of 2^(CWIDTH-2).  Thus, we only have
	//	   IWIDTH bits for the input
	//	       +1 bit for the add/subtract
	//	+CWIDTH-2 bits for the coefficient multiply
	//	       +1 (optional) bit for the add/subtract in the cpx mpy.
	//	 -------- ... multiply.  (This last bit may be shifted out.)
	//	 (IWIDTH+CWIDTH) valid output bits.
	// Now, if the user wants to keep any extras of these (via OWIDTH),
	// or if he wishes to arbitrarily shift some of these off (via
	// SHIFT) we accomplish that here.
	// }}}

	assign	left_sr = { {(2){fifo_r[(IWIDTH+CWIDTH)]}}, fifo_r };
	assign	left_si = { {(2){fifo_i[(IWIDTH+CWIDTH)]}}, fifo_i };

	convround #(CWIDTH+IWIDTH+3,OWIDTH,SHIFT+4)
	do_rnd_left_r(i_clk, i_ce, left_sr, rnd_left_r);

	convround #(CWIDTH+IWIDTH+3,OWIDTH,SHIFT+4)
	do_rnd_left_i(i_clk, i_ce, left_si, rnd_left_i);

	convround #(CWIDTH+IWIDTH+3,OWIDTH,SHIFT+4)
	do_rnd_right_r(i_clk, i_ce, mpy_r, rnd_right_r);

	convround #(CWIDTH+IWIDTH+3,OWIDTH,SHIFT+4)
	do_rnd_right_i(i_clk, i_ce, mpy_i, rnd_right_i);
	// }}}

	// fifo_read, mpy_r, mpy_i
	// {{{
	// Unwrap the three multiplies into the two multiply results
	always @(posedge i_clk)
	if (i_ce)
	begin
		// First clock, recover all values
		fifo_read <= fifo_left[fifo_read_addr];
		// These values are IWIDTH+CWIDTH+3 bits wide
		// although they only need to be (IWIDTH+1)
		// + (CWIDTH) bits wide.  (We've got two
		// extra bits we need to get rid of.)
		mpy_r <= p_one - p_two;
		mpy_i <= p_three - p_one - p_two;
	end
	// }}}

	// aux_pipeline
	// {{{
	initial	aux_pipeline = 0;
	always @(posedge i_clk)
	if (i_reset)
		aux_pipeline <= 0;
	else if (i_ce)
		aux_pipeline <= { aux_pipeline[(AUXLEN-2):0], i_aux };
	// }}}

	// o_aux
	// {{{
	initial o_aux = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
		o_aux <= 1'b0;
	else if (i_ce)
	begin
		// Second clock, latch for final clock
		o_aux <= aux_pipeline[AUXLEN-1];
	end
	// }}}

	// o_left, o_right
	// {{{
	// As a final step, we pack our outputs into two packed two's
	// complement numbers per output word, so that each output word
	// has (2*OWIDTH) bits in it, with the top half being the real
	// portion and the bottom half being the imaginary portion.
	assign	o_left = { rnd_left_r, rnd_left_i };
	assign	o_right= { rnd_right_r,rnd_right_i};
	// }}}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// Formal property section
// {{{
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
`ifdef	FORMAL
	initial	f_dlyaux[0] = 0;
	always @(posedge i_clk)
	if (i_reset)
		f_dlyaux	<= 0;
	else if (i_ce)
		f_dlyaux	<= { f_dlyaux[F_DEPTH-2:0], i_aux };

	// f_dly[left|right|coef]_[i|r][0]
	// {{{
	always @(posedge i_clk)
	if (i_ce)
	begin
		f_dlyleft_r[0]   <= i_left[ (2*IWIDTH-1):IWIDTH];
		f_dlyleft_i[0]   <= i_left[ (  IWIDTH-1):0];
		f_dlyright_r[0]  <= i_right[(2*IWIDTH-1):IWIDTH];
		f_dlyright_i[0]  <= i_right[(  IWIDTH-1):0];
		f_dlycoeff_r[0]  <= i_coef[ (2*CWIDTH-1):CWIDTH];
		f_dlycoeff_i[0]  <= i_coef[ (  CWIDTH-1):0];
	end
	// }}}

	// f_dly[left|right|coef]_[i|r][F_DEPTH-1:1]
	// {{{
	genvar	k;
	generate for(k=1; k<F_DEPTH; k=k+1)
	begin : F_PROPAGATE_DELAY_LINES


		always @(posedge i_clk)
		if (i_ce)
		begin
			f_dlyleft_r[k]  <= f_dlyleft_r[ k-1];
			f_dlyleft_i[k]  <= f_dlyleft_i[ k-1];
			f_dlyright_r[k] <= f_dlyright_r[k-1];
			f_dlyright_i[k] <= f_dlyright_i[k-1];
			f_dlycoeff_r[k] <= f_dlycoeff_r[k-1];
			f_dlycoeff_i[k] <= f_dlycoeff_i[k-1];
		end

	end endgenerate
	// }}}

`ifndef VERILATOR
	//
	// Make some i_ce restraining assumptions.  These are necessary
	// to get the design to pass induction.
	//
	generate if (CKPCE <= 1)
	begin
		// {{{
		// No primary i_ce assumption.  i_ce can be anything
		//
		// First induction i_ce assumption: No more than one
		// empty cycle between used cycles.  Without this
		// assumption, or one like it, induction would never
		// complete.
		always @(posedge i_clk)
		if ((!$past(i_ce)))
			assume(i_ce);

		// Second induction i_ce assumption: avoid skipping an
		// i_ce and thus stretching out the i_ce cycle two i_ce
		// cycles in a row.  Without this assumption, induction
		// would still complete, it would just take longer
		always @(posedge i_clk)
		if (($past(i_ce))&&(!$past(i_ce,2)))
			assume(i_ce);
		// }}}
	end else if (CKPCE == 2)
	begin : F_CKPCE_TWO
		// {{{
		// Primary i_ce assumption: Every i_ce cycle is followed
		// by a non-i_ce cycle, so the multiplies can be
		// multiplexed
		always @(posedge i_clk)
		if ($past(i_ce))
			assume(!i_ce);
		// First induction assumption: Don't let this stretch
		// out too far.  This is necessary to pass induction
		always @(posedge i_clk)
		if ((!$past(i_ce))&&(!$past(i_ce,2)))
			assume(i_ce);

		always @(posedge i_clk)
		if ((!$past(i_ce))&&($past(i_ce,2))
				&&(!$past(i_ce,3))&&(!$past(i_ce,4)))
			assume(i_ce);
		// }}}
	end else if (CKPCE == 3)
	begin : F_CKPCE_THREE
		// {{{
		// Primary i_ce assumption: Following any i_ce cycle,
		// there must be two clock cycles with i_ce de-asserted
		always @(posedge i_clk)
		if (($past(i_ce))||($past(i_ce,2)))
			assume(!i_ce);

		// Induction assumption: Allow i_ce's every third or
		// fourth clock, but don't allow them to be separated
		// further than that
		always @(posedge i_clk)
		if ((!$past(i_ce))&&(!$past(i_ce,2))&&(!$past(i_ce,3)))
			assume(i_ce);

		// Second induction assumption, to speed up the proof:
		// If it's the earliest possible opportunity for an
		// i_ce, and the last i_ce was late, don't let this one
		// be late as well.
		always @(posedge i_clk)
		if ((!$past(i_ce))&&(!$past(i_ce,2))
			&&($past(i_ce,3))&&(!$past(i_ce,4))
			&&(!$past(i_ce,5))&&(!$past(i_ce,6)))
			assume(i_ce);
		// }}}
	end endgenerate
`endif

	reg	[F_LGDEPTH:0]	f_startup_counter;
	initial	f_startup_counter = 0;
	always @(posedge i_clk)
	if (i_reset)
		f_startup_counter <= 0;
	else if ((i_ce)&&(!(&f_startup_counter)))
		f_startup_counter <= f_startup_counter + 1;

	always @(*)
	begin
		f_sumr = f_dlyleft_r[F_D] + f_dlyright_r[F_D];
		f_sumi = f_dlyleft_i[F_D] + f_dlyright_i[F_D];
	end

	assign	f_sumrx = { {(4){f_sumr[IWIDTH]}}, f_sumr, {(CWIDTH-2){1'b0}} };
	assign	f_sumix = { {(4){f_sumi[IWIDTH]}}, f_sumi, {(CWIDTH-2){1'b0}} };

	always @(*)
	begin
		f_difr = f_dlyleft_r[F_D] - f_dlyright_r[F_D];
		f_difi = f_dlyleft_i[F_D] - f_dlyright_i[F_D];
	end

	assign	f_difrx = { {(CWIDTH+2){f_difr[IWIDTH]}}, f_difr };
	assign	f_difix = { {(CWIDTH+2){f_difi[IWIDTH]}}, f_difi };

	assign	f_widecoeff_r ={ {(IWIDTH+3){f_dlycoeff_r[F_D][CWIDTH-1]}},
						f_dlycoeff_r[F_D] };
	assign	f_widecoeff_i ={ {(IWIDTH+3){f_dlycoeff_i[F_D][CWIDTH-1]}},
						f_dlycoeff_i[F_D] };

	always @(posedge i_clk)
	if (f_startup_counter > {1'b0, F_D})
	begin
		assert(aux_pipeline == f_dlyaux);
		assert(left_sr == f_sumrx);
		assert(left_si == f_sumix);
		assert(aux_pipeline[AUXLEN-1] == f_dlyaux[F_D]);

		if ((f_difr == 0)&&(f_difi == 0))
		begin
			assert(mpy_r == 0);
			assert(mpy_i == 0);
		end else if ((f_dlycoeff_r[F_D] == 0)
				&&(f_dlycoeff_i[F_D] == 0))
		begin
			assert(mpy_r == 0);
			assert(mpy_i == 0);
		end

		if ((f_dlycoeff_r[F_D] == 1)&&(f_dlycoeff_i[F_D] == 0))
		begin
			assert(mpy_r == f_difrx);
			assert(mpy_i == f_difix);
		end

		if ((f_dlycoeff_r[F_D] == 0)&&(f_dlycoeff_i[F_D] == 1))
		begin
			assert(mpy_r == -f_difix);
			assert(mpy_i ==  f_difrx);
		end

		if ((f_difr == 1)&&(f_difi == 0))
		begin
			assert(mpy_r == f_widecoeff_r);
			assert(mpy_i == f_widecoeff_i);
		end

		if ((f_difr == 0)&&(f_difi == 1))
		begin
			assert(mpy_r == -f_widecoeff_i);
			assert(mpy_i ==  f_widecoeff_r);
		end
	end

	// Let's see if we can improve our performance at all by
	// moving our test one clock earlier.  If nothing else, it should
	// help induction finish one (or more) clocks ealier than
	// otherwise


	always @(*)
	begin
		f_predifr = f_dlyleft_r[F_D-1] - f_dlyright_r[F_D-1];
		f_predifi = f_dlyleft_i[F_D-1] - f_dlyright_i[F_D-1];
	end

	assign	f_predifrx = { {(CWIDTH+2){f_predifr[IWIDTH]}}, f_predifr };
	assign	f_predifix = { {(CWIDTH+2){f_predifi[IWIDTH]}}, f_predifi };

	always @(*)
	begin
		f_sumcoef = f_dlycoeff_r[F_D-1] + f_dlycoeff_i[F_D-1];
		f_sumdiff = f_predifr + f_predifi;
	end

	// Induction helpers
	always @(posedge i_clk)
	if (f_startup_counter >= { 1'b0, F_D })
	begin
		if (f_dlycoeff_r[F_D-1] == 0)
			assert(p_one == 0);
		if (f_dlycoeff_i[F_D-1] == 0)
			assert(p_two == 0);

		if (f_dlycoeff_r[F_D-1] == 1)
			assert(p_one == f_predifrx);
		if (f_dlycoeff_i[F_D-1] == 1)
			assert(p_two == f_predifix);

		if (f_predifr == 0)
			assert(p_one == 0);
		if (f_predifi == 0)
			assert(p_two == 0);

		// verilator lint_off WIDTH
		if (f_predifr == 1)
			assert(p_one == f_dlycoeff_r[F_D-1]);
		if (f_predifi == 1)
			assert(p_two == f_dlycoeff_i[F_D-1]);
		// verilator lint_on  WIDTH

		if (f_sumcoef == 0)
			assert(p_three == 0);
		if (f_sumdiff == 0)
			assert(p_three == 0);
		// verilator lint_off WIDTH
		if (f_sumcoef == 1)
			assert(p_three == f_sumdiff);
		if (f_sumdiff == 1)
			assert(p_three == f_sumcoef);
		// verilator lint_on  WIDTH
`ifdef	VERILATOR
		// Check that the multiplies match--but *ONLY* if using
		// Veri1lator, and not if using formal proper
		assert(p_one   == f_predifr * f_dlycoeff_r[F_D-1]);
		assert(p_two   == f_predifi * f_dlycoeff_i[F_D-1]);
		assert(p_three == f_sumdiff * f_sumcoef);
`endif	// VERILATOR
	end

	// The following logic formally insists that our version of the
	// inputs to the multiply matches what the (multiclock) multiply
	// thinks its inputs were.  While this may seem redundant, the
	// proof will not complete in any reasonable amount of time
	// without these assertions.

	assign	f_p3c_in = f_dlycoeff_i[F_D-1] + f_dlycoeff_r[F_D-1];
	assign	f_p3d_in = f_predifi + f_predifr;

	always @(*)
	if (f_startup_counter >= { 1'b0, F_D })
	begin
		assert(fp_one_ic == { f_dlycoeff_r[F_D-1][CWIDTH-1],
				f_dlycoeff_r[F_D-1][CWIDTH-1:0] });
		assert(fp_two_ic == { f_dlycoeff_i[F_D-1][CWIDTH-1],
				f_dlycoeff_i[F_D-1][CWIDTH-1:0] });
		assert(fp_one_id == { f_predifr[IWIDTH], f_predifr });
		assert(fp_two_id == { f_predifi[IWIDTH], f_predifi });
		assert(fp_three_ic == f_p3c_in);
		assert(fp_three_id == f_p3d_in);
	end

	// F_CHECK will be set externally by the solver, so that we can
	// double check that the solver is actually testing what we think
	// it is testing.  We'll set it here to MPYREMAINDER, which will
	// essentially eliminate the check--unless overridden by the
	// solver.
	parameter	F_CHECK = MPYREMAINDER;
	initial	assert(MPYREMAINDER == F_CHECK);

`endif // FORMAL
// }}}
endmodule
////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	convround.v
// {{{
// Project:	A General Purpose Pipelined FFT Implementation
//
// Purpose:	A convergent rounding routine, also known as banker's
//		rounding, Dutch rounding, Gaussian rounding, unbiased
//	rounding, or ... more, at least according to Wikipedia.
//
//	This form of rounding works by rounding, when the direction is in
//	question, towards the nearest even value.
//
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
module	convround(i_clk, i_ce, i_val, o_val);
	parameter	IWID=16, OWID=8, SHIFT=0;
	input	wire				i_clk, i_ce;
	input	wire	signed	[(IWID-1):0]	i_val;
	output	reg	signed	[(OWID-1):0]	o_val;

	// Let's deal with three cases to be as general as we can be here
	//
	//	1. The desired output would lose no bits at all
	//	2. One bit would be dropped, so the rounding is simply
	//		adjusting the value to be the nearest even number in
	//		cases of being halfway between two.  If identically
	//		equal to a number, we just leave it as is.
	//	3. Two or more bits would be dropped.  In this case, we round
	//		normally unless we are rounding a value of exactly
	//		halfway between the two.  In the halfway case we round
	//		to the nearest even number.
	generate
	if (IWID == OWID) // In this case, the shift is irrelevant and
	begin : NO_ROUNDING // cannot be applied.  No truncation or rounding takes
	// effect here.

		always @(posedge i_clk)
		if (i_ce)	o_val <= i_val[(IWID-1):0];

	end else if (IWID-SHIFT < OWID)
	begin : ADD_BITS_TO_OUTPUT // No truncation or rounding, output drops no bits
	// Instead, we need to stuff the bits in the output

		always @(posedge i_clk)
		if (i_ce)	o_val <= { {(OWID-IWID+SHIFT){i_val[IWID-SHIFT-1]}}, i_val[(IWID-SHIFT-1):0] };

	end else if (IWID-SHIFT == OWID)
	begin : SHIFT_ONE_BIT
	// No truncation or rounding, output drops no bits

		always @(posedge i_clk)
		if (i_ce)	o_val <= i_val[(IWID-SHIFT-1):0];

	end else if (IWID-SHIFT-1 == OWID)
	begin : DROP_ONE_BIT // Output drops one bit, can only add one or ... not.
		wire	[(OWID-1):0]	truncated_value, rounded_up;
		wire			last_valid_bit, first_lost_bit;
		assign	truncated_value=i_val[(IWID-1-SHIFT):(IWID-SHIFT-OWID)];
		assign	rounded_up=truncated_value + {{(OWID-1){1'b0}}, 1'b1 };
		assign	last_valid_bit = truncated_value[0];
		assign	first_lost_bit = i_val[0];

		always @(posedge i_clk)
		if (i_ce)
		begin
			if (!first_lost_bit) // Round down / truncate
				o_val <= truncated_value;
			else if (last_valid_bit)// Round up to nearest
				o_val <= rounded_up; // even value
			else // else round down to the nearest
				o_val <= truncated_value; // even value
		end

	end else // If there's more than one bit we are dropping
	begin : ROUND_RESULT
		wire	[(OWID-1):0]	truncated_value, rounded_up;
		wire			last_valid_bit, first_lost_bit;

		assign	truncated_value=i_val[(IWID-1-SHIFT):(IWID-SHIFT-OWID)];
		assign	rounded_up=truncated_value + {{(OWID-1){1'b0}}, 1'b1 };
		assign	last_valid_bit = truncated_value[0];
		assign	first_lost_bit = i_val[(IWID-SHIFT-OWID-1)];

		wire	[(IWID-SHIFT-OWID-2):0]	other_lost_bits;
		assign	other_lost_bits = i_val[(IWID-SHIFT-OWID-2):0];

		always @(posedge i_clk)
			if (i_ce)
			begin
				if (!first_lost_bit) // Round down / truncate
					o_val <= truncated_value;
				else if (|other_lost_bits) // Round up to
					o_val <= rounded_up; // closest value
				else if (last_valid_bit) // Round up to
					o_val <= rounded_up; // nearest even
				else	// else round down to nearest even
					o_val <= truncated_value;
			end
	end
	endgenerate

endmodule
////////////////////////////////////////////////////////////////////////////////
//
// Filename:	fftmain.v
// {{{
// Project:	A General Purpose Pipelined FFT Implementation
//
// Purpose:	This is the main module in the General Purpose FPGA FFT
//		implementation.  As such, all other modules are subordinate
//	to this one.  This module accomplish a fixed size Complex FFT on
//	256 data points.
//	The FFT is fully pipelined, and accepts as inputs one complex two's
//	complement sample per clock.
//
// Parameters:
//	i_clk	The clock.  All operations are synchronous with this clock.
//	i_reset	Synchronous reset, active high.  Setting this line will
//			force the reset of all of the internals to this routine.
//			Further, following a reset, the o_sync line will go
//			high the same time the first output sample is valid.
//	i_ce	A clock enable line.  If this line is set, this module
//			will accept one complex input value, and produce
//			one (possibly empty) complex output value.
//	i_sample	The complex input sample.  This value is split
//			into two two's complement numbers, 16 bits each, with
//			the real portion in the high order bits, and the
//			imaginary portion taking the bottom 16 bits.
//	o_result	The output result, of the same format as i_sample,
//			only having 21 bits for each of the real and imaginary
//			components, leading to 42 bits total.
//	o_sync	A one bit output indicating the first sample of the FFT frame.
//			It also indicates the first valid sample out of the FFT
//			on the first frame.
//
// Arguments:	This file was computer generated using the following command
//		line:
//
//		% ./fftgen -f 256 -a hdr
//
//	This core will use hardware accelerated multiplies (DSPs)
//	for 0 of the 8 stages
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
//
//
module fftmain(i_clk, i_reset, i_ce,
		i_sample, o_result, o_sync);
	// The bit-width of the input, IWIDTH, output, OWIDTH, and the log
	// of the FFT size.  These are localparams, rather than parameters,
	// because once the core has been generated, they can no longer be
	// changed.  (These values can be adjusted by running the core
	// generator again.)  The reason is simply that these values have
	// been hardwired into the core at several places.
	localparam	IWIDTH=16, OWIDTH=21; // LGWIDTH=8;
	//
	input	wire				i_clk, i_reset, i_ce;
	//
	input	wire	[(2*IWIDTH-1):0]	i_sample;
	output	reg	[(2*OWIDTH-1):0]	o_result;
	output	reg				o_sync;


	// Outputs of the FFT, ready for bit reversal.
	wire				br_sync;
	wire	[(2*OWIDTH-1):0]	br_result;


	wire		w_s256;
	wire	[33:0]	w_d256;
	fftstage	#(IWIDTH,IWIDTH+4,17,7,0,
			0, 1, "cmem_256.hex")
		stage_256(i_clk, i_reset, i_ce,
			(!i_reset), i_sample, w_d256, w_s256);


	wire		w_s128;
	wire	[35:0]	w_d128;
	fftstage	#(17,21,18,6,0,
			0, 1, "cmem_128.hex")
		stage_128(i_clk, i_reset, i_ce,
			w_s256, w_d256, w_d128, w_s128);

	wire		w_s64;
	wire	[35:0]	w_d64;
	fftstage	#(18,22,18,5,0,
			0, 1, "cmem_64.hex")
		stage_64(i_clk, i_reset, i_ce,
			w_s128, w_d128, w_d64, w_s64);

	wire		w_s32;
	wire	[37:0]	w_d32;
	fftstage	#(18,22,19,4,0,
			0, 1, "cmem_32.hex")
		stage_32(i_clk, i_reset, i_ce,
			w_s64, w_d64, w_d32, w_s32);

	wire		w_s16;
	wire	[37:0]	w_d16;
	fftstage	#(19,23,19,3,0,
			0, 1, "cmem_16.hex")
		stage_16(i_clk, i_reset, i_ce,
			w_s32, w_d32, w_d16, w_s16);

	wire		w_s8;
	wire	[39:0]	w_d8;
	fftstage	#(19,23,20,2,0,
			0, 1, "cmem_8.hex")
		stage_8(i_clk, i_reset, i_ce,
			w_s16, w_d16, w_d8, w_s8);

	wire		w_s4;
	wire	[39:0]	w_d4;
	qtrstage	#(20,20,8,0,0)	stage_4(i_clk, i_reset, i_ce,
						w_s8, w_d8, w_d4, w_s4);
	wire		w_s2;
	wire	[41:0]	w_d2;
	laststage	#(20,21,1)	stage_2(i_clk, i_reset, i_ce,
					w_s4, w_d4, w_d2, w_s2);


	wire	br_start;
	reg	r_br_started;
	initial	r_br_started = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
		r_br_started <= 1'b0;
	else if (i_ce)
		r_br_started <= r_br_started || w_s2;
	assign	br_start = r_br_started || w_s2;

	// Now for the bit-reversal stage.
	bitreverse	#(8,21)
	revstage(
		// {{{
		.i_clk(i_clk),
		.i_reset(i_reset),
		.i_ce(i_ce & br_start),
		.i_in(w_d2),
		.o_out(br_result),
		.o_sync(br_sync)
		// }}}
	);


	// Last clock: Register our outputs, we're done.
	initial	o_sync  = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
		o_sync  <= 1'b0;
	else if (i_ce)
		o_sync  <= br_sync;

	always @(posedge i_clk)
	if (i_ce)
		o_result  <= br_result;


    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, fftmain);
      #1;
    end
    `endif
    `endif

endmodule
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

	reg	[(LGSPAN):0]		iaddr;
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
////////////////////////////////////////////////////////////////////////////////
//
// Filename:	hwbfly.v
// {{{
// Project:	A General Purpose Pipelined FFT Implementation
//
// Purpose:	This routine is identical to the butterfly.v routine found
//		in 'butterfly.v', save only that it uses the verilog
//	operator '*' in hopes that the synthesizer would be able to optimize
//	it with hardware resources.
//
//	It is understood that a hardware multiply can complete its operation in
//	a single clock.
//
// Operation:
//
//	Given two inputs, A (i_left) and B (i_right), and a complex
//	coefficient C (i_coeff), return two outputs, O1 and O2, where:
//
//		O1 = A + B, and
//		O2 = (A - B)*C
//
//	This operation is commonly known as a Decimation in Frequency (DIF)
//	Radix-2 Butterfly.
//	O1 and O2 are rounded before being returned in (o_left) and o_right
//	to OWIDTH bits.  If SHIFT is one, an extra bit is dropped from these
//	values during the rounding process.
//
//	Further, since these outputs will take some number of clocks to
//	calculate, we'll pipe a value (i_aux) through the system and return
//	it with the results (o_aux), so you can synchronize to the outgoing
//	output stream.
//
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
module	hwbfly #(
		// {{{
		// Public changeable parameters ...
		//	- IWIDTH, number of bits in each component of the input
		//	- CWIDTH, number of bits in each component of the
		//	twiddle factor
		//	- OWIDTH, number of bits in each component of the
		//	output
		parameter IWIDTH=16,CWIDTH=IWIDTH+4,OWIDTH=IWIDTH+1,
		// SHIFT
		// {{{
		// Drop an additional bit on the output?
		parameter		SHIFT=0,
		// }}}
		// CKPCE
		// {{{
		// The number of clocks per clock enable, 1, 2, or 3.
		parameter	[1:0]	CKPCE=1
		// }}}
		// }}}
	) (
		// {{{
		input	wire	i_clk, i_reset, i_ce,
		input	wire	[(2*CWIDTH-1):0]	i_coef,
		input	wire	[(2*IWIDTH-1):0]	i_left, i_right,
		input	wire	i_aux,
		output	wire	[(2*OWIDTH-1):0]	o_left, o_right,
		output	reg	o_aux
		// }}}
	);

	// Local signal declarations
	// {{{
	reg	[(2*IWIDTH-1):0]	r_left, r_right;
	reg				r_aux, r_aux_2;
	reg	[(2*CWIDTH-1):0]	r_coef;
	wire	signed	[(IWIDTH-1):0]	r_left_r, r_left_i, r_right_r, r_right_i;
	reg	signed	[(CWIDTH-1):0]	ir_coef_r, ir_coef_i;

	reg	signed	[(IWIDTH):0]	r_sum_r, r_sum_i, r_dif_r, r_dif_i;

	reg	[(2*IWIDTH+2):0]	leftv, leftvv;

	wire	signed	[((IWIDTH+1)+(CWIDTH)-1):0]	p_one, p_two;
	wire	signed	[((IWIDTH+2)+(CWIDTH+1)-1):0]	p_three;

	wire	signed	[((IWIDTH+2)+(CWIDTH+1)-1):0]	w_one, w_two;

	wire	aux_s;
	wire	signed	[(IWIDTH+CWIDTH):0]	left_si, left_sr;
	reg		[(2*IWIDTH+2):0]	left_saved;
	(* use_dsp48="no" *)
	reg	signed	[(CWIDTH+IWIDTH+3-1):0]	mpy_r, mpy_i;

	wire	signed	[(OWIDTH-1):0]	rnd_left_r, rnd_left_i, rnd_right_r, rnd_right_i;
	// }}}

	assign	r_left_r  = r_left[ (2*IWIDTH-1):(IWIDTH)];
	assign	r_left_i  = r_left[ (IWIDTH-1):0];
	assign	r_right_r = r_right[(2*IWIDTH-1):(IWIDTH)];
	assign	r_right_i = r_right[(IWIDTH-1):0];

	// Set up the input to the multiply

	// r_aux, r_aux_2
	// {{{
	initial r_aux   = 1'b0;
	initial r_aux_2 = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
	begin
		r_aux <= 1'b0;
		r_aux_2 <= 1'b0;
	end else if (i_ce)
	begin
		// One clock just latches the inputs
		r_aux <= i_aux;
		// Next clock adds/subtracts
		// Other inputs are simply delayed on second clock
		r_aux_2 <= r_aux;
	end
	// }}}

	// r_[left|right|coef], r_[sum|dif]_[r|i], ir_coef_[r|i]
	// {{{
	always @(posedge i_clk)
	if (i_ce)
	begin
		// One clock just latches the inputs
		r_left <= i_left;	// No change in # of bits
		r_right <= i_right;
		r_coef  <= i_coef;
		// Next clock adds/subtracts
		r_sum_r <= r_left_r + r_right_r; // Now IWIDTH+1 bits
		r_sum_i <= r_left_i + r_right_i;
		r_dif_r <= r_left_r - r_right_r;
		r_dif_i <= r_left_i - r_right_i;
		// Other inputs are simply delayed on second clock
		ir_coef_r <= r_coef[(2*CWIDTH-1):CWIDTH];
		ir_coef_i <= r_coef[(CWIDTH-1):0];
	end
	// }}}


	// See comments in the butterfly.v source file for a discussion of
	// these operations and the appropriate bit widths.


	// leftv, leftvv
	// {{{
	initial leftv    = 0;
	initial leftvv   = 0;
	always @(posedge i_clk)
	if (i_reset)
	begin
		leftv <= 0;
		leftvv <= 0;
	end else if (i_ce)
	begin
		// Second clock, pipeline = 1
		leftv <= { r_aux_2, r_sum_r, r_sum_i };

		// Third clock, pipeline = 3
		//   As desired, each of these lines infers a DSP48
		leftvv <= leftv;
	end
	// }}}

	// Core multiply section
	// {{{
	generate if (CKPCE <= 1)
	begin : CKPCE_ONE
		// {{{
		// Local declarations
		// {{{
		// Coefficient multiply inputs
		reg	signed	[(CWIDTH-1):0]	p1c_in, p2c_in;
		// Data multiply inputs
		reg	signed	[(IWIDTH):0]	p1d_in, p2d_in;
		// Product 3, coefficient input
		reg	signed	[(CWIDTH):0]	p3c_in;
		// Product 3, data input
		reg	signed	[(IWIDTH+1):0]	p3d_in;

		reg	signed	[((IWIDTH+1)+(CWIDTH)-1):0]	rp_one, rp_two;
		reg	signed	[((IWIDTH+2)+(CWIDTH+1)-1):0]	rp_three;
		// }}}

		// p[1|2]c_in, p[1|2|3]d_in
		// {{{
		always @(posedge i_clk)
		if (i_ce)
		begin
			// Second clock, pipeline = 1
			p1c_in <= ir_coef_r;
			p2c_in <= ir_coef_i;
			p1d_in <= r_dif_r;
			p2d_in <= r_dif_i;
			p3c_in <= ir_coef_i + ir_coef_r;
			p3d_in <= r_dif_r + r_dif_i;
		end
		// }}}

		// Perform our multiplies
		// {{{
`ifndef	FORMAL
		always @(posedge i_clk)
		if (i_ce)
		begin
			// Third clock, pipeline = 3
			//   As desired, each of these lines infers a DSP48
			rp_one   <= p1c_in * p1d_in;
			rp_two   <= p2c_in * p2d_in;
			rp_three <= p3c_in * p3d_in;
		end
`else
		// {{{
		wire	signed	[((IWIDTH+1)+(CWIDTH)-1):0]	pre_rp_one, pre_rp_two;
		wire	signed	[((IWIDTH+2)+(CWIDTH+1)-1):0]	pre_rp_three;

		abs_mpy #(CWIDTH,IWIDTH+1,1'b1)
			onei(p1c_in, p1d_in, pre_rp_one);
		abs_mpy #(CWIDTH,IWIDTH+1,1'b1)
			twoi(p2c_in, p2d_in, pre_rp_two);
		abs_mpy #(CWIDTH+1,IWIDTH+2,1'b1)
			threei(p3c_in, p3d_in, pre_rp_three);

		always @(posedge i_clk)
		if (i_ce)
		begin
			rp_one   <= pre_rp_one;
			rp_two   <= pre_rp_two;
			rp_three <= pre_rp_three;
		end
		// }}}
`endif // FORMAL
		// }}}

		assign	p_one   = rp_one;
		assign	p_two   = rp_two;
		assign	p_three = rp_three;
		// }}}
	end else if (CKPCE <= 2)
	begin : CKPCE_TWO
		// {{{
		// Local declarations
		// {{{
		// Coefficient multiply inputs
		reg		[2*(CWIDTH)-1:0]	mpy_pipe_c;
		// Data multiply inputs
		reg		[2*(IWIDTH+1)-1:0]	mpy_pipe_d;
		wire	signed	[(CWIDTH-1):0]	mpy_pipe_vc;
		wire	signed	[(IWIDTH):0]	mpy_pipe_vd;
		//
		reg	signed	[(CWIDTH+1)-1:0]	mpy_cof_sum;
		reg	signed	[(IWIDTH+2)-1:0]	mpy_dif_sum;

		reg			mpy_pipe_v;
		reg			ce_phase;

		reg	signed	[(CWIDTH+IWIDTH+1)-1:0]	mpy_pipe_out;
		reg	signed [IWIDTH+CWIDTH+3-1:0]	longmpy;

		reg	signed	[((IWIDTH+1)+(CWIDTH)-1):0]	rp_one,
							rp2_one, rp_two;
		reg	signed	[((IWIDTH+2)+(CWIDTH+1)-1):0]	rp_three;
		// }}}

		assign	mpy_pipe_vc =  mpy_pipe_c[2*(CWIDTH)-1:CWIDTH];
		assign	mpy_pipe_vd =  mpy_pipe_d[2*(IWIDTH+1)-1:IWIDTH+1];

		// ce_phase
		// {{{
		initial	ce_phase = 1'b1;
		always @(posedge i_clk)
		if (i_reset)
			ce_phase <= 1'b1;
		else if (i_ce)
			ce_phase <= 1'b0;
		else
			ce_phase <= 1'b1;
		// }}}

		// mpy_pipe_v
		// {{{
		always @(*)
			mpy_pipe_v = (i_ce)||(!ce_phase);
		// }}}

		// mpy_pipe_c, mpy_pipe_d, mpy_cof_sum, mpy_dif_sum
		// {{{
		always @(posedge i_clk)
		if (!ce_phase)
		begin
			// Pre-clock
			mpy_pipe_c[2*CWIDTH-1:0] <=
					{ ir_coef_r, ir_coef_i };
			mpy_pipe_d[2*(IWIDTH+1)-1:0] <=
					{ r_dif_r, r_dif_i };

			mpy_cof_sum  <= ir_coef_i + ir_coef_r;
			mpy_dif_sum <= r_dif_r + r_dif_i;

		end else if (i_ce)
		begin
			// First clock
			mpy_pipe_c[2*(CWIDTH)-1:0] <= {
				mpy_pipe_c[(CWIDTH)-1:0], {(CWIDTH){1'b0}} };
			mpy_pipe_d[2*(IWIDTH+1)-1:0] <= {
				mpy_pipe_d[(IWIDTH+1)-1:0], {(IWIDTH+1){1'b0}} };
		end
		// }}}

		// Perform the actual multiplies
		// {{{
`ifndef	FORMAL
		always @(posedge i_clk)
		if (i_ce) // First clock
			longmpy <= mpy_cof_sum * mpy_dif_sum;

		always @(posedge i_clk)
		if (mpy_pipe_v)
			mpy_pipe_out <= mpy_pipe_vc * mpy_pipe_vd;
`else
		// {{{
		wire	signed [IWIDTH+CWIDTH+3-1:0]	pre_longmpy;
		wire	signed	[(CWIDTH+IWIDTH+1)-1:0]	pre_mpy_pipe_out;

		abs_mpy	#(CWIDTH+1,IWIDTH+2,1)
			longmpyi(mpy_cof_sum, mpy_dif_sum, pre_longmpy);

		always @(posedge i_clk)
		if (i_ce)
			longmpy <= pre_longmpy;


		abs_mpy #(CWIDTH,IWIDTH+1,1)
			mpy_pipe_outi(mpy_pipe_vc, mpy_pipe_vd, pre_mpy_pipe_out);

		always @(posedge i_clk)
		if (mpy_pipe_v)
			mpy_pipe_out <= pre_mpy_pipe_out;
		// }}}
`endif
		// }}}

		// Register our outputs
		// {{{
		always @(posedge i_clk)
		if (!ce_phase) // 1.5 clock
			rp_one <= mpy_pipe_out;
		always @(posedge i_clk)
		if (i_ce) // two clocks
			rp_two <= mpy_pipe_out;
		always @(posedge i_clk)
		if (i_ce) // Second clock
			rp_three<= longmpy;

		// Reclock rp_one when i_ce is true next
		always @(posedge i_clk)
		if (i_ce)
			rp2_one<= rp_one;
		// }}}

		// Assign our output values
		// {{{
		assign	p_one  = rp2_one;
		assign	p_two  = rp_two;
		assign	p_three= rp_three;
		// }}}

		// }}}
	end else if (CKPCE <= 2'b11)
	begin : CKPCE_THREE
		// {{{
		// Local declarations
		// {{{
		// Coefficient multiply inputs
		reg		[3*(CWIDTH+1)-1:0]	mpy_pipe_c;
		// Data multiply inputs
		reg		[3*(IWIDTH+2)-1:0]	mpy_pipe_d;
		wire	signed	[(CWIDTH):0]	mpy_pipe_vc;
		wire	signed	[(IWIDTH+1):0]	mpy_pipe_vd;

		reg			mpy_pipe_v;
		reg		[2:0]	ce_phase;

		reg	signed	[  (CWIDTH+IWIDTH+3)-1:0]	mpy_pipe_out;

		reg	signed	[((IWIDTH+1)+(CWIDTH)-1):0]	rp_one, rp_two,
						rp2_one, rp2_two;
		reg	signed	[((IWIDTH+2)+(CWIDTH+1)-1):0]	rp_three, rp2_three;
		// }}}


		assign	mpy_pipe_vc =  mpy_pipe_c[3*(CWIDTH+1)-1:2*(CWIDTH+1)];
		assign	mpy_pipe_vd =  mpy_pipe_d[3*(IWIDTH+2)-1:2*(IWIDTH+2)];

		// ce_phase
		// {{{
		initial	ce_phase = 3'b011;
		always @(posedge i_clk)
		if (i_reset)
			ce_phase <= 3'b011;
		else if (i_ce)
			ce_phase <= 3'b000;
		else if (ce_phase != 3'b011)
			ce_phase <= ce_phase + 1'b1;
		// }}}

		// mpy_pipe_v
		// {{{
		always @(*)
			mpy_pipe_v = (i_ce)||(ce_phase < 3'b010);
		// }}}

		// mpy_pipe_c, mpy_pipe_d
		// {{{
		always @(posedge i_clk)
		if (ce_phase == 3'b000)
		begin
			// Second clock
			mpy_pipe_c[3*(CWIDTH+1)-1:(CWIDTH+1)] <= {
				ir_coef_r[CWIDTH-1], ir_coef_r,
				ir_coef_i[CWIDTH-1], ir_coef_i };
			mpy_pipe_c[CWIDTH:0] <= ir_coef_i + ir_coef_r;
			mpy_pipe_d[3*(IWIDTH+2)-1:(IWIDTH+2)] <= {
				r_dif_r[IWIDTH], r_dif_r,
				r_dif_i[IWIDTH], r_dif_i };
			mpy_pipe_d[(IWIDTH+2)-1:0] <= r_dif_r + r_dif_i;

		end else if (mpy_pipe_v)
		begin
			mpy_pipe_c[3*(CWIDTH+1)-1:0] <= {
				mpy_pipe_c[2*(CWIDTH+1)-1:0], {(CWIDTH+1){1'b0}} };
			mpy_pipe_d[3*(IWIDTH+2)-1:0] <= {
				mpy_pipe_d[2*(IWIDTH+2)-1:0], {(IWIDTH+2){1'b0}} };
		end
		// }}}

		// Perform our actual multiplies
		// {{{
`ifndef	FORMAL
		// mpy_pipe_out
		// {{{
		always @(posedge i_clk)
		if (mpy_pipe_v)
			mpy_pipe_out <= mpy_pipe_vc * mpy_pipe_vd;
		// }}}

`else	// FORMAL
		// {{{
		wire	signed	[  (CWIDTH+IWIDTH+3)-1:0] pre_mpy_pipe_out;

		abs_mpy #(CWIDTH+1,IWIDTH+2,1)
			mpy_pipe_outi(mpy_pipe_vc, mpy_pipe_vd, pre_mpy_pipe_out);
		always @(posedge i_clk)
		if (mpy_pipe_v)
			mpy_pipe_out <= pre_mpy_pipe_out;
		// }}}
`endif	// FORMAL
		// }}}
		// rp_[one|two|three], rp2_[one|two|three]--Sync outputs to i_ce
		// {{{
		always @(posedge i_clk)
		if(i_ce)
			rp_one <= mpy_pipe_out[(CWIDTH+IWIDTH):0];

		always @(posedge i_clk)
		if(ce_phase == 3'b000)
			rp_two <= mpy_pipe_out[(CWIDTH+IWIDTH):0];

		always @(posedge i_clk)
		if(ce_phase == 3'b001)
			rp_three <= mpy_pipe_out;

		always @(posedge i_clk)
		if (i_ce)
		begin
			rp2_one<= rp_one;
			rp2_two<= rp_two;
			rp2_three<= rp_three;
		end
		// }}}

		// Assign to p_* values
		// {{{
		assign	p_one	= rp2_one;
		assign	p_two	= rp2_two;
		assign	p_three	= rp2_three;
		// }}}

		// }}}
	end endgenerate
	// }}}

	assign	w_one = { {(2){p_one[((IWIDTH+1)+(CWIDTH)-1)]}}, p_one };
	assign	w_two = { {(2){p_two[((IWIDTH+1)+(CWIDTH)-1)]}}, p_two };

	// left_sr, left_si
	// {{{
	// These values are held in memory and delayed during the
	// multiply.  Here, we recover them.  During the multiply,
	// values were multiplied by 2^(CWIDTH-2)*exp{-j*2*pi*...},
	// therefore, the left_x values need to be right shifted by
	// CWIDTH-2 as well.  The additional bits come from a sign
	// extension.
	assign	left_sr = { {2{left_saved[2*(IWIDTH+1)-1]}}, left_saved[(2*(IWIDTH+1)-1):(IWIDTH+1)], {(CWIDTH-2){1'b0}} };
	assign	left_si = { {2{left_saved[(IWIDTH+1)-1]}}, left_saved[((IWIDTH+1)-1):0], {(CWIDTH-2){1'b0}} };
	// }}}
	assign	aux_s = left_saved[2*IWIDTH+2];

	// left_saved, o_aux
	// {{{
	initial left_saved = 0;
	initial o_aux      = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
	begin
		left_saved <= 0;
		o_aux <= 1'b0;
	end else if (i_ce)
	begin
		// First clock, recover all values
		left_saved <= leftvv;

		// Second clock, round and latch for final clock
		o_aux <= aux_s;
	end
	// }}}

	// mpy_r, mpy_i
	// {{{
	always @(posedge i_clk)
	if (i_ce)
	begin
		// These values are IWIDTH+CWIDTH+3 bits wide
		// although they only need to be (IWIDTH+1)
		// + (CWIDTH) bits wide.  (We've got two
		// extra bits we need to get rid of.)

		// These two lines also infer DSP48's.
		// To keep from using extra DSP48 resources,
		// they are prevented from using DSP48's
		// by the (* use_dsp48 ... *) comment above.
		mpy_r <= w_one - w_two;
		mpy_i <= p_three - w_one - w_two;
	end
	// }}}

	// Round the results
	// {{{
	convround #(CWIDTH+IWIDTH+1,OWIDTH,SHIFT+2)
	do_rnd_left_r(i_clk, i_ce, left_sr, rnd_left_r);

	convround #(CWIDTH+IWIDTH+1,OWIDTH,SHIFT+2)
	do_rnd_left_i(i_clk, i_ce, left_si, rnd_left_i);

	convround #(CWIDTH+IWIDTH+3,OWIDTH,SHIFT+4)
	do_rnd_right_r(i_clk, i_ce, mpy_r, rnd_right_r);

	convround #(CWIDTH+IWIDTH+3,OWIDTH,SHIFT+4)
	do_rnd_right_i(i_clk, i_ce, mpy_i, rnd_right_i);
	// }}}

	// o_left, o_right
	// {{{
	// As a final step, we pack our outputs into two packed two's
	// complement numbers per output word, so that each output word
	// has (2*OWIDTH) bits in it, with the top half being the real
	// portion and the bottom half being the imaginary portion.
	assign	o_left = { rnd_left_r, rnd_left_i };
	assign	o_right= { rnd_right_r,rnd_right_i};
// }}}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// Formal property section
// {{{
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
`ifdef	FORMAL
	localparam	F_LGDEPTH = 3;
	localparam	F_DEPTH = 5;
	localparam	[F_LGDEPTH-1:0]	F_D = F_DEPTH-1;

	reg	signed	[IWIDTH-1:0]	f_dlyleft_r  [0:F_DEPTH-1];
	reg	signed	[IWIDTH-1:0]	f_dlyleft_i  [0:F_DEPTH-1];
	reg	signed	[IWIDTH-1:0]	f_dlyright_r [0:F_DEPTH-1];
	reg	signed	[IWIDTH-1:0]	f_dlyright_i [0:F_DEPTH-1];
	reg	signed	[CWIDTH-1:0]	f_dlycoeff_r [0:F_DEPTH-1];
	reg	signed	[CWIDTH-1:0]	f_dlycoeff_i [0:F_DEPTH-1];
	reg	signed	[F_DEPTH-1:0]	f_dlyaux;
	reg	[F_LGDEPTH-1:0]	f_startup_counter;
	reg	signed	[IWIDTH:0]	f_sumr, f_sumi;
	reg	signed	[IWIDTH+CWIDTH:0]	f_sumrx, f_sumix;
	reg	signed	[IWIDTH:0]	f_difr, f_difi;
	wire	signed	[IWIDTH+CWIDTH+3-1:0]	f_difrx, f_difix;
	wire	signed	[IWIDTH+CWIDTH+3-1:0]	f_widecoeff_r, f_widecoeff_i;
	reg	signed	[IWIDTH:0]	f_predifr, f_predifi;
	wire	signed	[IWIDTH+CWIDTH+1-1:0]	f_predifrx, f_predifix;
	reg	signed	[CWIDTH:0]	f_sumcoef;
	reg	signed	[IWIDTH+1:0]	f_sumdiff;

	always @(posedge i_clk)
	if (i_reset)
		f_dlyaux <= 0;
	else if (i_ce)
		f_dlyaux <= { f_dlyaux[F_DEPTH-2:0], i_aux };

	always @(posedge i_clk)
	if (i_ce)
	begin
		f_dlyleft_r[0]   <= i_left[ (2*IWIDTH-1):IWIDTH];
		f_dlyleft_i[0]   <= i_left[ (  IWIDTH-1):0];
		f_dlyright_r[0]  <= i_right[(2*IWIDTH-1):IWIDTH];
		f_dlyright_i[0]  <= i_right[(  IWIDTH-1):0];
		f_dlycoeff_r[0]  <= i_coef[ (2*CWIDTH-1):CWIDTH];
		f_dlycoeff_i[0]  <= i_coef[ (  CWIDTH-1):0];
	end

	genvar	k;
	generate for(k=1; k<F_DEPTH; k=k+1)

		always @(posedge i_clk)
		if (i_ce)
		begin
			f_dlyleft_r[k]  <= f_dlyleft_r[ k-1];
			f_dlyleft_i[k]  <= f_dlyleft_i[ k-1];
			f_dlyright_r[k] <= f_dlyright_r[k-1];
			f_dlyright_i[k] <= f_dlyright_i[k-1];
			f_dlycoeff_r[k] <= f_dlycoeff_r[k-1];
			f_dlycoeff_i[k] <= f_dlycoeff_i[k-1];
		end

	endgenerate

`ifdef	VERILATOR
`else
	always @(posedge i_clk)
	if ((!$past(i_ce))&&(!$past(i_ce,2))&&(!$past(i_ce,3))
			&&(!$past(i_ce,4)))
		assume(i_ce);

	generate if (CKPCE <= 1)
	begin

		// i_ce is allowed to be anything in this mode

	end else if (CKPCE == 2)
	begin : F_CKPCE_TWO

		always @(posedge i_clk)
			if ($past(i_ce))
				assume(!i_ce);

	end else if (CKPCE == 3)
	begin : F_CKPCE_THREE

		always @(posedge i_clk)
			if (($past(i_ce))||($past(i_ce,2)))
				assume(!i_ce);

	end endgenerate
`endif
	initial	f_startup_counter = 0;
	always @(posedge i_clk)
	if (i_reset)
		f_startup_counter <= 0;
	else if ((i_ce)&&(!(&f_startup_counter)))
		f_startup_counter <= f_startup_counter + 1;

	always @(*)
	begin
		f_sumr = f_dlyleft_r[F_D] + f_dlyright_r[F_D];
		f_sumi = f_dlyleft_i[F_D] + f_dlyright_i[F_D];
	end

	assign	f_sumrx = { {(2){f_sumr[IWIDTH]}}, f_sumr, {(CWIDTH-2){1'b0}} };
	assign	f_sumix = { {(2){f_sumi[IWIDTH]}}, f_sumi, {(CWIDTH-2){1'b0}} };

	always @(*)
	begin
		f_difr = f_dlyleft_r[F_D] - f_dlyright_r[F_D];
		f_difi = f_dlyleft_i[F_D] - f_dlyright_i[F_D];
	end

	assign	f_difrx = { {(CWIDTH+2){f_difr[IWIDTH]}}, f_difr };
	assign	f_difix = { {(CWIDTH+2){f_difi[IWIDTH]}}, f_difi };

	assign	f_widecoeff_r = {{(IWIDTH+3){f_dlycoeff_r[F_D][CWIDTH-1]}},
			f_dlycoeff_r[F_D] };
	assign	f_widecoeff_i = {{(IWIDTH+3){f_dlycoeff_i[F_D][CWIDTH-1]}},
			f_dlycoeff_i[F_D] };

	always @(posedge i_clk)
	if (f_startup_counter > F_D)
	begin
		assert(left_sr == f_sumrx);
		assert(left_si == f_sumix);
		assert(aux_s == f_dlyaux[F_D]);

		if ((f_difr == 0)&&(f_difi == 0))
		begin
			assert(mpy_r == 0);
			assert(mpy_i == 0);
		end else if ((f_dlycoeff_r[F_D] == 0)
				&&(f_dlycoeff_i[F_D] == 0))
		begin
			assert(mpy_r == 0);
			assert(mpy_i == 0);
		end

		if ((f_dlycoeff_r[F_D] == 1)&&(f_dlycoeff_i[F_D] == 0))
		begin
			assert(mpy_r == f_difrx);
			assert(mpy_i == f_difix);
		end

		if ((f_dlycoeff_r[F_D] == 0)&&(f_dlycoeff_i[F_D] == 1))
		begin
			assert(mpy_r == -f_difix);
			assert(mpy_i ==  f_difrx);
		end

		if ((f_difr == 1)&&(f_difi == 0))
		begin
			assert(mpy_r == f_widecoeff_r);
			assert(mpy_i == f_widecoeff_i);
		end

		if ((f_difr == 0)&&(f_difi == 1))
		begin
			assert(mpy_r == -f_widecoeff_i);
			assert(mpy_i ==  f_widecoeff_r);
		end
	end

	// Let's see if we can improve our performance at all by
	// moving our test one clock earlier.  If nothing else, it should
	// help induction finish one (or more) clocks ealier than
	// otherwise


	always @(*)
	begin
		f_predifr = f_dlyleft_r[F_D-1] - f_dlyright_r[F_D-1];
		f_predifi = f_dlyleft_i[F_D-1] - f_dlyright_i[F_D-1];
	end

	assign	f_predifrx = { {(CWIDTH){f_predifr[IWIDTH]}}, f_predifr };
	assign	f_predifix = { {(CWIDTH){f_predifi[IWIDTH]}}, f_predifi };

	always @(*)
	begin
		f_sumcoef = f_dlycoeff_r[F_D-1] + f_dlycoeff_i[F_D-1];
		f_sumdiff = f_predifr + f_predifi;
	end

	// Induction helpers
	always @(posedge i_clk)
	if (f_startup_counter >= F_D)
	begin
		if (f_dlycoeff_r[F_D-1] == 0)
			assert(p_one == 0);
		if (f_dlycoeff_i[F_D-1] == 0)
			assert(p_two == 0);

		if (f_dlycoeff_r[F_D-1] == 1)
			assert(p_one == f_predifrx);
		if (f_dlycoeff_i[F_D-1] == 1)
			assert(p_two == f_predifix);

		if (f_predifr == 0)
			assert(p_one == 0);
		if (f_predifi == 0)
			assert(p_two == 0);

		// verilator lint_off WIDTH
		if (f_predifr == 1)
			assert(p_one == f_dlycoeff_r[F_D-1]);
		if (f_predifi == 1)
			assert(p_two == f_dlycoeff_i[F_D-1]);
		// verilator lint_on  WIDTH

		if (f_sumcoef == 0)
			assert(p_three == 0);
		if (f_sumdiff == 0)
			assert(p_three == 0);
		// verilator lint_off WIDTH
		if (f_sumcoef == 1)
			assert(p_three == f_sumdiff);
		if (f_sumdiff == 1)
			assert(p_three == f_sumcoef);
		// verilator lint_on  WIDTH
`ifdef	VERILATOR
		assert(p_one   == f_predifr * f_dlycoeff_r[F_D-1]);
		assert(p_two   == f_predifi * f_dlycoeff_i[F_D-1]);
		assert(p_three == f_sumdiff * f_sumcoef);
`endif	// VERILATOR
	end

`endif // FORMAL
// }}}
endmodule
////////////////////////////////////////////////////////////////////////////////
//
// Filename:	laststage.v
// {{{
// Project:	A General Purpose Pipelined FFT Implementation
//
// Purpose:	This is part of an FPGA implementation that will process
//		the final stage of a decimate-in-frequency FFT, running
//	through the data at one sample per clock.
//
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
module	laststage #(
		// {{{
		parameter IWIDTH=16,OWIDTH=IWIDTH+1, SHIFT=0
		// }}}
	) (
		// {{{
		input	wire			i_clk, i_reset, i_ce, i_sync,
		input	wire  [(2*IWIDTH-1):0]	i_val,
		output	wire [(2*OWIDTH-1):0]	o_val,
		output	reg			o_sync
		// }}}
	);
	// Local declarations
	// {{{
	reg	signed	[(IWIDTH-1):0]	m_r, m_i;
	wire	signed	[(IWIDTH-1):0]	i_r, i_i;

	// Don't forget that we accumulate a bit by adding two values
	// together. Therefore our intermediate value must have one more
	// bit than the two originals.
	reg	signed	[(IWIDTH):0]	rnd_r, rnd_i, sto_r, sto_i;
	reg				wait_for_sync, stage;
	reg		[1:0]		sync_pipe;
	wire	signed	[(OWIDTH-1):0]	o_r, o_i;
	// }}}

	assign	i_r = i_val[(2*IWIDTH-1):(IWIDTH)]; 
	assign	i_i = i_val[(IWIDTH-1):0]; 

	// wait_for_sync, stage
	// {{{
	initial	wait_for_sync = 1'b1;
	initial	stage         = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
	begin
		wait_for_sync <= 1'b1;
		stage         <= 1'b0;
	end else if ((i_ce)&&((!wait_for_sync)||(i_sync))&&(!stage))
	begin
		wait_for_sync <= 1'b0;
		//
		stage <= 1'b1;
		//
	end else if (i_ce)
		stage <= 1'b0;
	// }}}

	// sync_pipe
	// {{{
	initial	sync_pipe = 0;
	always @(posedge i_clk)
	if (i_reset)
		sync_pipe <= 0;
	else if (i_ce)
		sync_pipe <= { sync_pipe[0], i_sync };
	// }}}

	// o_sync
	// {{{
	initial	o_sync = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
		o_sync <= 1'b0;
	else if (i_ce)
		o_sync <= sync_pipe[1];
	// }}}

	// m_r, m_i, rnd_r, rnd_i
	// {{{
	always @(posedge i_clk)
	if (i_ce)
	begin
		if (!stage)
		begin
			// Clock 1
			m_r <= i_r;
			m_i <= i_i;
			// Clock 3
			rnd_r <= sto_r;
			rnd_i <= sto_i;
			//
		end else begin
			// Clock 2
			rnd_r <= m_r + i_r;
			rnd_i <= m_i + i_i;
			//
			sto_r <= m_r - i_r;
			sto_i <= m_i - i_i;
			//
		end
	end
	// }}}

	// Now that we have our results, let's round them and report them

	// Round the results, generating o_r, o_i, and thus o_val
	// {{{
	convround #(IWIDTH+1,OWIDTH,SHIFT) do_rnd_r(i_clk, i_ce, rnd_r, o_r);
	convround #(IWIDTH+1,OWIDTH,SHIFT) do_rnd_i(i_clk, i_ce, rnd_i, o_i);

	assign	o_val  = { o_r, o_i };
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
	// Local formal declarations
	// {{{
	reg	f_past_valid;
	wire	f_syncd;
	reg	f_rsyncd;
	reg	f_state;
	// }}}

	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

`ifdef	LASTSTAGE
	always @(posedge i_clk)
		assume((i_ce)||($past(i_ce))||($past(i_ce,2)));
`endif

	initial	assert(IWIDTH+1 == OWIDTH);

	reg	signed	[IWIDTH-1:0]	f_piped_real	[0:3];
	reg	signed	[IWIDTH-1:0]	f_piped_imag	[0:3];
	always @(posedge i_clk)
	if (i_ce)
	begin
		f_piped_real[0] <= i_val[2*IWIDTH-1:IWIDTH];
		f_piped_imag[0] <= i_val[  IWIDTH-1:0];

		f_piped_real[1] <= f_piped_real[0];
		f_piped_imag[1] <= f_piped_imag[0];

		f_piped_real[2] <= f_piped_real[1];
		f_piped_imag[2] <= f_piped_imag[1];

		f_piped_real[3] <= f_piped_real[2];
		f_piped_imag[3] <= f_piped_imag[2];
	end

	initial	f_rsyncd	= 0;
	always @(posedge i_clk)
	if (i_reset)
		f_rsyncd <= 1'b0;
	else if (!f_rsyncd)
		f_rsyncd <= o_sync;
	assign	f_syncd = (f_rsyncd)||(o_sync);

	initial	f_state = 0;
	always @(posedge i_clk)
	if (i_reset)
		f_state <= 0;
	else if ((i_ce)&&((!wait_for_sync)||(i_sync)))
		f_state <= f_state + 1;

	always @(*)
	if (f_state != 0)
		assume(!i_sync);

	always @(*)
		assert(stage == f_state[0]);

	always @(posedge i_clk)
	if ((f_state == 1'b1)&&(f_syncd))
	begin
		assert(o_r == f_piped_real[2] + f_piped_real[1]);
		assert(o_i == f_piped_imag[2] + f_piped_imag[1]);
	end

	always @(posedge i_clk)
	if ((f_state == 1'b0)&&(f_syncd))
	begin
		assert(!o_sync);
		assert(o_r == f_piped_real[3] - f_piped_real[2]);
		assert(o_i == f_piped_imag[3] - f_piped_imag[2]);
	end

	always @(*)
	if (wait_for_sync)
	begin
		assert(!f_rsyncd);
		assert(!o_sync);
		assert(f_state == 0);
	end

`endif // FORMAL
// }}}
endmodule
////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	fft-core/longbimpy.v
// {{{
// Project:	A General Purpose Pipelined FFT Implementation
//
// Purpose:	A portable shift and add multiply, built with the knowledge
//	of the existence of a six bit LUT and carry chain.  That knowledge
//	allows us to multiply two bits from one value at a time against all
//	of the bits of the other value.  This sub multiply is called the
//	bimpy.
//
//	For minimal processing delay, make the first parameter the one with
//	the least bits, so that AWIDTH <= BWIDTH.
//
//
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
module	longbimpy #(
		// {{{
		parameter	IAW=8,	// The width of i_a, min width is 5
				IBW=12	// The width of i_b, can be anything
		// }}}
	) (
		// {{{
		input	wire			i_clk, i_ce,
		input	wire	[(IAW-1):0]	i_a_unsorted,
		input	wire	[(IBW-1):0]	i_b_unsorted,
		output	reg	[(AW+BW-1):0]	o_r

`ifdef	FORMAL
		, output	wire	[(IAW-1):0]	f_past_a_unsorted,
		output	wire	[(IBW-1):0]	f_past_b_unsorted
`endif
		// }}}
	);
			// The following three parameters should not be changed
			// by any implementation, but are based upon hardware
			// and the above values:
			// OW=IAW+IBW;	// The output width
		localparam	AW = (IAW<IBW) ? IAW : IBW;
                localparam	BW = (IAW<IBW) ? IBW : IAW;
	        localparam	IW=(AW+1)&(-2);	// Internal width of A
		localparam	LUTB=2;	// How many bits to mpy at once
		localparam	TLEN=(AW+(LUTB-1))/LUTB; // Rows in our tableau
	// Local declarations
	// {{{
	// Swap parameter order, so that AW <= BW -- for performance
	// reasons
	wire	[AW-1:0]	i_a;
	wire	[BW-1:0]	i_b;
	generate if (IAW <= IBW)
	begin : NO_PARAM_CHANGE_I
		assign i_a = i_a_unsorted;
		assign i_b = i_b_unsorted;
	end else begin : SWAP_PARAMETERS_I
		assign i_a = i_b_unsorted;
		assign i_b = i_a_unsorted;
	end endgenerate

	reg	[(IW-1):0]	u_a;
	reg	[(BW-1):0]	u_b;
	reg			sgn;

	reg	[(IW-1-2*(LUTB)):0]	r_a[0:(TLEN-3)];
	reg	[(BW-1):0]		r_b[0:(TLEN-3)];
	reg	[(TLEN-1):0]		r_s;
	reg	[(IW+BW-1):0]		acc[0:(TLEN-2)];
	genvar k;

	wire	[(BW+LUTB-1):0]	pr_a, pr_b;
	wire	[(IW+BW-1):0]	w_r;
	// }}}

	// First step:
	// Switch to unsigned arithmetic for our multiply, keeping track
	// of the along the way.  We'll then add the sign again later at
	// the end.
	//
	// If we were forced to stay within two's complement arithmetic,
	// taking the absolute value here would require an additional bit.
	// However, because our results are now unsigned, we can stay
	// within the number of bits given (for now).

	// u_a
	// {{{
	initial u_a = 0;
	generate if (IW > AW)
	begin : ABS_AND_ADD_BIT_TO_A
		always @(posedge i_clk)
		if (i_ce)
			u_a <= { 1'b0, (i_a[AW-1])?(-i_a):(i_a) };
	end else begin : ABS_A
		always @(posedge i_clk)
		if (i_ce)
			u_a <= (i_a[AW-1])?(-i_a):(i_a);
	end endgenerate
	// }}}

	// sgn, u_b
	// {{{
	initial sgn = 0;
	initial u_b = 0;
	always @(posedge i_clk)
	if (i_ce)
	begin : ABS_B
		u_b <= (i_b[BW-1])?(-i_b):(i_b);
		sgn <= i_a[AW-1] ^ i_b[BW-1];
	end
	// }}}

	//
	// Second step: First two 2xN products.
	//
	// Since we have no tableau of additions (yet), we can do both
	// of the first two rows at the same time and add them together.
	// For the next round, we'll then have a previous sum to accumulate
	// with new and subsequent product, and so only do one product at
	// a time can follow this--but the first clock can do two at a time.
	bimpy	#(BW) lmpy_0(i_clk,1'b0,i_ce,u_a[(  LUTB-1):   0], u_b, pr_a);
	bimpy	#(BW) lmpy_1(i_clk,1'b0,i_ce,u_a[(2*LUTB-1):LUTB], u_b, pr_b);

	// r_s, r_a[0], r_b[0]
	// {{{
	initial r_s    = 0;
	initial r_a[0] = 0;
	initial r_b[0] = 0;
	always @(posedge i_clk)
	if (i_ce)
	begin
		r_a[0] <= u_a[(IW-1):(2*LUTB)];
		r_b[0] <= u_b;
		r_s <= { r_s[(TLEN-2):0], sgn };
	end
	// }}}

	// acc[0]
	// {{{
	initial acc[0] = 0;
	always @(posedge i_clk) // One clk after p[0],p[1] become valid
	if (i_ce)
		acc[0] <= { {(IW-LUTB){1'b0}}, pr_a}
		  +{ {(IW-(2*LUTB)){1'b0}}, pr_b, {(LUTB){1'b0}} };
	// }}}

	// r_a[TLEN-3:1], r_b[TLEN-3:1]
	// {{{
	generate // Keep track of intermediate values, before multiplying them
	if (TLEN > 3) for(k=0; k<TLEN-3; k=k+1)
	begin : GENCOPIES

		initial r_a[k+1] = 0;
		initial r_b[k+1] = 0;
		always @(posedge i_clk)
		if (i_ce)
		begin
			r_a[k+1] <= { {(LUTB){1'b0}},
				r_a[k][(IW-1-(2*LUTB)):LUTB] };
			r_b[k+1] <= r_b[k];
		end
	end endgenerate
	// }}}

	// acc[TLEN-2:1]
	// {{{
	generate // The actual multiply and accumulate stage
	if (TLEN > 2) for(k=0; k<TLEN-2; k=k+1)
	begin : GENSTAGES
		wire	[(BW+LUTB-1):0] genp;

		// First, the multiply: 2-bits times BW bits
		bimpy #(BW)
		genmpy(i_clk,1'b0,i_ce,r_a[k][(LUTB-1):0],r_b[k], genp);

		// Then the accumulate step -- on the next clock
		initial acc[k+1] = 0;
		always @(posedge i_clk)
		if (i_ce)
			acc[k+1] <= acc[k] + {{(IW-LUTB*(k+3)){1'b0}},
				genp, {(LUTB*(k+2)){1'b0}} };
	end endgenerate
	// }}}

	assign	w_r = (r_s[TLEN-1]) ? (-acc[TLEN-2]) : acc[TLEN-2];

	// o_r
	// {{{
	initial o_r = 0;
	always @(posedge i_clk)
	if (i_ce)
		o_r <= w_r[(AW+BW-1):0];
	// }}}

	// Make Verilator happy
	// {{{
	generate if (IW > AW)
	begin : VUNUSED
		// verilator lint_off UNUSED
		wire	unused;
		assign	unused = &{ 1'b0, w_r[(IW+BW-1):(AW+BW)] };
		// verilator lint_on UNUSED
	end endgenerate
	// }}}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// Formal property section
// {{{
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
`ifdef	FORMAL
	reg	f_past_valid;
	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

`define	ASSERT	assert
`ifdef	LONGBIMPY

	always @(posedge i_clk)
	if (!$past(i_ce))
		assume(i_ce);

`endif

	reg	[AW-1:0]	f_past_a	[0:TLEN];
	reg	[BW-1:0]	f_past_b	[0:TLEN];
	reg	[TLEN+1:0]	f_sgn_a, f_sgn_b;

	initial	f_past_a[0] = 0;
	initial	f_past_b[0] = 0;
	initial	f_sgn_a = 0;
	initial	f_sgn_b = 0;
	always @(posedge i_clk)
	if (i_ce)
	begin
		f_past_a[0] <= u_a;
		f_past_b[0] <= u_b;
		f_sgn_a[0] <= i_a[AW-1];
		f_sgn_b[0] <= i_b[BW-1];
	end

	generate for(k=0; k<TLEN; k=k+1)
	begin
		initial	f_past_a[k+1] = 0;
		initial	f_past_b[k+1] = 0;
		initial	f_sgn_a[k+1] = 0;
		initial	f_sgn_b[k+1] = 0;
		always @(posedge i_clk)
		if (i_ce)
		begin
			f_past_a[k+1] <= f_past_a[k];
			f_past_b[k+1] <= f_past_b[k];

			f_sgn_a[k+1]  <= f_sgn_a[k];
			f_sgn_b[k+1]  <= f_sgn_b[k];
		end
	end endgenerate

	always @(posedge i_clk)
	if (i_ce)
	begin
		f_sgn_a[TLEN+1] <= f_sgn_a[TLEN];
		f_sgn_b[TLEN+1] <= f_sgn_b[TLEN];
	end

	always @(posedge i_clk)
	begin
		assert(sgn == (f_sgn_a[0] ^ f_sgn_b[0]));
		assert(r_s[TLEN-1:0] == (f_sgn_a[TLEN:1] ^ f_sgn_b[TLEN:1]));
		assert(r_s[TLEN-1:0] == (f_sgn_a[TLEN:1] ^ f_sgn_b[TLEN:1]));
	end

	always @(posedge i_clk)
	if ((f_past_valid)&&($past(i_ce)))
	begin
		if ($past(i_a)==0)
		begin
			`ASSERT(u_a == 0);
		end else if ($past(i_a[AW-1]) == 1'b0)
			`ASSERT(u_a == $past(i_a));

		if ($past(i_b)==0)
		begin
			`ASSERT(u_b == 0);
		end else if ($past(i_b[BW-1]) == 1'b0)
			`ASSERT(u_b == $past(i_b));
	end

	generate // Keep track of intermediate values, before multiplying them
	if (TLEN > 3) for(k=0; k<TLEN-3; k=k+1)
	begin : ASSERT_GENCOPY
		always @(posedge i_clk)
		if (i_ce)
		begin
			if (f_past_a[k]==0)
			begin
				`ASSERT(r_a[k] == 0);
			end else if (f_past_a[k]==1)
				`ASSERT(r_a[k] == 0);
			`ASSERT(r_b[k] == f_past_b[k]);
		end
	end endgenerate

	generate // The actual multiply and accumulate stage
	if (TLEN > 2) for(k=0; k<TLEN-2; k=k+1)
	begin : ASSERT_GENSTAGE
		always @(posedge i_clk)
		if ((f_past_valid)&&($past(i_ce)))
		begin
			if (f_past_a[k+1]==0)
				`ASSERT(acc[k] == 0);
			if (f_past_a[k+1]==1)
				`ASSERT(acc[k] == f_past_b[k+1]);
			if (f_past_b[k+1]==0)
				`ASSERT(acc[k] == 0);
			if (f_past_b[k+1]==1)
			begin
				`ASSERT(acc[k][(2*k)+3:0]
						== f_past_a[k+1][(2*k)+3:0]);
				`ASSERT(acc[k][(IW+BW-1):(2*k)+4] == 0);
			end
		end
	end endgenerate

	wire	[AW-1:0]	f_past_a_neg = - f_past_a[TLEN];
	wire	[BW-1:0]	f_past_b_neg = - f_past_b[TLEN];

	wire	[AW-1:0]	f_past_a_pos = f_past_a[TLEN][AW-1]
					? f_past_a_neg : f_past_a[TLEN];
	wire	[BW-1:0]	f_past_b_pos = f_past_b[TLEN][BW-1]
					? f_past_b_neg : f_past_b[TLEN];

	always @(posedge i_clk)
	if ((f_past_valid)&&($past(i_ce)))
	begin
		if ((f_past_a[TLEN]==0)||(f_past_b[TLEN]==0))
		begin
			`ASSERT(o_r == 0);
		end else if (f_past_a[TLEN]==1)
		begin
			if ((f_sgn_a[TLEN+1]^f_sgn_b[TLEN+1])==0)
			begin
				`ASSERT(o_r[BW-1:0] == f_past_b_pos[BW-1:0]);
				`ASSERT(o_r[AW+BW-1:BW] == 0);
			end else begin // if (f_sgn_b[TLEN+1]) begin
				`ASSERT(o_r[BW-1:0] == f_past_b_neg);
				`ASSERT(o_r[AW+BW-1:BW]
					== {(AW){f_past_b_neg[BW-1]}});
			end
		end else if (f_past_b[TLEN]==1)
		begin
			if ((f_sgn_a[TLEN+1] ^ f_sgn_b[TLEN+1])==0)
			begin
				`ASSERT(o_r[AW-1:0] == f_past_a_pos[AW-1:0]);
				`ASSERT(o_r[AW+BW-1:AW] == 0);
			end else begin
				`ASSERT(o_r[AW-1:0] == f_past_a_neg);
				`ASSERT(o_r[AW+BW-1:AW]
					== {(BW){f_past_a_neg[AW-1]}});
			end
		end else begin
			`ASSERT(o_r != 0);
			if (!o_r[AW+BW-1:0])
			begin
				`ASSERT((o_r[AW-1:0] != f_past_a[TLEN][AW-1:0])
					||(o_r[AW+BW-1:AW]!=0));
				`ASSERT((o_r[BW-1:0] != f_past_b[TLEN][BW-1:0])
					||(o_r[AW+BW-1:BW]!=0));
			end else begin
				`ASSERT((o_r[AW-1:0] != f_past_a_neg[AW-1:0])
					||(! (&o_r[AW+BW-1:AW])));
				`ASSERT((o_r[BW-1:0] != f_past_b_neg[BW-1:0])
					||(! (&o_r[AW+BW-1:BW]!=0)));
			end
		end
	end

	generate if (IAW <= IBW)
	begin : NO_PARAM_CHANGE_II
		assign f_past_a_unsorted = (!f_sgn_a[TLEN+1])
					? f_past_a[TLEN] : f_past_a_neg;
		assign f_past_b_unsorted = (!f_sgn_b[TLEN+1])
					? f_past_b[TLEN] : f_past_b_neg;
	end else begin : SWAP_PARAMETERS_II
		assign f_past_a_unsorted = (!f_sgn_b[TLEN+1])
					? f_past_b[TLEN] : f_past_b_neg;
		assign f_past_b_unsorted = (!f_sgn_a[TLEN+1])
					? f_past_a[TLEN] : f_past_a_neg;
	end endgenerate
`ifdef	BUTTERFLY
	// The following properties artificially restrict the inputs
	// to this long binary multiplier to only those values whose
	// absolute value is 0..7.  It is used by the formal proof of
	// the BUTTERFLY to artificially limit the scope of the proof.
	// By the time the butterfly sees this code, it will be known
	// that the long binary multiply works.  At issue will no longer
	// be whether or not this works, but rather whether it works in
	// context.  For that purpose, we'll need to check timing, not
	// results.  Checking against inputs of +/- 1 and 0 are perfect
	// for that task.  The below assumptions (yes they are assumptions
	// just go a little bit further.
	//
	// THEREFORE, THESE PROPERTIES ARE NOT NECESSARY TO PROVING THAT
	// THIS MODULE WORKS, AND THEY WILL INTERFERE WITH THAT PROOF.
	//
	// This just limits the proof for the butterfly, the parent.
	// module that calls this one
	//
	// Start by assuming that all inputs have an absolute value less
	// than eight.
	always @(*)
		assume(u_a[AW-1:3] == 0);
	always @(*)
		assume(u_b[BW-1:3] == 0);

	// If the inputs have these properties, then so too do many of
	// our internal values.  ASSERT therefore that we never get out
	// of bounds
	generate for(k=0; k<TLEN; k=k+1)
	begin
		always @(*)
		begin
			assert(f_past_a[k][AW-1:3] == 0);
			assert(f_past_b[k][BW-1:3] == 0);
		end
	end endgenerate

	generate for(k=0; k<TLEN-1; k=k+1)
	begin
		always @(*)
			assert(acc[k][IW+BW-1:6] == 0);
	end endgenerate

	generate for(k=0; k<TLEN-2; k=k+1)
	begin
		always @(*)
			assert(r_b[k][BW-1:3] == 0);
	end endgenerate
`endif	// BUTTERFLY
`endif	// FORMAL
// }}}
endmodule
////////////////////////////////////////////////////////////////////////////////
//
// Filename:	qtrstage.v
// {{{
// Project:	A General Purpose Pipelined FFT Implementation
//
// Purpose:	This file encapsulates the 4 point stage of a decimation in
//		frequency FFT.  This particular implementation is optimized
//	so that all of the multiplies are accomplished by additions and
//	multiplexers only.
//
// Operation:
// 	The operation of this stage is identical to the regular stages of
// 	the FFT (see them for details), with one additional and critical
// 	difference: this stage doesn't require any hardware multiplication.
// 	The multiplies within it may all be accomplished using additions and
// 	subtractions.
//
// 	Let's see how this is done.  Given x[n] and x[n+2], cause thats the
// 	stage we are working on, with i_sync true for x[0] being input,
// 	produce the output:
//
// 	y[n  ] = x[n] + x[n+2]
// 	y[n+2] = (x[n] - x[n+2]) * e^{-j2pi n/2}	(forward transform)
// 	       = (x[n] - x[n+2]) * -j^n
//
// 	y[n].r = x[n].r + x[n+2].r	(This is the easy part)
// 	y[n].i = x[n].i + x[n+2].i
//
// 	y[2].r = x[0].r - x[2].r
// 	y[2].i = x[0].i - x[2].i
//
// 	y[3].r =   (x[1].i - x[3].i)		(forward transform)
// 	y[3].i = - (x[1].r - x[3].r)
//
// 	y[3].r = - (x[1].i - x[3].i)		(inverse transform)
// 	y[3].i =   (x[1].r - x[3].r)		(INVERSE = 1)
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
module	qtrstage(i_clk, i_reset, i_ce, i_sync, i_data, o_data, o_sync);
	parameter	IWIDTH=16, OWIDTH=IWIDTH+1;
	parameter	LGWIDTH=8, INVERSE=0,SHIFT=0;
	input	wire				i_clk, i_reset, i_ce, i_sync;
	input	wire	[(2*IWIDTH-1):0]	i_data;
	output	reg	[(2*OWIDTH-1):0]	o_data;
	output	reg				o_sync;
	
	reg		wait_for_sync;
	reg	[2:0]	pipeline;

	reg	signed [(IWIDTH):0]	sum_r, sum_i, diff_r, diff_i;

	reg	[(2*OWIDTH-1):0]	ob_a;
	wire	[(2*OWIDTH-1):0]	ob_b;
	reg	[(OWIDTH-1):0]		ob_b_r, ob_b_i;
	assign	ob_b = { ob_b_r, ob_b_i };

	reg	[(LGWIDTH-1):0]		iaddr;
	reg	[(2*IWIDTH-1):0]	imem	[0:1];

	wire	signed	[(IWIDTH-1):0]	imem_r, imem_i;
	assign	imem_r = imem[1][(2*IWIDTH-1):(IWIDTH)];
	assign	imem_i = imem[1][(IWIDTH-1):0];

	wire	signed	[(IWIDTH-1):0]	i_data_r, i_data_i;
	assign	i_data_r = i_data[(2*IWIDTH-1):(IWIDTH)];
	assign	i_data_i = i_data[(IWIDTH-1):0];

	reg	[(2*OWIDTH-1):0]	omem [0:1];

	//
	// Round our output values down to OWIDTH bits
	//
	wire	signed	[(OWIDTH-1):0]	rnd_sum_r, rnd_sum_i,
			rnd_diff_r, rnd_diff_i, n_rnd_diff_r, n_rnd_diff_i;
	convround #(IWIDTH+1,OWIDTH,SHIFT)	do_rnd_sum_r(i_clk, i_ce,
				sum_r, rnd_sum_r);

	convround #(IWIDTH+1,OWIDTH,SHIFT)	do_rnd_sum_i(i_clk, i_ce,
				sum_i, rnd_sum_i);

	convround #(IWIDTH+1,OWIDTH,SHIFT)	do_rnd_diff_r(i_clk, i_ce,
				diff_r, rnd_diff_r);

	convround #(IWIDTH+1,OWIDTH,SHIFT)	do_rnd_diff_i(i_clk, i_ce,
				diff_i, rnd_diff_i);

	assign n_rnd_diff_r = - rnd_diff_r;
	assign n_rnd_diff_i = - rnd_diff_i;
	initial wait_for_sync = 1'b1;
	initial iaddr = 0;
	always @(posedge i_clk)
	if (i_reset)
	begin
		wait_for_sync <= 1'b1;
		iaddr <= 0;
	end else if ((i_ce)&&((!wait_for_sync)||(i_sync)))
	begin
		iaddr <= iaddr + 1'b1;
		wait_for_sync <= 1'b0;
	end

	always @(posedge i_clk)
	if (i_ce)
	begin
		imem[0] <= i_data;
		imem[1] <= imem[0];
	end


	// Note that we don't check on wait_for_sync or i_sync here.
	// Why not?  Because iaddr will always be zero until after the
	// first i_ce, so we are safe.
	initial pipeline = 3'h0;
	always	@(posedge i_clk)
	if (i_reset)
		pipeline <= 3'h0;
	else if (i_ce) // is our pipeline process full?  Which stages?
		pipeline <= { pipeline[1:0], iaddr[1] };

	// This is the pipeline[-1] stage, pipeline[0] will be set next.
	always	@(posedge i_clk)
	if ((i_ce)&&(iaddr[1]))
	begin
		sum_r  <= imem_r + i_data_r;
		sum_i  <= imem_i + i_data_i;
		diff_r <= imem_r - i_data_r;
		diff_i <= imem_i - i_data_i;
	end

	// pipeline[1] takes sum_x and diff_x and produces rnd_x

	// Now for pipeline[2].  We can actually do this at all i_ce
	// clock times, since nothing will listen unless pipeline[3]
	// on the next clock.  Thus, we simplify this logic and do
	// it independent of pipeline[2].
	always	@(posedge i_clk)
	if (i_ce)
	begin
		ob_a <= { rnd_sum_r, rnd_sum_i };
		// on Even, W = e^{-j2pi 1/4 0} = 1
		if (!iaddr[0])
		begin
			ob_b_r <= rnd_diff_r;
			ob_b_i <= rnd_diff_i;
		end else if (INVERSE==0) begin
			// on Odd, W = e^{-j2pi 1/4} = -j
			ob_b_r <=   rnd_diff_i;
			ob_b_i <= n_rnd_diff_r;
		end else begin
			// on Odd, W = e^{j2pi 1/4} = j
			ob_b_r <= n_rnd_diff_i;
			ob_b_i <=   rnd_diff_r;
		end
	end

	always	@(posedge i_clk)
	if (i_ce)
	begin // In sequence, clock = 3
		omem[0] <= ob_b;
		omem[1] <= omem[0];
		if (pipeline[2])
			o_data <= ob_a;
		else
			o_data <= omem[1];
	end

	initial	o_sync = 1'b0;
	always	@(posedge i_clk)
	if (i_reset)
		o_sync <= 1'b0;
	else if (i_ce)
		o_sync <= (iaddr[2:0] == 3'b101);

`ifdef	FORMAL
	// Formal declarations
	// {{{
	reg				f_past_valid;
	reg	signed [IWIDTH-1:0]	f_piped_real	[0:7];
	reg	signed [IWIDTH-1:0]	f_piped_imag	[0:7];
	reg				f_rsyncd;
	wire				f_syncd;
	reg	[1:0]			f_state;
	wire	signed [OWIDTH-1:0]	f_o_real, f_o_imag;
	// }}}

	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

`ifdef	QTRSTAGE
	always @(posedge i_clk)
		assume((i_ce)||($past(i_ce))||($past(i_ce,2)));
`endif

	// The below logic only works if the rounding stage does nothing
	initial	assert(IWIDTH+1 == OWIDTH);


	always @(posedge i_clk)
	if (i_ce)
	begin
		f_piped_real[0] <= i_data[2*IWIDTH-1:IWIDTH];
		f_piped_imag[0] <= i_data[  IWIDTH-1:0];

		f_piped_real[1] <= f_piped_real[0];
		f_piped_imag[1] <= f_piped_imag[0];

		f_piped_real[2] <= f_piped_real[1];
		f_piped_imag[2] <= f_piped_imag[1];

		f_piped_real[3] <= f_piped_real[2];
		f_piped_imag[3] <= f_piped_imag[2];

		f_piped_real[4] <= f_piped_real[3];
		f_piped_imag[4] <= f_piped_imag[3];

		f_piped_real[5] <= f_piped_real[4];
		f_piped_imag[5] <= f_piped_imag[4];

		f_piped_real[6] <= f_piped_real[5];
		f_piped_imag[6] <= f_piped_imag[5];

		f_piped_real[7] <= f_piped_real[6];
		f_piped_imag[7] <= f_piped_imag[6];
	end


	initial	f_rsyncd = 0;
	always @(posedge i_clk)
	if (i_reset)
		f_rsyncd <= 1'b0;
	else if (!f_rsyncd)
		f_rsyncd <= (o_sync);
	assign	f_syncd = (f_rsyncd)||(o_sync);


	initial	f_state = 0;
	always @(posedge i_clk)
	if (i_reset)
		f_state <= 0;
	else if ((i_ce)&&((!wait_for_sync)||(i_sync)))
		f_state <= f_state + 1;

	always @(*)
	if (f_state != 0)
		assume(!i_sync);

	always @(posedge i_clk)
		assert(f_state[1:0] == iaddr[1:0]);

	assign			f_o_real = o_data[2*OWIDTH-1:OWIDTH];
	assign			f_o_imag = o_data[  OWIDTH-1:0];

	always @(posedge i_clk)
	if (f_state == 2'b11)
	begin
		assume(f_piped_real[0] != 3'sb100);
		assume(f_piped_real[2] != 3'sb100);
		assert(sum_r  == f_piped_real[2] + f_piped_real[0]);
		assert(sum_i  == f_piped_imag[2] + f_piped_imag[0]);

		assert(diff_r == f_piped_real[2] - f_piped_real[0]);
		assert(diff_i == f_piped_imag[2] - f_piped_imag[0]);
	end

	always @(posedge i_clk)
	if ((f_state == 2'b00)&&((f_syncd)||(iaddr >= 4)))
	begin
		assert(rnd_sum_r  == f_piped_real[3]+f_piped_real[1]);
		assert(rnd_sum_i  == f_piped_imag[3]+f_piped_imag[1]);
		assert(rnd_diff_r == f_piped_real[3]-f_piped_real[1]);
		assert(rnd_diff_i == f_piped_imag[3]-f_piped_imag[1]);
	end

	always @(posedge i_clk)
	if ((f_state == 2'b10)&&(f_syncd))
	begin
		// assert(o_sync);
		assert(f_o_real == f_piped_real[5] + f_piped_real[3]);
		assert(f_o_imag == f_piped_imag[5] + f_piped_imag[3]);
	end

	always @(posedge i_clk)
	if ((f_state == 2'b11)&&(f_syncd))
	begin
		assert(!o_sync);
		assert(f_o_real == f_piped_real[5] + f_piped_real[3]);
		assert(f_o_imag == f_piped_imag[5] + f_piped_imag[3]);
	end

	always @(posedge i_clk)
	if ((f_state == 2'b00)&&(f_syncd))
	begin
		assert(!o_sync);
		assert(f_o_real == f_piped_real[7] - f_piped_real[5]);
		assert(f_o_imag == f_piped_imag[7] - f_piped_imag[5]);
	end

	always @(*)
	if ((iaddr[2:0] == 0)&&(!wait_for_sync))
		assume(i_sync);

	always @(*)
	if (wait_for_sync)
		assert((iaddr == 0)&&(f_state == 2'b00)&&(!o_sync)&&(!f_rsyncd));

	always @(posedge i_clk)
	if ((f_past_valid)&&($past(i_ce))&&($past(i_sync))&&(!$past(i_reset)))
		assert(!wait_for_sync);

	always @(posedge i_clk)
	if ((f_state == 2'b01)&&(f_syncd))
	begin
		assert(!o_sync);
		if (INVERSE)
		begin
			assert(f_o_real == -f_piped_imag[7]+f_piped_imag[5]);
			assert(f_o_imag ==  f_piped_real[7]-f_piped_real[5]);
		end else begin
			assert(f_o_real ==  f_piped_imag[7]-f_piped_imag[5]);
			assert(f_o_imag == -f_piped_real[7]+f_piped_real[5]);
		end
	end

`endif
endmodule
