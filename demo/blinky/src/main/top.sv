`ifndef TOP
`define TOP

`include "slow_clk.sv"

module top (
    input logic CLK,
    input logic RST,
    output logic [15:0] LEDS
);
    /* Slow down current clock. */
    logic clk;
    slow_clk slow_clk(
        .i_CLK(CLK),
        .i_clk(clk)
    );

    logic [15:0] counter = 0;
    always @(posedge clk) begin
        counter <= counter + 1;
        if (RST) counter <= 0;
    end
    assign LEDS = counter;

`ifdef FORMAL
  // Assume we start from a reset condition
  initial assume (RST);

  reg f_past_valid;
  initial f_past_valid = 1'b0;
  always @(posedge clk) f_past_valid <= 1'b1;

`endif

endmodule

`endif