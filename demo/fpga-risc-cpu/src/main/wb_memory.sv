`default_nettype none `timescale 1ns / 1ps

`ifndef WB_MEMORY
`define WB_MEMORY

module wb_memory #(
    parameter BYTES = 32,
    parameter MASK  = 4,
    parameter WIDTH = 2 << 12
) (
    // Input Clock
    input  wire               i_clk,
    // Reset
    input  wire               i_rst,
    // Indicates that a valid bus cycle is in progress.
    input  wire               i_cyc,
    // Indicate that the SLAVE is selected
    input  wire               i_stb,
    // Indicates whether the current local bus cycle is a READ (0) or WRITE (1) cycle
    input  wire               i_we,
    // Write / Read at addr
    input  wire [BYTES - 1:0] i_addr,
    // Data to write
    input  wire [BYTES - 1:0] i_data,
    // what byte is selectd
    input  wire [ MASK - 1:0] i_sel,
    // Did we need another clock cycle?
    output wire               o_stall,
    // indicates the termination of a normal bus cycle (we just finish)
    output reg                o_ack,
    // Readed data (contain current state)
    output reg  [BYTES - 1:0] o_data
);

  localparam WORDSIZE = BYTES / MASK;
  reg [BYTES - 1:0] MEM[0:WIDTH-1];

`ifdef BENCH
  `include "riscv_assembly.taskssv"
  integer L0_ = 12;
`endif
  initial begin
`ifdef BENCH
    integer i;
    for (i = 0; i < WIDTH; i = i + 1) MEM[i] = 32'b0;
    // x10 will be used for leds
    LI(gp, 32'h0200_0000);
    ADD(x12, x0, x0);
    ADDI(x2, x0, 69);
    Label(L0_);
    LW(x12, gp, 8);
    BNE(x12, x2, LabelRef(L0_));
    SW(x12, gp, 8);
    EBREAK();  // Note: index 100 (word address)
    //     corresponds to 
    // address 400 (byte address)
    MEM[100] = {8'h0, 8'h0, 8'h0, 8'h0};
    MEM[101] = {8'h0, 8'h0, 8'h0, 8'h0};
    MEM[102] = {8'h0, 8'h0, 8'h0, 8'h0};
    MEM[103] = {8'h0, 8'h0, 8'h0, 8'h0};
`else
    $readmemh("firmware.hex", MEM);
`endif
  end

  wire [31:0] addr;
  assign addr = {2'b0, i_addr[31:2]};

  generate
    genvar i;
    for (i = 0; i < MASK; i = i + 1) begin
      always @(posedge i_clk) begin
        if (i_we && i_stb && i_sel[i]) begin
          MEM[addr][i*WORDSIZE+WORDSIZE-1:i*WORDSIZE] <= i_data[i*WORDSIZE+WORDSIZE-1:i*WORDSIZE];
        end
      end
    end
  endgenerate

  always @(posedge i_clk) begin
    if (!i_we && i_stb) begin
      o_data <= MEM[addr];
    end
  end

  initial o_data = 0;
  initial o_ack = 0;
  always @(posedge i_clk) o_ack <= (i_cyc && i_stb);

  assign o_stall = 1'b0;

  // verilator lint_off UNUSED
  wire [21:0] unused;
  assign unused = {i_rst, i_addr[1:0], addr[31:13]};
  // verilator lint_on UNUSED

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
`endif

endmodule

`endif
