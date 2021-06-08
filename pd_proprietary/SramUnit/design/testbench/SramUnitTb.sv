`define CLK_PERIOD 20
`define ASSIGNMENT_DELAY 5
`define FINISH_TIME 200
`define NUM_WMASKS 4
`define DATA_WIDTH 32
`define ADDR_WIDTH 10

module SramUnitTb;
  
  reg clk;
  reg rst_n;
  reg csb0; // active low chip select
  reg csb1; // active low chip select
  reg web0; // active low write control
  reg [`NUM_WMASKS-1:0] wmask0; // write mask
  reg [`ADDR_WIDTH-1:0] addr0;
  reg [`DATA_WIDTH-1:0] din0;
  wire [`DATA_WIDTH-1:0] dout0;
  wire [`DATA_WIDTH-1:0] dout1;
  supply0 VSS;
  supply1 VDD;


  always #(`CLK_PERIOD/2) clk =~clk;
 
  SramUnit #(
    .NUM_WMASKS(`NUM_WMASKS),
    .DATA_WIDTH(`DATA_WIDTH),
    .ADDR_WIDTH(`ADDR_WIDTH)
  ) SramUnit_inst (
    .clk(clk),
    .rst_n(rst_n),
    .csb0(csb0),
    .csb1(csb1),
    .web0(web0),
    .wmask0(wmask0),
    .addr0(addr0),
    .din0(din0),
    .dout0(dout0),
    .dout1(dout1)
    `ifdef USE_POWER_PINS
    ,
    .VSS(VSS),
    .VDD(VDD)
    `endif
  );

  initial begin
    clk <= 0;
    rst_n <= 0; // Reset the address
    csb0 <= 1; // SRAM port 0 not enabled
    csb1 <= 1; // SRAM port 1 not enabled
    web0 <= 1;
    addr0 <= 0;
    din0 <= 0;
    #(1*`CLK_PERIOD) rst_n <= 1;
    // Write into addr 0
    csb0 <= 0;
    web0 <= 0;
    addr0 <= 0;
    din0 <= 32'haaaaaaaa;
    wmask0 <= 4'b1111;
    #(1*`CLK_PERIOD) //csb0 <= 1;
    //csb1 <= 0;
    web0 <= 1; // Read
    #(1*`CLK_PERIOD) //csb1 <= 1;
    csb0 <= 1;
    #(`CLK_PERIOD/2) $display("dout0 = %h", dout0);
    // FIXME: current version of Icarus (that we use for GLS) does not support assertions
    //assert(dout0 == 32'haaaaaaaa);
  end

  initial begin
    $dumpfile("run.vcd");
    $dumpvars(0, SramUnitTb);
    #(`FINISH_TIME);
    $finish(2);
  end

  `ifdef GL
  initial begin
    $sdf_annotate("inputs/design.sdf", SramUnit_inst);
  end
  `endif

endmodule 
