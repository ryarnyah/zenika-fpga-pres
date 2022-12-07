`default_nettype none `timescale 1ns / 1ps

`ifndef SOC
`define SOC

`include "instr.svh"
`include "wb_memory.sv"
`include "processor.sv"
`include "wb_uart.sv"
`include "wb_mux.sv"
`include "wb_led_bar.sv"

module soc #(
  parameter CLOCK_RATE_HZ = 100_000_000,
  parameter BAUD_RATE = 115_200
) (
    input  wire clk,
    input  wire RESET,
    input  wire RXD,
    output wire TXD,

    output wire [15:0] LEDS
);

  wire resetn;
  assign resetn = RESET;

  // WB
  wire [31:0] wb_o_master_addr;
  wire [31:0] wb_i_master_data;
  wire [31:0] wb_o_master_data;
  wire [ 3:0] wb_o_master_sel;
  wire        wb_i_master_stall;
  wire        wb_i_master_ack;
  wire        wb_o_master_cyc;
  wire        wb_o_master_stb;
  wire        wb_o_master_we;

  // MEM
  wire        wb_i_mem_stb;
  wire        wb_o_mem_stall;
  wire        wb_o_mem_ack;
  wire [31:0] wb_o_mem_data;
  wire [31:0] wb_i_mem_addr;
  wire [31:0] wb_i_mem_data;
  wire        wb_i_mem_cyc;
  wire        wb_i_mem_we;
  wire [ 3:0] wb_i_mem_sel;

  // UART
  wire        wb_i_uart_stb;
  wire        wb_o_uart_stall;
  wire        wb_o_uart_ack;
  wire [31:0] wb_o_uart_data;
  wire [31:0] wb_i_uart_addr;
  wire [31:0] wb_i_uart_data;
  wire        wb_i_uart_cyc;
  wire        wb_i_uart_we;
  wire [ 3:0] wb_i_uart_sel;

  // LEDS
  wire        wb_i_led_stb;
  wire        wb_o_led_stall;
  wire        wb_o_led_ack;
  wire [15:0] wb_o_led_data;
  wire [15:0] wb_o_led_leds;
  wire [31:0] wb_i_led_addr;
  wire [31:0] wb_i_led_data;
  wire        wb_i_led_cyc;
  wire        wb_i_led_we;
  wire [ 3:0] wb_i_led_sel;

  wb_led_bar LED_BAR (
      .i_clk(clk),
      .i_rst(resetn),
      .o_data(wb_o_led_data),
      .i_data(wb_i_led_data[15:0]),
      .i_cyc(wb_i_led_cyc),
      .i_stb(wb_i_led_stb),
      .i_we(wb_i_led_we),
      .o_stall(wb_o_led_stall),
      .o_ack(wb_o_led_ack),
      .o_leds(wb_o_led_leds)
  );

  wb_uart #(
       .CLOCK_RATE_HZ(CLOCK_RATE_HZ),
       .BAUD_RATE(BAUD_RATE)
  ) UART (
      .i_clk(clk),
      .i_rst(resetn),
      .o_data(wb_o_uart_data),
      .i_data(wb_i_uart_data),
      .i_cyc(wb_i_uart_cyc),
      .i_stb(wb_i_uart_stb),
      .i_we(wb_i_uart_we),
      .o_stall(wb_o_uart_stall),
      .o_ack(wb_o_uart_ack),
      .ser_rx(RXD),
      .ser_tx(TXD)
  );

  wb_memory RAM (
      .i_clk(clk),
      .i_rst(resetn),
      .i_addr(wb_i_mem_addr),
      .o_data(wb_o_mem_data),
      .i_data(wb_i_mem_data),
      .i_sel(wb_i_mem_sel),
      .i_cyc(wb_i_mem_cyc),
      .i_stb(wb_i_mem_stb),
      .i_we(wb_i_mem_we),
      .o_stall(wb_o_mem_stall),
      .o_ack(wb_o_mem_ack)
  );

  // CPU
  processor CPU (
      .i_clk(clk),
      .i_rst(resetn),
      .o_addr(wb_o_master_addr),
      .i_data(wb_i_master_data),
      .o_data(wb_o_master_data),
      .o_sel(wb_o_master_sel),
      .i_stall(wb_i_master_stall),
      .i_ack(wb_i_master_ack),
      .o_cyc(wb_o_master_cyc),
      .o_stb(wb_o_master_stb),
      .o_we(wb_o_master_we)
  );

  // Uart
  wire led_sel = wb_o_master_addr == 32'h0200_0004;
  wire uart_sel = wb_o_master_addr == 32'h0200_0008;
  wire mem_sel = (!led_sel && !uart_sel);
  wb_mux mux (
      // Master
      .o_master_addr(wb_o_master_addr),
      .i_master_data(wb_i_master_data),
      .o_master_data(wb_o_master_data),
      .o_master_sel(wb_o_master_sel),
      .i_master_stall(wb_i_master_stall),
      .i_master_ack(wb_i_master_ack),
      .o_master_cyc(wb_o_master_cyc),
      .o_master_stb(wb_o_master_stb),
      .o_master_we(wb_o_master_we),

      // Slaves
      .i_slave_cyc({wb_i_mem_cyc, wb_i_led_cyc, wb_i_uart_cyc}),
      .i_slave_stb({wb_i_mem_stb, wb_i_led_stb, wb_i_uart_stb}),
      .i_slave_we({wb_i_mem_we, wb_i_led_we, wb_i_uart_we}),
      .i_slave_addr({wb_i_mem_addr, wb_i_led_addr, wb_i_uart_addr}),
      .i_slave_data({wb_i_mem_data, wb_i_led_data, wb_i_uart_data}),
      .i_slave_sel({wb_i_mem_sel, wb_i_led_sel, wb_i_uart_sel}),
      .o_slave_stall({wb_o_mem_stall, wb_o_led_stall, wb_o_uart_stall}),
      .o_slave_ack({wb_o_mem_ack, wb_o_led_ack, wb_o_uart_ack}),
      .o_slave_data({wb_o_mem_data, {16'b0, wb_o_led_data}, wb_o_uart_data}),

      // Mux
      .i_mux_slave_sel({
        mem_sel,
        led_sel,
        uart_sel
      })
  );

  assign LEDS = wb_o_led_leds[15:0];

  // verilator lint_off UNUSED
  wire [87:0] unused;
  assign unused = {wb_i_uart_addr, wb_i_uart_sel, wb_i_led_addr, wb_i_led_sel, wb_i_led_data[31:16]};
  // verilator lint_on UNUSED

endmodule

`endif
