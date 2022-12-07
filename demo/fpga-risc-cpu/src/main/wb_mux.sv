`default_nettype none `timescale 1ns / 1ps

`ifndef MUX
`define MUX

module wb_mux #(
    parameter BYTES = 32,
    parameter SLAVE_NUMBER = 3
) (
    // Master inputs
    input  wire [    BYTES-1:0] o_master_addr,
    output wire [    BYTES-1:0] i_master_data,
    input  wire [    BYTES-1:0] o_master_data,
    input  wire [BYTES/8 - 1:0] o_master_sel,
    output wire                 i_master_stall,
    output wire                 i_master_ack,
    input  wire                 o_master_cyc,
    input  wire                 o_master_stb,
    input  wire                 o_master_we,

    // Slave Inputs
    output wire [                SLAVE_NUMBER-1:0] i_slave_cyc,
    output wire [                SLAVE_NUMBER-1:0] i_slave_stb,
    output wire [                SLAVE_NUMBER-1:0] i_slave_we,
    output wire [      (SLAVE_NUMBER*BYTES) - 1:0] i_slave_addr,
    output wire [      (SLAVE_NUMBER*BYTES) - 1:0] i_slave_data,
    output wire [(SLAVE_NUMBER * (BYTES/8)) - 1:0] i_slave_sel,
    input  wire [                SLAVE_NUMBER-1:0] o_slave_stall,
    input  wire [                SLAVE_NUMBER-1:0] o_slave_ack,
    input  wire [        (SLAVE_NUMBER*BYTES)-1:0] o_slave_data,

    // Mux sel
    input  wire [                SLAVE_NUMBER-1:0] i_mux_slave_sel
);

  logic                      wb_master_ack;
  logic                      wb_master_stall;
  logic   [       BYTES-1:0] wb_master_data;

  generate
    genvar s;
    for (s = 0; s < SLAVE_NUMBER; s = s + 1) begin
      assign i_slave_addr[s*BYTES+:BYTES] = o_master_addr;
      assign i_slave_data[s*BYTES+:BYTES] = o_master_data;
      assign i_slave_sel[s*(BYTES/8)+:(BYTES/8)] = o_master_sel;
      assign i_slave_cyc[s] = o_master_cyc;
      assign i_slave_we[s] = o_master_we;
      assign i_slave_stb[s] = i_mux_slave_sel[s] & o_master_stb;
    end
  endgenerate

  always_comb begin
    wb_master_ack = 1'b0;
    for (int i = 0; i < SLAVE_NUMBER; i++) begin
      if (i_mux_slave_sel[i]) wb_master_ack = o_slave_ack[i];
    end
  end

  always_comb begin
    wb_master_stall = 1'b0;
    for (int i = 0; i < SLAVE_NUMBER; i++) begin
      if (i_mux_slave_sel[i]) wb_master_stall = o_slave_stall[i];
    end
  end

  always_comb begin
    wb_master_data = 32'b0;
    for (int i = 0; i < SLAVE_NUMBER; i++) begin
      if (i_mux_slave_sel[i]) wb_master_data = o_slave_data[i*BYTES+:BYTES];
    end
  end

  assign i_master_stall = wb_master_stall;
  assign i_master_ack   = wb_master_ack;
  assign i_master_data  = wb_master_data;

endmodule

`endif
