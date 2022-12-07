import os

import cocotb

from cocotb.clock import Clock, Timer
from cocotb.binary import BinaryValue
from cocotb.runner import get_runner

src_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
tests_dir = os.path.dirname(os.path.abspath(__file__))
sim_build = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sim_build", "test_alu")

@cocotb.test()
async def check_alu(dut):
    """ Test that ALU is working """
    clock = Clock(BinaryValue(0), 10, units="us")  # Create a 10us period clock on port clk
    cocotb.start_soon(clock.start())  # Start the clock

    TEST_CASES = [
        # ADD
        {
            'op': '0110011',
            'opcode': '000',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '1',
            'in2': 31 * '0' + '1',
            'imm': 32 * '0',
            'out': 30 * '0' + '10'
        },
        # SUB
        {
            'op': '0110011',
            'opcode': '000',
            'shamt': '00000',
            'funct7': '0100000',
            'in1': 31 * '0' + '1',
            'in2': 31 * '0' + '1',
            'imm': 32 * '0',
            'out': 31 * '0' + '0'
        },
        # SLL
        {
            'op': '0110011',
            'opcode': '001',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '1',
            'in2': 30 * '0' + '10',
            'imm': 32 * '0',
            'out': 29 * '0' + '100'
        },
        # SLT
        {
            'op': '0110011',
            'opcode': '010',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '1',
            'in2': 30 * '0' + '10',
            'imm': 32 * '0',
            'out': 31 * '0' + '1'
        },
        # SLT false
        {
            'op': '0110011',
            'opcode': '010',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 30 * '0' + '10',
            'in2': 31 * '0' + '1',
            'imm': 32 * '0',
            'out': 31 * '0' + '0'
        },
        # SLT negative
        {
            'op': '0110011',
            'opcode': '010',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': '1' + 29 * '0' + '10',
            'in2': 31 * '0' + '1',
            'imm': 32 * '0',
            'out': 31 * '0' + '1'
        },
        # SLT negative false
        {
            'op': '0110011',
            'opcode': '010',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '1',
            'in2': '1' + 29 * '0' + '10',
            'imm': 32 * '0',
            'out': 31 * '0' + '0'
        },
        # SLTU
        {
            'op': '0110011',
            'opcode': '011',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '1',
            'in2': '1' + 29 * '0' + '10',
            'imm': 32 * '0',
            'out': 31 * '0' + '1'
        },
        # XOR
        {
            'op': '0110011',
            'opcode': '100',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '1',
            'in2': 31 * '0' + '1',
            'imm': 32 * '0',
            'out': 31 * '0' + '0'
        },
        {
            'op': '0110011',
            'opcode': '100',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '1',
            'in2': 31 * '0' + '0',
            'imm': 32 * '0',
            'out': 31 * '0' + '1'
        },
        {
            'op': '0110011',
            'opcode': '100',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '0',
            'in2': 31 * '0' + '1',
            'imm': 32 * '0',
            'out': 31 * '0' + '1'
        },
        {
            'op': '0110011',
            'opcode': '100',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '0',
            'in2': 31 * '0' + '0',
            'imm': 32 * '0',
            'out': 31 * '0' + '0'
        },
        # SRL
        {
            'op': '0110011',
            'opcode': '101',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 30 * '0' + '10',
            'in2': 31 * '0' + '1',
            'imm': 32 * '0',
            'out': 31 * '0' + '1'
        },
        {
            'op': '0110011',
            'opcode': '101',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 30 * '0' + '10',
            'in2': 30 * '0' + '10',
            'imm': 32 * '0',
            'out': 31 * '0' + '0'
        },
        # OR
        {
            'op': '0110011',
            'opcode': '110',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '0',
            'in2': 31 * '0' + '0',
            'imm': 32 * '0',
            'out': 31 * '0' + '0'
        },
        {
            'op': '0110011',
            'opcode': '110',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '0',
            'in2': 31 * '0' + '1',
            'imm': 32 * '0',
            'out': 31 * '0' + '1'
        },
        {
            'op': '0110011',
            'opcode': '110',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '1',
            'in2': 31 * '0' + '0',
            'imm': 32 * '0',
            'out': 31 * '0' + '1'
        },
        {
            'op': '0110011',
            'opcode': '110',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '1',
            'in2': 31 * '0' + '1',
            'imm': 32 * '0',
            'out': 31 * '0' + '1'
        },
        # AND
        {
            'op': '0110011',
            'opcode': '111',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '0',
            'in2': 31 * '0' + '0',
            'imm': 32 * '0',
            'out': 31 * '0' + '0'
        },
        {
            'op': '0110011',
            'opcode': '111',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '1',
            'in2': 31 * '0' + '0',
            'imm': 32 * '0',
            'out': 31 * '0' + '0'
        },
        {
            'op': '0110011',
            'opcode': '111',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '0',
            'in2': 31 * '0' + '1',
            'imm': 32 * '0',
            'out': 31 * '0' + '0'
        },
        {
            'op': '0110011',
            'opcode': '111',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '1',
            'in2': 31 * '0' + '1',
            'imm': 32 * '0',
            'out': 31 * '0' + '1'
        },
        # ADDi
        {
            'op': '0010011',
            'opcode': '000',
            'shamt': '00000',
            'funct7': '0000000',
            'in1': 31 * '0' + '1',
            'in2': 32 * '0',
            'imm': 30 * '0' + '10',
            'out': 30 * '0' + '11'
        },
    ]

    for test_case in TEST_CASES:
        dut.op.value = BinaryValue(test_case['op'])
        dut.opcode.value = BinaryValue(test_case['opcode'])
        dut.shamt.value = BinaryValue(test_case['shamt'])
        dut.funct7.value = BinaryValue(test_case['funct7'])
        dut.in1.value = BinaryValue(test_case['in1'])
        dut.in2.value = BinaryValue(test_case['in2'])
        dut.imm.value = BinaryValue(test_case['imm'])

        await Timer(10, units='us')

        assert dut.out.value.binstr == test_case['out'], 'Error with {}'.format(test_case)


def test_runner():
    verilog_sources = [os.path.join(src_dir, "main", "soc.sv")]
    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)()
    os.makedirs(os.path.abspath(sim_build), exist_ok=True)
    with open(os.path.abspath(os.path.join(sim_build, "cmd.f")), 'w') as cmd:
        cmd.write('+timescale+1ns/1ps')
    runner.build(
        verilog_sources=verilog_sources,
        toplevel="alu",
        defines=["DEFINE=4", "BENCH=1"],
        includes=[os.path.join(src_dir, "main")],
        extra_args=[
            '-s', 'alu',
            '-f', os.path.abspath(os.path.join(sim_build, "cmd.f"))
        ],
        build_dir=sim_build
    )

    runner.test(
        python_search=[tests_dir],
        toplevel="alu",
        py_module="test_alu",
    )