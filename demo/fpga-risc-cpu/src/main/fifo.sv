`default_nettype none `timescale 1ns / 1ps

`ifndef FIFO
`define FIFO

module fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 512
) (
    input  wire [WIDTH-1:0] i_data,
    input  wire             i_clk,
    input  wire             i_rst,
    input  wire             i_we,
    input  wire             i_re,
    output reg  [WIDTH-1:0] o_data,
    output reg              o_full,
    output reg              o_empty
);
  localparam PTR_MSB = $clog2(DEPTH);
  localparam ADDR_MSB = PTR_MSB - 1;

  // memory will contain the FIFO data.
  (* ram_style = "distributed" *)
  reg [WIDTH-1:0] memory[0:DEPTH-1];
  reg [PTR_MSB:0] write_ptr = 0;
  reg [PTR_MSB:0] read_ptr = 0;

  // Initialization
  initial begin
    // Init both write_cnt and read_cnt to 0
    write_ptr = 0;
    read_ptr = 0;
    o_data = ~0;
  end  // end initial

  wire [ADDR_MSB:0] write_addr = write_ptr[ADDR_MSB:0];
  wire [ADDR_MSB:0] read_addr = read_ptr[ADDR_MSB:0];

  wire fifo_empty = (write_ptr == read_ptr) ? 1'b1 : 1'b0;
  wire fifo_full  = (write_addr == read_addr) & 
                    (write_ptr[PTR_MSB] != read_ptr[PTR_MSB])
                    ? 1'b1 : 1'b0;

  always @(posedge i_clk) begin
    o_empty <= fifo_empty;
    o_full <= fifo_full;
  end

  wire fifo_not_empty;
  assign fifo_not_empty = ~fifo_empty;

  always @(posedge i_clk) begin
    if (i_we) begin
      memory[write_addr] <= i_data;
      write_ptr <= write_ptr + 1;
    end

    if (i_re && fifo_not_empty) begin
      o_data   <= memory[read_addr];
      read_ptr <= read_ptr + 1;
    end
    
    if (i_rst) begin
      write_ptr <= 0;
      read_ptr <= 0;
    end
  end
endmodule
`endif
