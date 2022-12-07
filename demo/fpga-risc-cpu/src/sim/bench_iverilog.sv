`include "../main/soc.sv"

module ClkDivider(
        input logic clock_in,
        output logic clock_out
    );
    reg[27:0] counter=28'd0;
    parameter DIVISOR = 28'd2;
    // The frequency of the output clk_out
    //  = The frequency of the input clk_in divided by DIVISOR
    // For example: Fclk_in = 50Mhz, if you want to get 1Hz signal to blink LEDs
    // You will modify the DIVISOR parameter value to 28'd50.000.000
    // Then the frequency of the output clk_out = 50Mhz/50.000.000 = 1Hz
    always @(posedge clock_in)
    begin
        counter <= counter + 28'd1;
        if(counter>=(DIVISOR-1))
            counter <= 28'd0;
        clock_out <= (counter<DIVISOR/2)?1'b1:1'b0;
    end
endmodule

module Bench();
    logic CLK;
    logic RESET = 0;
    logic RXD = 1'b0;
    reg TXD;
    logic [15:0] LEDS;

    logic clk;
    ClkDivider CD (
        .clock_in(CLK),
        .clock_out(clk)
    );

    soc uut(
            .clk(clk),
            .RESET(RESET),
            .RXD(RXD),
            .TXD(TXD),
            .LEDS(LEDS)
        );

    initial begin
        CLK = 0;
        forever begin
            #1 CLK = ~CLK;
        end
    end

    always @(posedge clk) begin
        $display("LEDS [%b]", LEDS);
    end
endmodule

