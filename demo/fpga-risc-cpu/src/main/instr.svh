`ifndef INSTR
`define INSTR

// Instruction type
`define INSTR_ALU_REG 7'b0110011
`define INSTR_ALU_IMM 7'b0010011
`define INSTR_BRANCH  7'b1100011
`define INSTR_JALR    7'b1100111
`define INSTR_JAL     7'b1101111
`define INSTR_AUIPC   7'b0010111
`define INSTR_LUI     7'b0110111
`define INSTR_LOAD    7'b0000011
`define INSTR_STORE   7'b0100011
`define INSTR_SYSTEM  7'b1110011

// Opcodes
`define NOP 32'b0000000_00000_00000_000_00000_0110011
`define ADD_SUB 3'b000
`define SLL     3'b001
`define SLT     3'b010
`define SLTU    3'b011
`define XOR     3'b100
`define SRL     3'b101
`define OR      3'b110
`define AND     3'b111

// Branch opcode
`define BEQ     3'b000
`define BNE     3'b001
`define BLT     3'b100
`define BGE     3'b101
`define BLTU    3'b110
`define BGEU    3'b111

// Load opcodes
`define LB      3'b000
`define LH      3'b001
`define LW      3'b010
`define LBU     3'b100
`define LHU     3'b101

// States
`define STATE_FETCH         0
`define STATE_WAIT_FETCH    1
`define STATE_WAIT_INSTR    2
`define STATE_EXECUTE       3
`define STATE_WAIT_DATA     4

`endif
