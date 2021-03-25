module double_buffer
#( 
  parameter DATA_WIDTH = 64,
  parameter BANK_ADDR_WIDTH = 7,
  parameter [BANK_ADDR_WIDTH : 0] BANK_DEPTH = 128
)(
  input clk,
  input rst_n,
  input switch_banks,
  input ren,
  input [BANK_ADDR_WIDTH - 1 : 0] radr,
  output [DATA_WIDTH - 1 : 0] rdata,
  input wen,
  input [BANK_ADDR_WIDTH - 1 : 0] wadr,
  input [DATA_WIDTH - 1 : 0] wdata
);
  // Implement a double buffer with the dual-port SRAM (ram_sync_1r1w)
  // provided. This SRAM allows one read and one write every cycle. To read
  // from it you need to supply the address on radr and turn ren (read enable)
  // high. The read data will appear on rdata port after 1 cycle (1 cycle
  // latency). To write into the SRAM, provide write address and data on wadr
  // and wdata respectively and turn write enable (wen) high. 
  
  // You can implement both double buffer banks with one dual-port SRAM.
  // Think of one bank consisting of the first half of the addresses of the
  // SRAM, and the second bank consisting of the second half of the addresses.
  // If switch_banks is high, you need to switch the bank you are reading with
  // the bank you are writing on the clock edge.

  // Your code starts here
  reg active_write_bank_r;

  always @ (posedge clk) begin
    if (rst_n) begin
      if (switch_banks) begin
        active_write_bank_r <= !active_write_bank_r;
      end
    end else begin
      active_write_bank_r <= 1'b0;
    end
  end

  ram_sync_1r1w
  #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(BANK_ADDR_WIDTH + 1),
    .DEPTH(BANK_DEPTH*2)
  ) ram (
    .clk(clk),
    .wen(wen),
    .wadr(active_write_bank_r ? wadr + BANK_DEPTH : wadr),
    .wdata(wdata),
    .ren(ren),
    .radr(active_write_bank_r ? radr : radr + BANK_DEPTH),
    .rdata(rdata)
  );
  // Your code ends here
endmodule
