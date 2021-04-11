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
