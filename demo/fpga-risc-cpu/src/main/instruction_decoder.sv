`default_nettype none `timescale 1ns / 1ps

`ifndef INSTRUCTION_DECODER
`define INSTRUCTION_DECODER

`include "instr.svh"

module instruction_decoder (
    input wire        clk,
    input wire        rst,
    input wire [31:0] instr,

    output reg  [ 6:0] op,
    output reg  [ 2:0] opcode,
    output reg  [31:0] imm,
    output wire [ 4:0] rs1Id,
    output wire [ 4:0] rs2Id,
    output reg  [ 4:0] rdId,
    output reg  [ 6:0] funct7,
    output reg  [ 4:0] shamt
);

  /* Immediate values. */
  wire [31:0] Uimm = {instr[31], instr[30:12], {12{1'b0}}};
  wire [31:0] Iimm = {{21{instr[31]}}, instr[30:20]};
  wire [31:0] Simm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
  wire [31:0] Bimm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
  wire [31:0] Jimm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

  assign rs1Id = instr[19:15];
  assign rs2Id = instr[24:20];

  always @(posedge clk) begin
    rdId <= instr[11:7];

    funct7 <= instr[31:25];
    shamt <= instr[24:20];

    /* Op with opcode */
    op <= instr[6:0];
    opcode <= instr[14:12];
    imm <= fimm(instr[6:0], Uimm, Iimm, Simm, Bimm, Jimm);      
    
    if (rst) begin
      rdId <= 0;
      funct7 <= 0;
      shamt <= 0;
      op <= 0;
      opcode <= 0;
      imm <= 0;
    end
  end

  function [31:0] fimm(input logic [6:0] fop, input logic [31:0] fUimm, input logic [31:0] fIimm,
                       input logic [31:0] fSimm, input logic [31:0] fBimm,
                       input logic [31:0] fJimm);
    case (fop)
      `INSTR_ALU_REG: fimm = 32'b0;
      `INSTR_ALU_IMM: fimm = fIimm;
      `INSTR_BRANCH: fimm = fBimm;
      `INSTR_JALR: fimm = fIimm;
      `INSTR_JAL: fimm = fJimm;
      `INSTR_AUIPC: fimm = fUimm;
      `INSTR_LUI: fimm = fUimm;
      `INSTR_LOAD: fimm = fIimm;
      `INSTR_STORE: fimm = fSimm;
      `INSTR_SYSTEM: fimm = 32'b0;
      default: fimm = 32'b0;
    endcase

  endfunction
endmodule
`endif
