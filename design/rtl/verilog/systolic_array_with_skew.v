module systolic_array_with_skew
#( 
  parameter IFMAP_WIDTH = 16,
  parameter WEIGHT_WIDTH = 16,
  parameter OFMAP_WIDTH = 32,
  parameter ARRAY_HEIGHT = 4,
  parameter ARRAY_WIDTH = 4
)(
  input clk,
  input rst_n,
  input en,
  input weight_en,
  input weight_wen [ARRAY_HEIGHT - 1 : 0],
  input signed [IFMAP_WIDTH - 1 : 0] ifmap_in [ARRAY_HEIGHT - 1 : 0],
  input signed [WEIGHT_WIDTH - 1 : 0] weight_in [ARRAY_WIDTH - 1 : 0],
  input signed [OFMAP_WIDTH - 1 : 0] ofmap_in [ARRAY_WIDTH - 1 : 0],
  output signed [OFMAP_WIDTH - 1 : 0] ofmap_out [ARRAY_WIDTH - 1 : 0]
);
  
  wire signed [IFMAP_WIDTH - 1 : 0] ifmap [ARRAY_HEIGHT - 1 : 0];
  wire signed [OFMAP_WIDTH - 1 : 0] ofmap [ARRAY_WIDTH - 1 : 0];
  wire signed [OFMAP_WIDTH - 1 : 0] ofmap_reversed [ARRAY_WIDTH - 1 : 0];
  wire signed [OFMAP_WIDTH - 1 : 0] ofmap_out_reversed [ARRAY_WIDTH - 1 : 0];

  skew_registers
  #(
    .DATA_WIDTH(IFMAP_WIDTH),
    .N(ARRAY_HEIGHT)
  ) ifmap_skew_registers (
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .din(ifmap_in),
    .dout(ifmap)
  );
 
  systolic_array
  #( 
    .IFMAP_WIDTH(IFMAP_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .OFMAP_WIDTH(OFMAP_WIDTH),
    .ARRAY_HEIGHT(ARRAY_HEIGHT),
    .ARRAY_WIDTH(ARRAY_WIDTH)
  ) systolic_array_inst (
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .weight_en(weight_en),
    .weight_wen(weight_wen),
    .ifmap_in(ifmap),
    .weight_in(weight_in),
    .ofmap_in(ofmap_in),
    .ofmap_out(ofmap)
  );

  skew_registers
  #(
    .DATA_WIDTH(OFMAP_WIDTH),
    .N(ARRAY_WIDTH)
  ) ofmap_skew_registers (
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .din(ofmap_reversed),
    .dout(ofmap_out_reversed)
  );

  genvar x;
  generate
    for (x = 0; x < ARRAY_WIDTH; x++) begin: reverse 
      // Because the 0th entry in the array must be delayed the most which is
      // opposite from the way the skew resgiters are generated, so we just
      // flip the inputs to them
      assign ofmap_reversed[x] = ofmap[ARRAY_WIDTH - 1 - x];
      assign ofmap_out[x] = ofmap_out_reversed[ARRAY_WIDTH - 1 - x];
    end
  endgenerate

endmodule
