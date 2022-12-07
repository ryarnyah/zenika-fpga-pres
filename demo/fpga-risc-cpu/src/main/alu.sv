`default_nettype none
`timescale 1ns/1ps

`ifndef ALU
`define ALU

`include "instr.svh"

module alu(
        input wire [6:0] op,
        input wire [2:0] opcode,
        input wire [4:0] shamt,
        input wire [6:0] funct7,
        input wire [31:0] in1,
        input wire [31:0] in2,
        input wire [31:0] imm,
        output wire [31:0] out,
        output wire takeBranch
    );
    wire [31:0] ain2 = (op == `INSTR_ALU_REG) ? in2 : imm;
    wire [4:0] ashamt = (op == `INSTR_ALU_REG) ? ain2[4:0] : shamt;
    assign out = fout(
        op,
        opcode,
        funct7,
        ashamt,
        in1,
        ain2
    );
    /* verilator lint_off UNUSED */
    function [31:0] fout(
        input logic [6:0] fop,
        input logic [2:0] fopcode,
        input logic [6:0] ffunct7,
        input logic [4:0] fashamt,
        input logic [31:0] fin1,
        input logic [31:0] fin2);
        case(fopcode)
            `ADD_SUB: fout = (ffunct7[5] & fop[5]) ? (fin1-fin2) : (fin1+fin2);
            `SLL: fout = fin1 << fashamt;
            `SLT: fout = {31'b0, ($signed(fin1) < $signed(fin2))};
            `SLTU: fout = {31'b0, (fin1 < fin2)};
            `XOR: fout = (fin1 ^ fin2);
            `SRL: fout = ffunct7[5]? ($signed(fin1) >>> fashamt) : (fin1 >> fashamt);
            `OR: fout = (fin1 | fin2);
            `AND: fout = (fin1 & fin2);
            default: fout = 32'b0;
        endcase
    endfunction
    /* verilator lint_on UNUSED */

    assign takeBranch = branch(
        opcode,
        in1,
        in2
    );
    function branch(
        input logic [2:0] fopcode,
        input logic [31:0] fin1,
        input logic [31:0] fin2
    );
        case(fopcode)
            `BEQ: branch = (fin1 == fin2);
            `BNE: branch = (fin1 != fin2);
            `BLT: branch = ($signed(fin1) < $signed(fin2));
            `BGE: branch = ($signed(fin1) >= $signed(fin2));
            `BLTU: branch = (fin1 < fin2);
            `BGEU: branch = (fin1 >= fin2);
            default: branch = 1'b0;
        endcase
    endfunction
endmodule

`endif
