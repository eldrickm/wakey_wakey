module ram_sync_1r1w
#(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 7,
  parameter DEPTH = 128
)(
  input clk,
  input wen,
  input [ADDR_WIDTH - 1 : 0] wadr,
  input [DATA_WIDTH - 1 : 0] wdata,
  input ren,
  input [ADDR_WIDTH - 1 : 0] radr,
  output [DATA_WIDTH - 1 : 0] rdata
);
  
  /*
  // synopsys translate_off
  reg [DATA_WIDTH - 1 : 0] rdata_reg;
  
  reg [DATA_WIDTH - 1 : 0] mem [DEPTH - 1 : 0];
  
  always @(posedge clk) begin
    if (wen) begin
      mem[wadr] <= wdata; // write port
    end
    if (ren) begin
      rdata_reg <= mem[radr]; // read port
    end
  end

  assign rdata = rdata_reg;
  
  // synopsys translate_on
  */
  
  genvar x, y; 
  
  generate
    if (DEPTH >= 1024) begin

      wire [DATA_WIDTH - 1 : 0] rdata_w [DEPTH/1024 - 1 : 0];
      reg  [ADDR_WIDTH - 1 : 0] radr_r;

      always @ (posedge clk) begin
        radr_r <= radr;
      end

      for (x = 0; x < DATA_WIDTH/32; x = x + 1) begin: width_macro
        for (y = 0; y < DEPTH/1024; y = y + 1) begin: depth_macro
          sky130_sram_4kbyte_1rw1r_32x1024_8 sram (
            .clk0(clk),
            .csb0(~(wen && (wadr[ADDR_WIDTH - 1 : 10] == y))),
            .web0(~(wen && (wadr[ADDR_WIDTH - 1 : 10] == y))), // And wadr in range
            .wmask0(4'hF),
            .addr0(wadr[9:0]),
            .din0(wdata[32*(x+1)-1 : 32*x]),
            .dout0(),
            .clk1(clk),
            .csb1(~(ren && (radr[ADDR_WIDTH - 1 : 10] == y))), // And radr in range
            .addr1(radr[9:0]),
            .dout1(rdata_w[y][32*(x+1)-1 : 32*x])
          );
        end
      end

      assign rdata = rdata_w[radr_r[ADDR_WIDTH - 1 : 10]];

    end else if (DEPTH == 256) begin

      for (x = 0; x < DATA_WIDTH/32; x = x + 1) begin: width_macro
        sky130_sram_1kbyte_1rw1r_32x256_8 sram (
          .clk0(clk),
          .csb0(~wen),
          .web0(~wen), // And wadr in range
          .wmask0(4'hF),
          .addr0(wadr),
          .din0(wdata[32*(x+1)-1 : 32*x]),
          .dout0(),
          .clk1(clk),
          .csb1(~ren), // And radr in range
          .addr1(radr),
          .dout1(rdata[32*(x+1)-1 : 32*x])
        );
      end
      
    end
  endgenerate
  
endmodule
