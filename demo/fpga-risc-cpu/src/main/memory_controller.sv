`default_nettype none `timescale 1ns / 1ps

`ifndef MemoryController
`define MemoryController

`include "instr.svh"

module memory_controller (
    input  wire [ 6:0] op,
    input  wire [ 2:0] opcode,
    input  wire [31:0] memAddr,
    // Read
    input  wire [31:0] memData,
    output wire [31:0] out,
    // Write
    input  wire [31:0] in2,
    output wire [31:0] memWData,
    output wire [ 3:0] memWMask
);
  // TODO test it
  wire [15:0] LOAD_halfword = memAddr[1] ? memData[31:16] : memData[15:0];

  wire [7:0] LOAD_byte = memAddr[0] ? LOAD_halfword[15:8] : LOAD_halfword[7:0];
  wire mem_byteAccess = opcode[1:0] == 2'b00;
  wire mem_halfwordAccess = opcode[1:0] == 2'b01;
  wire LOAD_sign = !opcode[2] & (mem_byteAccess ? LOAD_byte[7] : LOAD_halfword[15]);

  assign out =
         mem_byteAccess ? {{24{LOAD_sign}},     LOAD_byte} :
     mem_halfwordAccess ? {{16{LOAD_sign}}, LOAD_halfword} :
                          memData ;
  assign memWData[7:0] = in2[7:0];
  assign memWData[15:8] = memAddr[0] ? in2[7:0] : in2[15:8];
  assign memWData[23:16] = memAddr[1] ? in2[7:0] : in2[23:16];
  assign memWData[31:24] = memAddr[0] ? in2[7:0] : memAddr[1] ? in2[15:8] : in2[31:24];
  assign memWMask = (op != `INSTR_STORE)? 4'b0000: mem_byteAccess      ?
	            (memAddr[1] ?
		          (memAddr[0] ? 4'b1000 : 4'b0100) :
		          (memAddr[0] ? 4'b0010 : 4'b0001)
                ) :
	        mem_halfwordAccess ?
	            (memAddr[1] ? 4'b1100 : 4'b0011) :
                4'b1111;
  
  // verilator lint_off UNUSED
  wire [29:0] unused;
  assign unused = {memAddr[31:2]};
  // verilator lint_on UNUSED

endmodule
`endif
