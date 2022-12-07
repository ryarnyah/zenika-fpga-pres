import os

import pytest

import cocotb

from cocotb.clock import Clock, Timer
from cocotb.binary import BinaryValue
from cocotb.runner import get_runner
from cocotb.triggers import FallingEdge

from cocotbext.uart import UartSource, UartSink

src_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
tests_dir = os.path.dirname(os.path.abspath(__file__))
sim_build = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sim_build", "uart")

@cocotb.test()
async def check_uart_recv(dut):
    clock = Clock(dut.i_clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.start_soon(clock.start())  # Start the clock

    dut.i_rst.value = BinaryValue('1')
    dut.i_we.value = BinaryValue('0')
    dut.i_stb.value = BinaryValue('0')
    dut.i_cyc.value = BinaryValue('0')
    await FallingEdge(dut.i_clk)
    assert dut.o_data.value.binstr == '11111111111111111111111111111111'

    baud_rate = 115200

    uart_source = UartSource(dut.ser_rx, baud=baud_rate, bits=8)
    dut.i_rst.value = BinaryValue('0')
    dut.i_we.value = BinaryValue('0')

    await uart_source.write(b'AB')

    # Wait for 8bits
    while dut.o_data.value.binstr == '11111111111111111111111111111111':
        dut.i_stb.value = BinaryValue('0')
        dut.i_cyc.value = BinaryValue('0')
        await FallingEdge(dut.i_clk)
        dut.i_stb.value = BinaryValue('1')
        dut.i_cyc.value = BinaryValue('1')
        await FallingEdge(dut.i_clk)
    
    assert dut.o_data.value == 65
    dut.i_stb.value = BinaryValue('0')
    dut.i_cyc.value = BinaryValue('0')
    await FallingEdge(dut.i_clk)
    
    while dut.o_data.value.binstr == '11111111111111111111111111111111':
        dut.i_stb.value = BinaryValue('0')
        dut.i_cyc.value = BinaryValue('0')
        await FallingEdge(dut.i_clk)
        dut.i_stb.value = BinaryValue('1')
        dut.i_cyc.value = BinaryValue('1')
        await FallingEdge(dut.i_clk)
    assert dut.o_data.value == 66

@cocotb.test()
async def check_uart_send(dut):
    clock = Clock(dut.i_clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.start_soon(clock.start())  # Start the clock

    uart_sink = UartSink(dut.ser_tx, baud=115200, bits=8)

    dut.i_rst.value = BinaryValue('1')
    dut.i_we.value = BinaryValue('0')
    dut.i_stb.value = BinaryValue('0')
    dut.i_cyc.value = BinaryValue('0')
    await FallingEdge(dut.i_clk)
    assert dut.o_data.value.binstr == '11111111111111111111111111111111'

    dut.i_rst.value = BinaryValue('0')
    dut.i_we.value = BinaryValue('1')
    dut.i_stb.value = BinaryValue('1')
    dut.i_cyc.value = BinaryValue('1')
    dut.i_data.value = BinaryValue((32-7) * '0' + bin(ord('A'))[2:])

    await FallingEdge(dut.i_clk)
    while dut.o_ack.value != 1:
        await FallingEdge(dut.i_clk)
    
    dut.i_stb.value = BinaryValue('0')
    dut.i_cyc.value = BinaryValue('0')
    
    data = await uart_sink.read()
    assert data == b'A'

@cocotb.test()
async def check_uart_send_multi(dut):
    clock = Clock(dut.i_clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.start_soon(clock.start())  # Start the clock

    to_send = 'AB'

    uart_sink = UartSink(dut.ser_tx, baud=115200, bits=8)
    
    dut.i_rst.value = BinaryValue('1')
    dut.i_we.value = BinaryValue('0')
    dut.i_stb.value = BinaryValue('0')
    dut.i_cyc.value = BinaryValue('0')
    await FallingEdge(dut.i_clk)
    assert dut.o_data.value.binstr == '11111111111111111111111111111111'

    dut.i_rst.value = BinaryValue('0')
    dut.i_we.value = BinaryValue('1')

    recv = b''
    for t in to_send:
        binary = bin(ord(t))[2:]
        dut.i_stb.value = BinaryValue('1')
        dut.i_cyc.value = BinaryValue('1')
        dut.i_data.value = BinaryValue((32-len(binary)) * '0' + binary)

        await FallingEdge(dut.i_clk)
        while dut.o_ack.value != 1:
            await FallingEdge(dut.i_clk)

        dut.i_stb.value = BinaryValue('0')
        dut.i_cyc.value = BinaryValue('0')

        await FallingEdge(dut.i_clk)
    
    for t in to_send:
        recv += await uart_sink.read()

    assert recv == b'AB'

def test_runner():
    verilog_sources = [os.path.join(src_dir, "main", "wb_uart.sv")]
    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)()
    os.makedirs(os.path.abspath(sim_build), exist_ok=True)
    with open(os.path.abspath(os.path.join(sim_build, "cmd.f")), 'w') as cmd:
        cmd.write('+timescale+1ns/1ps')
    runner.build(
        verilog_sources=verilog_sources,
        toplevel="wb_uart",
        defines=["DEFINE=4", "BENCH=1"],
        includes=[os.path.join(src_dir, "main")],
        extra_args=[
            '-s', 'wb_uart',
            '-f', os.path.abspath(os.path.join(sim_build, "cmd.f"))
        ],
        build_dir=sim_build
    )

    runner.test(
        python_search=[tests_dir],
        toplevel="wb_uart",
        py_module="test_uart",
    )