`define BSV_ASSIGNMENT_DELAY #0

module fifo
#(
  parameter DATA_WIDTH = 16,
  parameter FIFO_DEPTH = 3, // You will mostly use depth 2 FIFOs
  parameter COUNTER_WIDTH = 1 
)(
  input clk,
  input rst_n,
  input [DATA_WIDTH - 1 : 0] din,
  input enq,
  output full_n,
  output [DATA_WIDTH - 1 : 0] dout,
  input deq,
  output empty_n,
  input clr
);

  SizedFIFO #(
    .p1width(DATA_WIDTH),
    .p2depth(FIFO_DEPTH),
    .p3cntr_width(COUNTER_WIDTH)) fifo_inst (
    .CLK(clk), 
    .RST(rst_n), // By default this is a synchronous active low reset, but it can be made asynchronous by defining BSV_ASYNC_RESET in SizedFIFO, and it can be made active high by defining BSV_POSITIVE_RESET in SizedFIFO.v
    .D_IN(din), 
    .ENQ(enq), 
    .FULL_N(full_n), 
    .D_OUT(dout), 
    .DEQ(deq), 
    .EMPTY_N(empty_n), 
    .CLR(clr)
  );

endmodule
