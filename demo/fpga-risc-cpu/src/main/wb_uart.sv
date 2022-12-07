`default_nettype none `timescale 1ns / 1ps

`ifndef UART
`define UART

`include "fifo.sv"

module wb_uart #(
    parameter CLOCK_RATE_HZ = 100_000_000,
    parameter BAUD_RATE = 115_200
) (
    // Wishbone interface
    input  wire        i_clk,
    input  wire        i_rst,
    input  wire        i_we,
    input  wire        i_stb,
    input  wire        i_cyc,
    input  wire [31:0] i_data,
    output wire [31:0] o_data,
    output wire        o_stall,
    output reg         o_ack,

    // UART
    output wire ser_tx,
    input  wire ser_rx
);
  localparam [31:0] CLOCKS_PER_BAUD = CLOCK_RATE_HZ / BAUD_RATE;

  // RECV states
  reg [3:0] recv_state = 0;
  reg [31:0] recv_divcnt = 0;
  reg [7:0] recv_pattern = 0;
  reg [7:0] recv_buf_data = 0;
  reg recv_buf_valid = 0;

  // SEND states
  reg [9:0] send_pattern = ~0;
  reg [3:0] send_bitcnt = 0;
  reg [31:0] send_divcnt = 0;
  reg send_dummy = 1;
  wire send_idle = (send_bitcnt == 4'b0 && !send_dummy);

  // SEND FIFO
  wire send_fifo_full;
  wire send_fifo_empty;
  reg [7:0] send_fifo_data;
  reg send_fifo_data_available = 0;

  // RECV FIFO
  wire recv_fifo_empty;
  wire [7:0] recv_fifo_data;

  assign o_stall = (i_we && send_fifo_full);

  always @(posedge i_clk) o_ack <= (i_cyc && i_stb);

  assign o_data = recv_fifo_empty ? ~0 : {24'b0, recv_fifo_data};

  // RECV
  wire recv_fifo_read = !i_we && i_stb && !o_ack;
  /* verilator lint_off PINCONNECTEMPTY */
  fifo #(
    .WIDTH(8),
    .DEPTH(128)
  ) recv_fifo (
      .i_data(recv_buf_data),
      .i_rst (i_rst),
      .i_clk (i_clk),
      .i_we  (recv_buf_valid),

      .i_re  (recv_fifo_read),
      .o_data(recv_fifo_data),

      .o_full (),
      .o_empty(recv_fifo_empty)
  );
  /* verilator lint_on PINCONNECTEMPTY */

  always @(posedge i_clk) begin
    recv_divcnt <= recv_divcnt + 1;
    recv_buf_valid <= 0;
    case (recv_state)
      0: begin
        if (!ser_rx) recv_state <= 1;
        recv_divcnt <= 0;
      end
      1: begin
        if ((2 * recv_divcnt) > CLOCKS_PER_BAUD) begin
          recv_state  <= 2;
          recv_divcnt <= 0;
        end
      end
      10: begin
        if (recv_divcnt > CLOCKS_PER_BAUD) begin
          recv_buf_data <= recv_pattern;
          recv_buf_valid <= 1;
          recv_state <= 0;
        end
      end
      default: begin
        if (recv_divcnt > CLOCKS_PER_BAUD) begin
          recv_pattern <= {ser_rx, recv_pattern[7:1]};
          recv_state   <= recv_state + 1;
          recv_divcnt  <= 0;
        end
      end
    endcase
    if (i_rst) begin
      recv_state <= 0;
      recv_divcnt <= 0;
      recv_pattern <= 0;
      recv_buf_data <= 0;
      recv_buf_valid <= 0;
    end
  end

  // SEND

  // When FIFO is ready to send
  wire send_fifo_req_read = !send_fifo_empty && send_idle && !send_fifo_data_available;

  always @(posedge i_clk) begin
    // notify data available from FIFO
    send_fifo_data_available <= 0;
    if (send_fifo_req_read) begin
      send_fifo_data_available <= 1;
    end
  end

  wire send_fifo_write = i_we && i_stb && !o_ack;
  /* verilator lint_off PINCONNECTEMPTY */
  fifo #(
      .WIDTH(8),
      .DEPTH(16)
  ) send_fifo (
      .i_data(i_data[7:0]),
      .i_rst (i_rst),
      .i_clk (i_clk),
      .i_we  (send_fifo_write),

      .i_re  (send_fifo_req_read),
      .o_data(send_fifo_data),

      .o_full (send_fifo_full),
      .o_empty(send_fifo_empty)
  );
  /* verilator lint_on PINCONNECTEMPTY */
  assign ser_tx = send_pattern[0];

  always @(posedge i_clk) begin
    send_divcnt <= send_divcnt + 1;
    if (send_dummy && (send_bitcnt == 4'b0)) begin
      send_pattern <= ~0;
      send_bitcnt  <= 15;
      send_divcnt  <= 0;
      send_dummy   <= 0;
    end else if (send_fifo_data_available) begin
      send_pattern <= {1'b1, send_fifo_data, 1'b0};
      send_bitcnt  <= 10;
      send_divcnt  <= 0;
    end else if (send_divcnt > CLOCKS_PER_BAUD && (send_bitcnt != 4'b0)) begin
      send_pattern <= {1'b1, send_pattern[9:1]};
      send_bitcnt  <= send_bitcnt - 1;
      send_divcnt  <= 0;
    end
    if (i_rst) begin
      send_pattern <= ~0;
      send_bitcnt  <= 0;
      send_divcnt  <= 0;
      send_dummy   <= 1;
    end
  end

  // verilator lint_off UNUSED
  wire [23:0] unused;
  assign unused = {i_data[31:8]};
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

  // We never stall on read
  always @(*) if (!i_we) assert (!o_stall);

  // ack only one time
  always @(posedge i_clk)
    assert (o_ack == (f_past_valid && $past(
        i_stb
    ) && !$past(
        o_ack
    ) && $past(
        i_cyc
    )));

  // TODO recv && send
`endif

endmodule

`endif
