/*
 * Vector Multiplied
 */

module vec_mul #(
    parameter INPUT_BW = 8,
    parameter OUTPUT_BW = 8,
    parameter VECTOR_SIZE = 13
) (
    input clk_i,
    input rstn_i,

    input [VECTOR_SIZE * INPUT_BW - 1 : 0] data1_i,
    input valid1_i,
    input last1_i,
    output ready1_o,

    input [VECTOR_SIZE * INPUT_BW - 1 : 0] data2_i,
    input valid2_i,
    input last2_i,
    output ready2_o,

    output [VECTOR_SIZE * INPUT_BW - 1 : 0] data_o,
    output valid_o,
    output last_o,
    input  ready_i
);

    assign data_o = data1_i * data2_i;
    assign valid_o = valid1_i & valid2_i;
    assign last_o = last1_i | last2_i;
    assign ready1_o = ready_i;
    assign ready2_o = ready_i;

    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("vec_mul.vcd");
      $dumpvars (0, vec_mul);
      #1;
    end
    `endif
endmodule
