//-----------------------------------------------------------------------------
// SramUnit
//-----------------------------------------------------------------------------

module SramUnit #(
  parameter NUM_WMASKS = 4,
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 10
)(
  input clk, // clock
  input rst_n,
  input csb0, // active low chip select
  input csb1, // active low chip select
  input web0, // active low write control
  input [NUM_WMASKS-1:0] wmask0, // write mask
  input [ADDR_WIDTH-1:0] addr0,
  input [DATA_WIDTH-1:0] din0,
  output [DATA_WIDTH-1:0] dout0,
  output [DATA_WIDTH-1:0] dout1
);

  reg [ADDR_WIDTH-1:0]  addr1;

  sky130_sram_4kbyte_1rw1r_32x1024_8 sram(
    .clk0(clk),
    .csb0(csb0),
    .web0(web0),
    .wmask0(wmask0),
    .addr0(addr0),
    .din0(din0),
    .dout0(dout0),
    .clk1(clk),
    .csb1(csb1),
    .addr1(addr1),
    .dout1(dout1)
  );

  // Add a counter that is just circling through all the addresses
  always @ (posedge clk) begin
    if (rst_n) begin
      if (!csb1) begin
        addr1 <= addr1 + 1;
      end
    end else begin
      addr1 <= 0;
    end
  end

endmodule
