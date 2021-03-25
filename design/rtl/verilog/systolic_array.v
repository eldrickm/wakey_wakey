module systolic_array
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

  // This module contains two components: a systolic array of MAC units, and
  // registers that skew the weights going into the systolic array. The skew
  // registers are already instantiated below, and you should not need to
  // modify this code. The instructions for creating the systolic array are in
  // the next comment --- this is the part that you must complete. 
  
  // Weight skew registers
  
  // There are two sets of skew registers, each instantiated in a triangular
  // pattern as shown in the homework pdf. The reason we want to skew the
  // weight is because we want to perfectly overlap the loading of the weights
  // into the systolic array with streaming inputs into the array, and avoid
  // any dead time between two passes through the systolic array that need
  // different weights (at the end of one pass over an OX0*OY0 tile).
 
  // The first set (weight_in_skew_registers_inst) skews the weight values.
  // Their input is the module input weight_in, and their output is
  // weight_in_skewed, which feeds into the systolic array. weight_en controls
  // whether the weights move forward through these registers in any cycle.
  
  wire signed [WEIGHT_WIDTH - 1 : 0] weight_in_skewed [ARRAY_WIDTH - 1 : 0];

  skew_registers
  #(
    .DATA_WIDTH(WEIGHT_WIDTH),
    .N(ARRAY_WIDTH)
  ) weight_in_skew_registers_inst (
    .clk(clk),
    .rst_n(rst_n),
    .en(weight_en),
    .din(weight_in),
    .dout(weight_in_skewed)
  );

  // The second set of registers skews the weight write enable (weight_wen) ---
  // the signal that indicates whether one should update the weight sitting in
  // the MAC unit's weight register. Since we skew the weight values, we must
  // also skew the weight write enables by the same amount.

  wire weight_wen_w [ARRAY_WIDTH - 1 : 0][ARRAY_HEIGHT - 1 : 0]; 
  genvar x, y; 
  
  generate
    for (x = 0; x < ARRAY_WIDTH; x = x + 1) begin: row_reg
      for (y = 0; y < ARRAY_HEIGHT; y = y + 1) begin: col_reg
        if (x == 0) begin
          assign weight_wen_w[x][y] = weight_wen[y];
        end else begin
          en_reg #(.DATA_WIDTH(1)) skew_r (
            .clk(clk),
            .rst_n(rst_n),
            .en(weight_en),
            .din(weight_wen_w[x - 1][y]),
            .dout(weight_wen_w[x][y])
          );
        end
      end
    end
  endgenerate
  
  // Systolic array
  
  // Generate a systolic array of MAC units, as shown in the figure in the
  // homework pdf. ifmap_in is the vector of inputs that enters into the left
  // column of MACs, and propagates towards the right. weight_in_skewed
  // (generated in the code above) is the vector of weights that enters
  // into the top row of MACs, and propagates downwards. weight_wen_w[x][y]
  // (also generated in the code above) is the weight enable (the signal that
  // indicates that the weight should be put into the weight register) of the
  // (x, y)th MAC unit. ofmap_in is the vector of partial sums that enters
  // into the top row of MACs and gets accumulated on as it moves downwards.
  // ofmap_out is the vector of partial sums that is the output of last row of
  // MACs, and it also the output of the systolic array.

  // You should make sure that the systolic array is parameterized with
  // respect to ARRAY_WIDTH and ARRAY_HEIGHT. To create this you can use the
  // `generate` statement (the code above for skew registers shows an example
  // for how to use this statement). The en input is the enable that goes into
  // all the MAC units. This module has no registers (state) other that the
  // skew registers already instantiated above. The connections between the
  // MAC units are purely wiring, so make sure you do not introduce any extra
  // state.

  // Your code starts here

  wire signed [IFMAP_WIDTH - 1 : 0] ifmap_w [ARRAY_WIDTH : 0][ARRAY_HEIGHT - 1 : 0];
  wire signed [OFMAP_WIDTH - 1 : 0] ofmap_w [ARRAY_WIDTH - 1 : 0][ARRAY_HEIGHT : 0];

  generate
    for (x = 0; x < ARRAY_WIDTH; x = x + 1) begin: row
      for (y = 0; y < ARRAY_HEIGHT; y = y + 1) begin: col
        if (x == 0) begin
          assign ifmap_w[x][y] = ifmap_in[y];
        end else begin
          
        end
        if (y == 0) begin
          assign ofmap_w[x][y] = ofmap_in[x];
        end
        if (y == ARRAY_HEIGHT - 1) begin
          assign ofmap_out[x] = ofmap_w[x][y + 1];
        end
        mac #(
          .IFMAP_WIDTH(IFMAP_WIDTH),
          .WEIGHT_WIDTH(WEIGHT_WIDTH),
          .OFMAP_WIDTH(OFMAP_WIDTH)
        ) mac_inst (
          .clk(clk),
          .rst_n(rst_n),
          .en(en),
          .weight_wen(weight_wen_w[x][y]),
          .ifmap_in(ifmap_w[x][y]),
          .weight_in(weight_in_skewed[x]),
          .ofmap_in(ofmap_w[x][y]),
          .ifmap_out(ifmap_w[x + 1][y]),
          .ofmap_out(ofmap_w[x][y + 1])
        );
      end
    end
  endgenerate
  // Your code ends here
endmodule
