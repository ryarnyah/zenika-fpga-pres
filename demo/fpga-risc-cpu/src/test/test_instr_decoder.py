import os

import pytest

import cocotb

from cocotb.clock import Clock, Timer
from cocotb.binary import BinaryValue
from cocotb.runner import get_runner
from cocotb.triggers import FallingEdge

src_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
tests_dir = os.path.dirname(os.path.abspath(__file__))
sim_build = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sim_build", "instr_decoder")

@cocotb.test()
async def check_instr_decoder_decode(dut):
    """ Test that instr is decoded successfully """
    clock = Clock(dut.clk, 10, units="us")  # Create a 10us period clock on port clk
    cocotb.start_soon(clock.start())  # Start the clock

    TEST_CASES = [
        # add x1, x0, x0
        {
            'instr': '0000000' + '00000' + '00000' + '000' + '00001' + '0110011',
            'op': '0110011',
            'opcode': '000',
            'imm': 32 * '0',
            'rs1Id': '00000',
            'rs2Id': '00000',
            'rdId': '00001',
            'funct7': '0000000',
            'shamt': '00000'
        },
        # addi x1, x1, 1
        {
            'instr': '000000000001' + '00001' + '000' + '00001' + '0010011',
            'op': '0010011',
            'opcode': '000',
            'imm': 20 * '0' + '000000000001',
            'rs1Id': '00001',
            'rs2Id': '00001',
            'rdId': '00001',
            'funct7': '0000000',
            'shamt': '00001'
        },
        # lw x2,0(x1)
        {
            'instr': '000000000000' + '00001' + '010' + '00010' + '0000011',
            'op': '0000011',
            'opcode': '010',
            'imm': 32 * '0',
            'rs1Id': '00001',
            'rs2Id': '00000',
            'rdId': '00010',
            'funct7': '0000000',
            'shamt': '00000'
        },
        # sw x2,0(x1)
        {
            'instr': '0000000' + '00001' + '00010' + '010' + '00000' + '0100011',
            'op': '0100011',
            'opcode': '010',
            'imm': 32 * '0',
            'rs1Id': '00010',
            'rs2Id': '00001',
            'rdId': '00000',
            'funct7': '0000000',
            'shamt': '00001'
        },
        # ebreak
        {
            'instr': '000000000001' + '00000' + '000' + '00000' + '1110011',
            'op': '1110011',
            'opcode': '000',
            'imm': 32 * '0',
            'rs1Id': '00000',
            'rs2Id': '00001',
            'rdId': '00000',
            'funct7': '0000000',
            'shamt': '00001'
        }
    ]

    for test_case in TEST_CASES:
        dut.instr.value = BinaryValue(test_case['instr'])

        await FallingEdge(dut.clk)

        assert dut.op.value.binstr == test_case['op'], 'Error with {}'.format(test_case)
        assert dut.opcode.value.binstr == test_case['opcode'], 'Error with {}'.format(test_case)
        assert dut.rs1Id.value.binstr == test_case['rs1Id'], 'Error with {}'.format(test_case)
        assert dut.rs2Id.value.binstr == test_case['rs2Id'], 'Error with {}'.format(test_case)
        assert dut.rdId.value.binstr == test_case['rdId'], 'Error with {}'.format(test_case)
        assert dut.imm.value.binstr == test_case['imm'], 'Error with {}'.format(test_case)
        assert dut.funct7.value.binstr == test_case['funct7'], 'Error with {}'.format(test_case)
        assert dut.shamt.value.binstr == test_case['shamt'], 'Error with {}'.format(test_case)


def test_runner():
    verilog_sources = [os.path.join(src_dir, "main", "soc.sv")]
    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)()
    os.makedirs(os.path.abspath(sim_build), exist_ok=True)
    with open(os.path.abspath(os.path.join(sim_build, "cmd.f")), 'w') as cmd:
        cmd.write('+timescale+1ns/1ps')
    runner.build(
        verilog_sources=verilog_sources,
        toplevel="instruction_decoder",
        defines=["DEFINE=4", "BENCH=1"],
        includes=[os.path.join(src_dir, "main")],
        extra_args=[
            '-s', 'instruction_decoder',
            '-f', os.path.abspath(os.path.join(sim_build, "cmd.f"))
        ],
        build_dir=sim_build
    )

    runner.test(
        python_search=[tests_dir],
        toplevel="instruction_decoder",
        py_module="test_instr_decoder",
    )