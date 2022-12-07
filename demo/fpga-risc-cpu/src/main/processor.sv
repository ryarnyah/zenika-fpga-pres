`default_nettype none
`timescale 1ns/1ps

`ifndef Processor
`define Processor

`include "instr.svh"
`include "register_file.sv"
`include "instruction_decoder.sv"
`include "memory_controller.sv"
`include "alu.sv"

module processor(
    input wire i_clk,
    input wire i_rst,
    output wire [31:0] o_addr, 
    input wire [31:0] i_data,
    output wire [31:0] o_data,
    output wire [3:0] o_sel,
    input wire i_stall,
    input wire i_ack,
    output reg o_cyc,
    output reg o_stb,
    output reg o_we
);

    logic [31:0] PC = 0;
    logic [31:0] instr;

    // Instruction decoder
    wire [6:0] op;
    wire [2:0] opcode;
    wire [31:0] imm;
    wire [4:0] rs1Id;
    wire [4:0] rs2Id;
    wire [4:0] rdId;
    wire [6:0] funct7;
    wire [4:0] shamt;
    instruction_decoder decoder (
        .clk(i_clk),
        .rst(i_rst),
        .instr(instr),
        .op(op),
        .opcode(opcode),
        .imm(imm),
        .rs1Id(rs1Id),
        .rs2Id(rs2Id),
        .rdId(rdId),
        .funct7(funct7),
        .shamt(shamt)
    );

    // Registers
    wire [31:0] rs1;
    wire [31:0] rs2;
    logic [31:0] rd;
    wire writeReg;
    wire readReg;
    register_file registers(
        .clk(i_clk),
        .rst(i_rst),
        // Read
        .rs1Id(rs1Id),
        .rs2Id(rs2Id),
        .rs1(rs1),
        .rs2(rs2),
        // Write
        .rdId(rdId),
        .rd(rd),
        .write(writeReg),
        .read(readReg)
    );

    // ALU
    wire takeBranch;
    wire [31:0] aluOut;
    alu alu(
        .op(op),
        .opcode(opcode),
        .shamt(shamt),
        .funct7(funct7),
        .imm(imm),
        .in1(rs1),
        .in2(rs2),
        .out(aluOut),
        .takeBranch(takeBranch)
    );
    
    // MemoryController
    wire [31:0] mmuOut;
    wire [31:0] loadstoreAddr = rs1 + imm;
    memory_controller mem_controller(
        .op(op),
        .opcode(opcode),
        .memAddr(loadstoreAddr),
        .memData(i_data),
        .out(mmuOut),
        .in2(rs2),
        .memWData(o_data),
        .memWMask(o_sel)
    );

    // State machine
    reg [2:0] state = `STATE_FETCH;
    logic [31:0] nextPC;
    wire execState = state == `STATE_EXECUTE;
    always_comb begin
        nextPC = 0;
        if (execState) begin            
            case(1'b1)
                (op == `INSTR_BRANCH && takeBranch): nextPC = PC + imm;
                (op == `INSTR_JAL): nextPC = PC + imm;
                (op == `INSTR_JALR): nextPC = rs1 + imm;
                default: nextPC = PC + 4;
            endcase
        end
    end
    // Load/Store data into/from RD
    assign o_cyc = (state == `STATE_WAIT_DATA ||
                    state == `STATE_FETCH);
    assign o_stb = (state == `STATE_WAIT_DATA ||
                    state == `STATE_FETCH);
    assign o_addr = (state == `STATE_FETCH || state == `STATE_WAIT_FETCH) ? PC:
                      loadstoreAddr;
    assign o_we = (state == `STATE_WAIT_DATA && op == `INSTR_STORE) ||
                  (execState && op == `INSTR_STORE);
    // Write RD?
    assign writeReg = (state == `STATE_WAIT_DATA && op == `INSTR_LOAD && i_ack && rdId != 0) || 
                      (execState && op == `INSTR_JAL && rdId != 0) || 
                      (execState && op == `INSTR_JALR && rdId != 0) ||
                      (execState && op == `INSTR_ALU_REG && rdId != 0) || 
                      (execState && op == `INSTR_ALU_IMM && rdId != 0) ||
                      (execState && op == `INSTR_AUIPC && rdId != 0) ||
                      (execState && op == `INSTR_LUI && rdId != 0);
    assign readReg = (state == `STATE_WAIT_INSTR);
    always_comb begin
        case (1'b1)
            (state == `STATE_WAIT_DATA && op == `INSTR_LOAD): rd = mmuOut;
            (execState && (op == `INSTR_JAL || op == `INSTR_JALR)): rd = PC + 4;
            (execState && (op == `INSTR_ALU_REG || op == `INSTR_ALU_IMM)): rd = aluOut;
            (execState && op == `INSTR_AUIPC): rd = PC + imm;
            (execState && op == `INSTR_LUI): rd = imm;
            default: rd = 32'b0;
        endcase
    end

    always @(posedge i_clk) begin
        case(state)
            `STATE_FETCH: begin
                // Ensure memory is not stall
                if (!i_stall) begin
                    state <= `STATE_WAIT_FETCH;
                end
            end
            `STATE_WAIT_FETCH: begin
                // Wait for instr to be loaded
                if (i_ack) begin
                    instr <= i_data;
                    state <= `STATE_WAIT_INSTR;                        
                end
            end
            `STATE_WAIT_INSTR: begin
                // Wait for instr to be decoded & registers to be loaded
                state <= `STATE_EXECUTE;
            end
            `STATE_EXECUTE: begin
                // Ensure when load or store that we are not stall
                if (!i_stall || (op != `INSTR_LOAD && op != `INSTR_STORE)) begin
                    if (op != `INSTR_SYSTEM) begin
                        PC <= nextPC;
                    end
                    state <= (op == `INSTR_LOAD || op == `INSTR_STORE) ? `STATE_WAIT_DATA:
                            `STATE_FETCH;
                end
            end
            `STATE_WAIT_DATA: begin
                // Wait for data to be acked
                if (i_ack) begin
                    state <= `STATE_FETCH;
                end
            end
            default: ;
        endcase
`ifdef BENCH
        $display("PC = %0d, state = %0d i_ack = %b o_cyc = %b memAddr = %b, o_data = %b, mask = %b, instr = %b i_data = %b op = %b opcode = %b imm = %0d rs1Id = %d, rs1 = %b, rs2Id = %d rdId = %d func7 = %b branch = %b rd = %b write = %b",
                    PC / 4, state, i_ack, o_cyc, o_addr, o_data, o_sel, instr, i_data, op, opcode, imm, rs1Id, rs1, rs2Id, rdId, funct7, takeBranch, rd, writeReg);
        if (op == `INSTR_SYSTEM) $finish();
`endif
        if (i_rst) begin
            PC <= 0;
            state <= `STATE_FETCH;
        end
    end
endmodule

`endif
