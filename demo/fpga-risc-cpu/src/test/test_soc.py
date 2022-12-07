import os

import pytest
import logging
import cocotb

from cocotb.clock import Clock, Timer
from cocotb.binary import BinaryValue
from cocotb.runner import get_runner
from cocotb.triggers import FallingEdge

from cocotbext.uart import UartSource, UartSink

src_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
tests_dir = os.path.dirname(os.path.abspath(__file__))
sim_build = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sim_build", "soc")

@cocotb.test()
async def check_uart_recv(dut):
    """ Test that UART is working """
    clock = Clock(dut.clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.start_soon(clock.start())  # Start the clock

    log = logging.getLogger(f"check_uart_recv")

    dut.RESET.value = BinaryValue('1')
    await FallingEdge(dut.clk)

    dut.RESET.value = BinaryValue('0')
    await FallingEdge(dut.clk)

    rxd = UartSource(dut.RXD, baud=115200, bits=8)
    txd = UartSink(dut.TXD, baud=115200, bits=8)

    await rxd.write(b'ABCDE')

    for i in range(int(1e9/115200/10) * 10):
        await FallingEdge(dut.clk)
    val = await txd.read()
    assert val == b'E'

"""
    LI(gp, 32'h0200_0000);
    ADD(x12,x0,x0);
    ADDI(x2,x0,65);
    Label(L0_);
      LW(x12, gp, 8);
      BNE(x12, x2, LabelRef(L0_));
    SW(x12, gp, 8);
    EBREAK();
"""
@pytest.mark.skip(reason="no way of currently testing this")
def test_runner():
    verilog_sources = [os.path.join(src_dir, "main", "soc.sv")]
    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)()
    os.makedirs(os.path.abspath(sim_build), exist_ok=True)
    with open(os.path.abspath(os.path.join(sim_build, "cmd.f")), 'w') as cmd:
        cmd.write('+timescale+1ns/1ps')
    runner.build(
        verilog_sources=verilog_sources,
        toplevel="soc",
        defines=["DEFINE=4", "BENCH=1"],
        includes=[os.path.join(src_dir, "main")],
        extra_args=[
            '-s', 'soc',
            '-f', os.path.abspath(os.path.join(sim_build, "cmd.f"))
        ],
        build_dir=sim_build
    )

    runner.test(
        python_search=[tests_dir],
        toplevel="soc",
        py_module="test_soc",
    )