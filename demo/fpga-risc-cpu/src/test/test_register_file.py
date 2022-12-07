import os

import pytest

import cocotb

from cocotb.clock import Clock, Timer
from cocotb.binary import BinaryValue
from cocotb.runner import get_runner
from cocotb.triggers import FallingEdge

src_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
tests_dir = os.path.dirname(os.path.abspath(__file__))
sim_build = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sim_build", "register_file")


RESET_FLOW = []
for i in range(32):
    RESET_FLOW.append({
        'rs1Id': '00000',
        'rs2Id': '00000',
        'rdId': BinaryValue(i, n_bits = 5).binstr,
        'rd': 32 * '0',
        'write': '1',
        'read': '1',
        'rs1': 32 * '0',
        'rs2': 32 * '0'
    })
RESET_TEST_CASE = {
    'flow': RESET_FLOW,
    'expected': {
        'rs1': 32 * '0',
        'rs2': 32 * '0'
    }
}

@cocotb.test()
async def check_register_file(dut):
    """ Test that ALU is working """
    clock = Clock(dut.clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.start_soon(clock.start())  # Start the clock

    TEST_CASES = [
        RESET_TEST_CASE,
        # Write r1
        {
            'flow': [
                {
                    'rs1Id': '00000',
                    'rs2Id': '00000',
                    'rdId': '00001',
                    'rd': 31 * '0' + '1',
                    'write': '1',
                    'read': '0',
                    'rs1': 32 * '0',
                    'rs2': 32 * '0'
                },
                {
                    'rs1Id': '00001',
                    'rs2Id': '00000',
                    'rdId': '00000',
                    'rd': 32 * '0',
                    'write': '0',
                    'read': '1',
                    'rs1': 31 * '0' + '1',
                    'rs2': 32 * '0'
                }
            ],
            'expected': {
                'rs1': 31 * '0' + '1',
                'rs2': 32 * '0'
            }
        }
    ]

    for test_case in TEST_CASES:
        flow = test_case['flow']
        for step in flow:
            dut.rs1Id.value = BinaryValue(step['rs1Id'])
            dut.rs2Id.value = BinaryValue(step['rs2Id'])
            dut.rdId.value = BinaryValue(step['rdId'])
            dut.rd.value = BinaryValue(step['rd'])
            dut.write.value = BinaryValue(step['write'])
            dut.read.value = BinaryValue(step['read'])

            # Await write
            await FallingEdge(dut.clk)

            assert dut.rs1.value.binstr == step['rs1'], 'Error with {}'.format(step)
            assert dut.rs2.value.binstr == step['rs2'], 'Error with {}'.format(step)
        assert dut.rs1.value.binstr == test_case['expected']['rs1'], 'Error with {}'.format(test_case)
        assert dut.rs2.value.binstr == test_case['expected']['rs2'], 'Error with {}'.format(test_case)
        
def test_runner():
    verilog_sources = [os.path.join(src_dir, "main", "soc.sv")]
    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)()
    os.makedirs(os.path.abspath(sim_build), exist_ok=True)
    with open(os.path.abspath(os.path.join(sim_build, "cmd.f")), 'w') as cmd:
        cmd.write('+timescale+1ns/1ps')
    runner.build(
        verilog_sources=verilog_sources,
        toplevel="register_file",
        defines=["DEFINE=4", "BENCH=1"],
        includes=[os.path.join(src_dir, "main")],
        extra_args=[
            '-s', 'register_file',
            '-f', os.path.abspath(os.path.join(sim_build, "cmd.f"))
        ],
        build_dir=sim_build
    )

    runner.test(
        python_search=[tests_dir],
        toplevel="register_file",
        py_module="test_register_file",
    )