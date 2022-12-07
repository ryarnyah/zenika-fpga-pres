`ifndef SLOW_CLK
`define SLOW_CLK

module slow_clk (
    input  logic i_CLK,
    output logic i_clk
);
  reg [27:0] counter = 28'd0;
  parameter DIVISOR = 28'd100_000;
  // The frequency of the output clk_out
  //  = The frequency of the input clk_in divided by DIVISOR
  // For example: Fclk_in = 50Mhz, if you want to get 1Hz signal to blink LEDs
  // You will modify the DIVISOR parameter value to 28'd50.000.000
  // Then the frequency of the output clk_out = 50Mhz/50.000.000 = 1Hz
  always @(posedge i_CLK) begin
    counter <= counter + 28'd1;
    if (counter >= (DIVISOR - 1)) counter <= 28'd0;
    i_clk <= (counter < DIVISOR / 2) ? 1'b1 : 1'b0;
  end
endmodule

`endif
