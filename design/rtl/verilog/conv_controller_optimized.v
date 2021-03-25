// States

`define STATE_WIDTH 2
`define IDLE 0
`define INITIAL_FILL 1
`define INNER_LOOP 2
`define RESET_INNER_LOOP 3

module conv_controller
#(
  parameter IFMAP_WIDTH = 16,
  parameter WEIGHT_WIDTH = 16,
  parameter OFMAP_WIDTH = 32,
  
  parameter ARRAY_WIDTH = 4,
  parameter ARRAY_HEIGHT = 4,
  
  parameter WEIGHT_BANK_ADDR_WIDTH = 8,
  parameter WEIGHT_BANK_DEPTH = 256,
  parameter IFMAP_BANK_ADDR_WIDTH = 8,
  parameter IFMAP_BANK_DEPTH = 256,
  parameter OFMAP_BANK_ADDR_WIDTH = 8,
  parameter OFMAP_BANK_DEPTH = 256,

  parameter CONFIG_ADDR_WIDTH = 8,
  parameter CONFIG_DATA_WIDTH = 8,
  
  parameter NUM_CONFIGS = 35
)
(

  input clk,
  input rst_n,
  
  input [CONFIG_ADDR_WIDTH + CONFIG_DATA_WIDTH - 1 : 0] params_fifo_dout,
  output params_fifo_deq,
  input params_fifo_empty_n,

  output reg config_en,
  
  output [WEIGHT_BANK_ADDR_WIDTH - 1 : 0] weight_max_adr_c,
  output [IFMAP_BANK_ADDR_WIDTH - 1 : 0] ifmap_max_wadr_c,
  output [OFMAP_BANK_ADDR_WIDTH - 1 : 0] ofmap_max_adr_c,
  output [IFMAP_BANK_ADDR_WIDTH - 1 : 0] OX0_c, 
  output [IFMAP_BANK_ADDR_WIDTH - 1 : 0] OY0_c, 
  output [IFMAP_BANK_ADDR_WIDTH - 1 : 0] FX_c, 
  output [IFMAP_BANK_ADDR_WIDTH - 1 : 0] FY_c, 
  output [IFMAP_BANK_ADDR_WIDTH - 1 : 0] STRIDE_c, 
  output [IFMAP_BANK_ADDR_WIDTH - 1 : 0] IX0_c, 
  output [IFMAP_BANK_ADDR_WIDTH - 1 : 0] IY0_c, 
  output [IFMAP_BANK_ADDR_WIDTH - 1 : 0] IC1_c,
  
  input weight_wen,
  input ifmap_wen, 
  input ofmap_wb_ren,
  
  output reg weight_ren,
  output reg ifmap_ren,
  output reg ofmap_wen,
  output reg ofmap_ren,

  output wire weight_db_full_n,
  output wire ifmap_db_full_n,
  output reg ofmap_db_empty_n,

  output reg weight_switch_banks,
  output reg ifmap_switch_banks,
  output reg ofmap_switch_banks,
  
  output reg ofmap_skew_en, 
  output reg ofmap_initialize,
  
  output reg systolic_array_weight_wen [ARRAY_HEIGHT - 1 : 0],
  output reg systolic_array_weight_en,
  output reg systolic_array_en
);
  
  localparam COUNTER_WIDTH = 32; // FIXME: Arbitrary bitwidth
  
  integer i;
  
  // ---------------------------------------------------------------------------
  // Configuration registers
  // ---------------------------------------------------------------------------
  
  reg [CONFIG_DATA_WIDTH - 1 : 0] config_r [NUM_CONFIGS - 1 : 0];
  
  wire [COUNTER_WIDTH - 1 : 0] OC1_c;
  wire [COUNTER_WIDTH - 1 : 0] IC1_FY_FX_OY0_OX0_c;
  wire [COUNTER_WIDTH - 1 : 0] OY0_OX0_c;

  // ---------------------------------------------------------------------------
  // Registers for keeping track of the state of the accelerator
  // ---------------------------------------------------------------------------
  
  reg [`STATE_WIDTH - 1 : 0] state_r;
  
  reg [IFMAP_BANK_ADDR_WIDTH + 1 - 1 : 0] ifmap_wadr_r;
  reg [OFMAP_BANK_ADDR_WIDTH + 1 - 1 : 0] ofmap_wbadr_r;
  reg [WEIGHT_BANK_ADDR_WIDTH + 1 - 1 : 0] weight_wadr_r;

  reg [COUNTER_WIDTH - 1 : 0] loop_counter_r;
  reg [COUNTER_WIDTH - 1 : 0] ic1_fy_fx_r; 
  reg [COUNTER_WIDTH - 1 : 0] oc1_r;

  wire [COUNTER_WIDTH - 1 : 0] ic1_fy_fx_OY0_OX0;
  assign ic1_fy_fx_OY0_OX0 = ic1_fy_fx_r * OY0_OX0_c;

  assign weight_db_full_n = (weight_wadr_r <= weight_max_adr_c);
  assign ifmap_db_full_n = (ifmap_wadr_r <= ifmap_max_wadr_c);

  // Connections to the interface FIFO supplying the configuration parameters.

  wire [CONFIG_ADDR_WIDTH - 1 : 0] config_adr;
  wire [CONFIG_DATA_WIDTH - 1 : 0] config_data;
  assign config_adr = params_fifo_dout[CONFIG_ADDR_WIDTH + CONFIG_DATA_WIDTH - 1 : CONFIG_DATA_WIDTH];
  assign config_data = params_fifo_dout[CONFIG_DATA_WIDTH - 1 : 0];
  assign params_fifo_deq = params_fifo_empty_n && (state_r == `IDLE);

  always @ (posedge clk) begin
    if (rst_n) begin
      
      // If we are in the IDLE state, and if there is data in parameters FIFO,
      // use it to configure the registers in the accelerator. When we
      // receive a special config_adr it means configuration is done and we
      // can go to the INITIAL_FILL state.
      
      if (state_r == `IDLE) begin
        if (params_fifo_empty_n) begin
          if (config_adr == NUM_CONFIGS - 1) begin 
            
            // This is the last address in the configuration stream, this should
            // be kept consistent with the testbench if more configuration
            // registers are added.
            
            config_en <= 1;
            state_r <= `INITIAL_FILL; 
          end else begin
            config_r[config_adr] <= config_data;
          end
        end
      end 
      
      // Once we have configured the accelerator, we need to fill the first
      // ifmap tile and weight tile in the ifmap double buffer and the weight
      // double buffer respectively. This is done in the INITIAL_FILL state.
      
      else if (state_r == `INITIAL_FILL) begin
        
        config_en <= 0;
        
        // These counters are probably replicated in address generators, and 
        // could be reused from there to save area.
        
        ifmap_wadr_r <= ((ifmap_wen) && (ifmap_wadr_r <= ifmap_max_wadr_c)) ? 
			    ifmap_wadr_r + 1 : ifmap_wadr_r;
        weight_wadr_r <= ((weight_wen) && (weight_wadr_r <= weight_max_adr_c)) ? 
			    weight_wadr_r + 1 : weight_wadr_r;
        
        // Once we have written the complete ifmap and weight tiles in the
        // respective double buffers, we switch banks and start execution in
        // the INNER_LOOP state.
        
        if ((ifmap_wadr_r  == ifmap_max_wadr_c + 1) && 
            (weight_wadr_r == weight_max_adr_c + 1)) begin
          weight_switch_banks <= 1;
          ifmap_switch_banks <= 1;
          ifmap_wadr_r <= 0;
          weight_wadr_r <= 0;
          state_r <= `INNER_LOOP;
        end
      end 

      // We are in the INNER_LOOP state for the majority of the execution. In
      // this state we iterate over the OX0, OY0, FX, FY and IC1 loops (and
      // ICO and OC0 loops that are unrolled) to complete the processing of
      // one OX0*OY0*OC0 ofmap tile. In parallel we also write in the next
      // ifmap tile and the next weight tile into the respective double
      // buffers.

      else if (state_r == `INNER_LOOP) begin
       
        // ---------------------------------------------------------------------
        //  Data transfer between the double buffers and the accelerator 
        //  interface
        // ---------------------------------------------------------------------
 
        // Write the next ifmap tile and weight tile to the double buffers.

        weight_switch_banks <= 0;
        ifmap_switch_banks <= 0;
        ofmap_switch_banks <= 0;
        
        ifmap_wadr_r <= ((ifmap_wen) && (ifmap_wadr_r <= ifmap_max_wadr_c)) ? 
          ifmap_wadr_r + 1 : ifmap_wadr_r;
        weight_wadr_r <= ((weight_wen) && (weight_wadr_r <= weight_max_adr_c)) ? 
          weight_wadr_r + 1 : weight_wadr_r;
       
        // Send the completed ofmap tile from the accumulation buffer out of
        // the accelerator. ofmap_db_empty_n signal tells the ofmap
        // deaggregator that the accumulation buffer has data that needs to be
        // read out. ofmap_wbadr_r is a local register that gets initialized
        // to OX0*OY0 at the end of the processing of one ofmap tile.
        // ofmap_wb_ren signal is coming from the deaggregator that is high
        // every time an entry is read out of the accumualation buffer. We use
        // this to decrement ofmap_wbadr_r to keep track of how many entries
        // are left in the accumulation buffer. When it becomes zero, we raise
        // the accumulation buffer empty flag (set ofmap_db_empty_n to 0), to
        // stop the deaggregator from reading further.

        if ((ofmap_wbadr_r > 0) && !ofmap_switch_banks) 
          ofmap_db_empty_n <= 1; 
        else 
          ofmap_db_empty_n <= 0;
        
        if (ofmap_wb_ren && (ofmap_wbadr_r > 0)) 
          ofmap_wbadr_r <= ofmap_wbadr_r - 1;


        // ---------------------------------------------------------------------
        //  Data transfer between the double buffers and the systolic array
        // ---------------------------------------------------------------------
 
        // We use a couple of counters to keep track of where we are in the
        // inner loops.  The counter loop_counter_r increments on every cycle
        // in the inner loop. We use it to keep track of which cycle we are
        // at. The counter ic1_fy_fx_r increments after each OX0*OY0 tile of
        // partial sums.

        // FIXME: There is an assumption here that the tile size OX0*OY0 is
        // larger that approximately the array height plus few cycles. That is
        // not true for an FC layer since for that OX0*OY0 is 1. So this code
        // does not work correctly for FC layers.
       
        loop_counter_r <= loop_counter_r + 1;
        
        ic1_fy_fx_r <= (loop_counter_r == ic1_fy_fx_OY0_OX0 + OY0_OX0_c - 1) ? 
          ic1_fy_fx_r + 1 : ic1_fy_fx_r;

        // Enable the weight double buffer. This has to be done for
        // ARRAY_HEIGHT cycles, and in that time OC0*IC0 weights would be
        // read out. We repeat this everytime we increment ic1_fx_fy_r.

        if ((loop_counter_r >= ic1_fy_fx_OY0_OX0) && 
            (loop_counter_r <= ic1_fy_fx_OY0_OX0 + ARRAY_HEIGHT - 1) &&
            (loop_counter_r <= IC1_FY_FX_OY0_OX0_c - OY0_OX0_c + ARRAY_HEIGHT)) begin
          weight_ren <= 1;
        end else begin
          weight_ren <= 0;
        end
    
        // One cycle after the weight is read, put it into the array (the 
        // double buffer has a one cycle latency).
        
        if ((loop_counter_r >= ic1_fy_fx_OY0_OX0 + 1) && 
            (loop_counter_r <= ic1_fy_fx_OY0_OX0 + ARRAY_HEIGHT - 1 + 1) &&
            (loop_counter_r <= IC1_FY_FX_OY0_OX0_c - OY0_OX0_c + ARRAY_HEIGHT + 1)) begin
          for(i = 0; i < ARRAY_HEIGHT; i++) begin
            if (i == loop_counter_r - ic1_fy_fx_OY0_OX0 - 1) begin
              systolic_array_weight_wen[i] <= 1;
            end else begin
              systolic_array_weight_wen[i] <= 0;
            end
          end
        end else begin
          for(i = 0; i < ARRAY_HEIGHT; i++) systolic_array_weight_wen[i] <= 0;
        end
       
        // Push the weights through the skew registers.
        
        if ((loop_counter_r >= ic1_fy_fx_OY0_OX0 + 1) && 
            (loop_counter_r <= ic1_fy_fx_OY0_OX0 + ARRAY_HEIGHT - 1 + 1 + ARRAY_WIDTH - 1) &&
            (loop_counter_r <= IC1_FY_FX_OY0_OX0_c - OY0_OX0_c + ARRAY_HEIGHT + 1 + ARRAY_WIDTH - 1)) begin
          systolic_array_weight_en <= 1;
        end else begin
          systolic_array_weight_en <= 0;
        end
 
        // One cycle after enabling the weight double buffer, enable input double buffer.

        if ((loop_counter_r >= 1) && (loop_counter_r <= IC1_FY_FX_OY0_OX0_c)) begin 
          ifmap_ren <= 1;
        end else begin
          ifmap_ren <= 0;
        end
        
        // At the next cycle, input is available and weight is available in
        // MAC's weight register, so enable the systolic array.
        
        if ((loop_counter_r >= 2) && 
            (loop_counter_r <= IC1_FY_FX_OY0_OX0_c + 1 + 2*ARRAY_HEIGHT - 1)) begin
          systolic_array_en <= 1;
        end else begin
          systolic_array_en <= 0;
        end
        
        // After ARRAY_HEIGHT registers going down the systolic array we have
        // a partial sum available which goes into ARRAY_HEIGHT - 1 skew registers, 
        // and 3 cycles are wasted at the beginning, so the output will be ready 
        // at ARRAY_HEIGHT + ARRAY_HEIGHT - 1 + 3 - 1th cycle.

        if ((loop_counter_r >= 2*ARRAY_HEIGHT + 1) && 
            (loop_counter_r <= IC1_FY_FX_OY0_OX0_c + 2*ARRAY_HEIGHT)) begin 
          ofmap_wen <= 1;
        end else begin
          ofmap_wen <= 0;
        end

        if ((loop_counter_r >= OY0_OX0_c + 2) && 
            (loop_counter_r <= IC1_FY_FX_OY0_OX0_c + 1)) begin
          ofmap_initialize <= 0;
        end else begin
          ofmap_initialize <= 1;
        end

        if ((loop_counter_r >= OY0_OX0_c + 1) && 
            (loop_counter_r <= IC1_FY_FX_OY0_OX0_c)) begin
          ofmap_ren <= 1;
        end else begin
          ofmap_ren <= 0;
        end

        // This is equal to ofmap_ren for the most part, except during the
        // last iteration when skewing of zeros must happen even if you are
        // not reading partial sums to flush outputs from the pipeline.

        if ((loop_counter_r >= OY0_OX0_c + 1) && 
            (loop_counter_r <= IC1_FY_FX_OY0_OX0_c + OY0_OX0_c - 1)) begin
          ofmap_skew_en <= 1;
        end else begin
          ofmap_skew_en <= 0;
        end

        // Check for the fullness of the input buffer only if you are in the
        // last OC1 iteration

        if (!weight_db_full_n && !systolic_array_en && 
          !ofmap_db_empty_n && (loop_counter_r >= IC1_FY_FX_OY0_OX0_c)) begin

          if (oc1_r == OC1_c - 1) begin
            if (!ifmap_db_full_n) begin
              state_r <= `RESET_INNER_LOOP;
            end
          end else begin
            state_r <= `RESET_INNER_LOOP;
          end
        end

      end else if (state_r == `RESET_INNER_LOOP) begin
        
        // We come into this state after we are done with the inner 
        // ic0, oc0, ix0, iy0, ic1 loops, so we have one OC0*OX0*OY0 output 
        // block created. At this point we must switch the weight buffer and
        // the output buffer, but we must wait until we are done with the oc1
        // loop to switch the input buffer.
        
        oc1_r <= (oc1_r == OC1_c - 1) ? 0 : oc1_r + 1;
        if (oc1_r == OC1_c - 1) begin 
          ifmap_switch_banks <= 1;
          ifmap_wadr_r <= 0;
        end else begin
          ifmap_wadr_r <= ((ifmap_wen) && (ifmap_wadr_r <= ifmap_max_wadr_c)) ? 
            ifmap_wadr_r + 1 : ifmap_wadr_r;
        end

        weight_switch_banks <= 1;
        weight_wadr_r <= 0;
        
        ofmap_switch_banks <= 1;
        ofmap_wbadr_r <= OY0_OX0_c;

        loop_counter_r <= 0;
        ic1_fy_fx_r <= 0;
        state_r <= `INNER_LOOP;
      end

    // Reset

    end else begin 
      
      // Reset internal state
      state_r <= `IDLE;

      // Reset counters for double buffer writers 
      ifmap_wadr_r <= 0;
      weight_wadr_r <= 0;
      ofmap_wbadr_r <= 0;
      
      // Reset counters for double buffer readers
      loop_counter_r <= 0;
      ic1_fy_fx_r <= 0;
      oc1_r <= 0;

      // Reset outputs of the controller
      weight_ren <= 0;
      ifmap_ren <= 0;
      ofmap_wen <= 0;
      ofmap_ren <= 0;

      weight_switch_banks <= 0;
      ifmap_switch_banks <= 0;
      ofmap_switch_banks <= 0;      

      ofmap_initialize <= 1;
      ofmap_skew_en <= 0;

      ofmap_db_empty_n <= 0;

      for(i = 0; i < ARRAY_HEIGHT; i++) systolic_array_weight_wen[i] <= 0;
      systolic_array_weight_en <= 0;
      systolic_array_en <= 0;

    end

  end

  // This code assigns values to the configuration registers. It is a little
  // brittle --- you will have to manually change how many config_r's to use
  // depending on the width. Selects the lower bits out of 16 bits by default.

  assign weight_max_adr_c    = {config_r[ 1], config_r[ 0]};
  assign ifmap_max_wadr_c    = {config_r[ 3], config_r[ 2]};
  assign ofmap_max_adr_c     = {config_r[ 5], config_r[ 4]};
  assign OX0_c               = {config_r[ 7], config_r[ 6]};
  assign OY0_c               = {config_r[ 9], config_r[ 8]};
  assign FX_c                = {config_r[11], config_r[10]};
  assign FY_c                = {config_r[13], config_r[12]};
  assign STRIDE_c            = {config_r[15], config_r[14]};
  assign IX0_c               = {config_r[17], config_r[16]};
  assign IY0_c               = {config_r[19], config_r[18]};
  assign IC1_c               = {config_r[21], config_r[20]};
  assign OC1_c               = {config_r[25], config_r[24], config_r[23], config_r[22]};
  assign IC1_FY_FX_OY0_OX0_c = {config_r[29], config_r[28], config_r[27], config_r[26]};
  assign OY0_OX0_c           = {config_r[33], config_r[32], config_r[31], config_r[30]};
 
endmodule
