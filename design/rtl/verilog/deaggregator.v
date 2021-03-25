module deaggregator
#(
  parameter DATA_WIDTH = 16,
  parameter FETCH_WIDTH = 4
)
(
  input clk,
  input rst_n,
  input [FETCH_WIDTH*DATA_WIDTH - 1 : 0] sender_data, // from db
  input sender_empty_n,
  output sender_deq,
  output [DATA_WIDTH - 1 : 0] receiver_data, // to interface fifo
  input receiver_full_n,
  output receiver_enq
);

  localparam COUNTER_WIDTH = $clog2(FETCH_WIDTH);
  reg [COUNTER_WIDTH - 1 : 0] select_r;
  wire [DATA_WIDTH - 1 : 0] fifo_dout [FETCH_WIDTH - 1 : 0]; 
  wire fifo_empty_n [FETCH_WIDTH - 1 : 0];
  wire fifo_deq [FETCH_WIDTH - 1 : 0];

  reg sender_deq_r;
  wire fifo_full_n [FETCH_WIDTH - 1 : 0];
  reg [1 : 0] fifo_elements_r; 
  // 1:0 because FIFO has depth 3

  genvar i;
  generate
    for (i = 0; i < FETCH_WIDTH; i++) begin: instantiate_fifos
      fifo
      #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(3),
        .COUNTER_WIDTH(1)
      ) fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .din(sender_data[(i + 1)*DATA_WIDTH - 1 : i*DATA_WIDTH]),
        .enq(sender_deq_r), // enq must be 1 cycle after sender is dequeued 
        .full_n(fifo_full_n[i]),
        .dout(fifo_dout[i]),
        .deq(fifo_deq[i]),
        .empty_n(fifo_empty_n[i]),
        .clr(1'b0)
      );
   
      assign fifo_deq[i] = (select_r == i) ? (rst_n && receiver_full_n && fifo_empty_n[i]) : 0;

    end
  endgenerate
  
  // Output side
  assign receiver_data = fifo_dout[select_r];
  assign receiver_enq = rst_n && receiver_full_n && fifo_empty_n[select_r];
  
  always @ (posedge clk) begin
    if (rst_n) begin
      if (receiver_enq) begin
        select_r <= select_r + 1;
      end
    end else begin
      select_r <= 0;
    end
  end
 
  // Input side
  // If the double buffer is not empty and there is space in all the FIFOs
  // send a read enable to the double buffer. However, finding out if there is
  // space in FIFOs is tricky because there is a one cycle delay is for
  // getting the data, and FIFO may have an outstanding request, so we can't
  // use the fifo_full_n signal directly but have to keep track of how many
  // elements there are in the FIFO taking into account the outstanding
  // request. In fact, since FIFOs are dequeued in order we are okay as long
  // we have a counter that keeps track of the last FIFO.
  always @ (posedge clk) begin
    if (rst_n) begin
      if (sender_deq && (!fifo_deq[FETCH_WIDTH - 1])) begin
        // Increment
        fifo_elements_r <= fifo_elements_r + 1;
      end else if (!sender_deq && fifo_deq[FETCH_WIDTH - 1]) begin
        // Decrement
        fifo_elements_r <= fifo_elements_r - 1;
      end
    end else begin
      fifo_elements_r <= 0;
    end
  end

  assign sender_deq = sender_empty_n && (fifo_elements_r < 3);

  // The data will come back in the next cycle so buffer sender_deq
  always @ (posedge clk) begin
    if (rst_n) begin
      sender_deq_r <= sender_deq;
    end else begin
      sender_deq_r <= 0;
    end
  end

endmodule
