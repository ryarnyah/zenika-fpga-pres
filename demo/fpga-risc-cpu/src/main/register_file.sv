`default_nettype none
`timescale 1ns/1ps

`ifndef REGISTER_FILE
`define REGISTER_FILE

module register_file (
    input  wire        clk,
    input  wire        rst,
    input  wire [ 4:0] rs1Id,
    input  wire [ 4:0] rs2Id,
    input  wire [ 4:0] rdId,
    input  wire [31:0] rd,
    input  wire        write,
    input  wire        read,
    output reg        [31:0] rs1,
    output reg        [31:0] rs2
);
  (* ram_style = "distributed" *)
  reg [31:0] regs[0:31];
`ifdef BENCH
  integer i;
  initial begin
    for (i = 0; i < 32; ++i) begin
      regs[i] = 0;
    end
  end
`endif
`ifdef COCOTB
  integer i;
  initial begin
    for (i = 0; i < 32; ++i) begin
      regs[i] = 0;
    end
  end
`endif

  always @(posedge clk) begin
    case (1'b1)
      read: begin
        rs1 <= regs[rs1Id];
        rs2 <= regs[rs2Id];        
      end
      write: begin
`ifdef BENCH
        $display("write r%0d = %d", rdId, rd);
`endif
        regs[rdId] <= rd;      
      end
      default: ;
    endcase
    if (rst) begin
      rs1 <= 0;
      rs2 <= 0;
    end
  end

endmodule

`endif
