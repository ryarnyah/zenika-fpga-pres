`default_nettype none `timescale 1ns / 1ps

`ifndef LED_BAR
`define LED_BAR

module wb_led_bar #(
    parameter LED_NUMBER = 16
) (
    input  wire                    i_clk,
    input  wire                    i_rst,
    input  wire                    i_we,
    input  wire                    i_stb,
    input  wire                    i_cyc,
    input  wire [LED_NUMBER - 1:0] i_data,
    output reg  [LED_NUMBER - 1:0] o_data,
    output wire                    o_stall,
    output reg                     o_ack,
    // Led bar
    output wire [LED_NUMBER - 1:0] o_leds
);

  reg [LED_NUMBER-1:0] leds = {LED_NUMBER{1'b0}};
  initial o_ack = 0;

  wire write = i_we && i_stb;
  wire read = !i_we && i_stb;

  always @(posedge i_clk) begin
    if (write) begin
      leds <= i_data;
    end else if (read) begin
      o_data <= leds;
    end
    if (i_rst) begin
      leds <= {LED_NUMBER{1'b0}};
    end 
  end

  assign o_leds = leds;

  // Only ack one time
  always @(posedge i_clk) o_ack <= (i_cyc && i_stb);

  assign o_stall = 1'b0;

`ifdef FORMAL

  // Assume we start from a reset condition
  initial assert (i_rst);
  initial assume (!i_cyc);
  initial assume (!i_stb);
  initial assume (!o_ack);

  reg f_past_valid;
  initial f_past_valid = 1'b0;
  always @(posedge i_clk) f_past_valid <= 1'b1;

  always @(*) if (!f_past_valid) assume (i_rst);
  always @(*) if (!f_past_valid) assume (!i_cyc);

  // STB can only be true if CYC is also true
  always @(*) if (i_stb) assume (i_cyc);

  // Within any series of STB/requests, the direction of the request
  // may not change.
  always @(posedge i_clk)
    if ((f_past_valid) && ($past(i_stb)) && (i_stb))
      assume (i_we == $past(i_we));

  // If CYC was low on the last clock, then both ACK and ERR should be
  // low on this clock.
  always @(posedge i_clk)
    if ((f_past_valid) && (!$past(i_cyc)) && (!i_cyc)) begin
      assert (!o_ack);
      // Stall may still be true--such as when we are not
      // selected at some arbiter between us and the slave
    end

  // stb is only asserted when !o_ack
  always @(*) if (o_ack) assume (!i_stb);

  // We never stall
  always @(*) assert (!o_stall);

  // ack only one time
  always @(posedge i_clk)
    assert (o_ack == (f_past_valid && $past(
        i_stb
    ) && !$past(
        o_ack
    ) && $past(
        i_cyc
    )));

  // leds are off when reset is asserted
  always @(posedge i_clk) if (f_past_valid && $past(i_rst)) assert (leds == {LED_NUMBER{1'b0}});

  // leds are updated when write is enable
  always @(posedge i_clk)
    if (f_past_valid && !$past(i_rst) && $past(i_we) && $past(i_stb) && !$past(o_ack))
      assert ($past(i_data) == leds);

  // leds are read when read is enable
  always @(posedge i_clk)
    if (f_past_valid && !$past(i_rst) && !$past(i_we) && $past(i_stb) && !$past(o_ack))
      assert ($past(leds) == o_data);

`endif

endmodule

`endif
