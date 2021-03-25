module ifmap_radr_gen
#( 
  parameter BANK_ADDR_WIDTH = 8
)(
  input clk,
  input rst_n,
  input adr_en,
  output [BANK_ADDR_WIDTH - 1 : 0] adr,
  input config_en,
  input [BANK_ADDR_WIDTH*8 - 1 : 0] config_data
);

  reg [BANK_ADDR_WIDTH - 1 : 0] config_OX0, config_OY0, config_FX, config_FY, 
    config_STRIDE, config_IX0, config_IY0, config_IC1;
  
  always @ (posedge clk) begin
    if (rst_n) begin
      if (config_en) begin
        {config_OX0, config_OY0, config_FX, config_FY, config_STRIDE, 
         config_IX0, config_IY0, config_IC1} <= config_data; 
      end
    end else begin
      {config_OX0, config_OY0, config_FX, config_FY, config_STRIDE, 
       config_IX0, config_IY0, config_IC1} <= 0;
    end
  end
  
  // This is the read address generator for the input double buffer. It is
  // more complex than the sequential address generator because there are
  // overlaps between the input tiles that are read out.  We have already
  // instantiated for you all the configuration registers that will hold the
  // various tiling parameters (OX0, OY0, FX, FY, STRIDE, IX0, IY0, IC1, OC1).
  // You need to generate address (adr) for the input buffer in the same
  // sequence as the C++ tiled convolution that you implemented. Make sure you
  // increment/step the address generator only when adr_en is high. Also reset
  // all registers when rst_n is low.  
  
  // Your code starts here
 
  reg [BANK_ADDR_WIDTH - 1 : 0] ox0, oy0, fx, fy, ic1;
  wire [BANK_ADDR_WIDTH - 1 : 0] ix0, iy0, adrc;
  
  always @ (posedge clk) begin
    if (rst_n) begin
      if (adr_en) begin
        ox0 <=  (ox0 == config_OX0 - 1) ? 
          0 : ox0 + 1;
        oy0 <=  (ox0 == config_OX0 - 1) ? 
          ((oy0 == config_OY0 - 1) ? 0 : oy0 + 1) : oy0;
        fx  <= ((ox0 == config_OX0 - 1) && (oy0 == config_OY0 - 1)) ? 
          ((fx == config_FX - 1) ? 0 : fx + 1) : fx;
        fy  <= ((ox0 == config_OX0 - 1) && (oy0 == config_OY0 - 1) && (fx == config_FX - 1)) ? 
          ((fy == config_FY - 1) ? 0 : fy + 1) : fy;
        ic1 <= ((ox0 == config_OX0 - 1) && (oy0 == config_OY0 - 1) && (fx == config_FX - 1) && (fy == config_FY - 1)) ? 
          ((ic1 == config_IC1 - 1) ? 0 : ic1 + 1) : ic1;
      end
    end else begin
      ox0 <= 0;
      oy0 <= 0;
      fx <= 0;
      fy <= 0;
      ic1 <= 0;
    end
  end

  assign ix0 = config_STRIDE * ox0 + fx;
  assign iy0 = config_STRIDE * oy0 + fy;
  assign adrc = ic1 * config_IX0 * config_IY0 + iy0 * config_IX0 + ix0;

  assign adr = adrc[BANK_ADDR_WIDTH - 1 : 0];
  // Your code ends here
endmodule
