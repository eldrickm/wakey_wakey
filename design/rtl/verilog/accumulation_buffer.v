module accumulation_buffer
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
  input [DATA_WIDTH - 1 : 0] wdata,

  input ren_wb,
  input [BANK_ADDR_WIDTH - 1 : 0] radr_wb,
  output [DATA_WIDTH - 1 : 0] rdata_wb
);

  // Implement an accumulation buffer with the dual-port SRAM (ram_sync_1r1w)
  // provided. This SRAM allows one read and one write every cycle. To read
  // from it you need to supply the address on radr and turn ren (read enable)
  // high. The read data will appear on rdata port after 1 cycle (1 cycle
  // latency). To write into the SRAM, provide write address and data on wadr
  // and wdata respectively and turn write enable (wen) high. 
  
  // Accumulation buffer is similar to a double buffer, but one of its banks
  // has both a read port (ren, radr, rdata) and a write port (wen, wadr,
  // wdata). This bank is used by the systolic array to store partial sums and
  // then read them back out. The other bank has a read port only (ren_wb,
  // radr_wb, rdata_wb). This bank is used to read out the final output (after
  // accumulation is complete) and send it out of the chip. The reason for
  // adopting two banks is so that we can overlap systolic array processing,
  // and data transfer out of the accelerator (otherwise one of them will
  // stall while the other is taking place). Note: both srams will be 1r1w, 
  // but the logical operation will be as described above.

  // If switch_banks is high, you need to switch the functionality of the two
  // banks at the positive edge of the clock. That means, you will use the bank
  // you were previously using for data transfer out of the chip for systolic
  // array and vice versa.

  // Your code starts here
  wire [DATA_WIDTH - 1 : 0] rdata0;
  wire [DATA_WIDTH - 1 : 0] rdata1;

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
    .ADDR_WIDTH(BANK_ADDR_WIDTH),
    .DEPTH(BANK_DEPTH)
  ) ram0 (
    .clk(clk),
    .wen(active_write_bank_r ? 1'b0 : wen),
    .wadr(wadr),
    .wdata(wdata),
    .ren(active_write_bank_r ? ren_wb : ren),
    .radr(active_write_bank_r ? radr_wb : radr),
    .rdata(rdata0)
  );
  
  ram_sync_1r1w
  #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(BANK_ADDR_WIDTH),
    .DEPTH(BANK_DEPTH)
  ) ram1 (
    .clk(clk),
    .wen(active_write_bank_r ? wen : 1'b0),
    .wadr(wadr),
    .wdata(wdata),
    .ren(active_write_bank_r ? ren : ren_wb),
    .radr(active_write_bank_r ? radr : radr_wb),
    .rdata(rdata1)
  );

  assign rdata = active_write_bank_r ? rdata1 : rdata0;
  assign rdata_wb = active_write_bank_r ? rdata0 : rdata1;
  // Your code ends here
endmodule
