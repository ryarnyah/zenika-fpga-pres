VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
BASE=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

VMOD := soc
VOBJDR	:= $(BASE)/obj_dir
VSOURCES := $(BASE)/../main/$(VMOD).sv
VTLIB := $(VOBJDR)/V$(VMOD)__ALL.a
VLIB := $(BASE)/../main

CXX = g++
CPPFLAGS := -Og -g -Wall -faligned-new

all: soc_tb

.PHONY: $(VTLIB)
$(VTLIB): 
	verilator -GCLOCK_RATE_HZ=10000000 -O3 -Wall --MMD -trace -y $(VLIB) --Mdir $(VOBJDR) -cc $(VSOURCES)
	make --no-print-directory -C $(VOBJDR) -f V$(VMOD).mk

soc_tb.o: $(VTLIB)
	$(CXX) $(CPPFLAGS) -I$(VERILATOR_ROOT)/include -I$(VOBJDR) -c soc_tb.cpp -o soc_tb.o

verilated.o:
	$(CXX) $(CPPFLAGS) -I$(VERILATOR_ROOT)/include -c $(VERILATOR_ROOT)/include/verilated.cpp -o verilated.o

verilated_vcd_c.o:
	$(CXX) $(CPPFLAGS) -I$(VERILATOR_ROOT)/include -c $(VERILATOR_ROOT)/include/verilated_vcd_c.cpp -o verilated_vcd_c.o

uartsim.o:
	$(CXX) $(CPPFLAGS) -I$(VERILATOR_ROOT)/include -c uartsim.cpp -o uartsim.o

soc_tb: uartsim.o verilated_vcd_c.o verilated.o soc_tb.o
	$(CXX) $(CPPFLAGS) -I$(VERILATOR_ROOT)/include -I$(VOBJDR) soc_tb.o uartsim.o verilated.o verilated_vcd_c.o $(VTLIB) -o soc_tb

.PHONY: run
run: soc_tb
	python3 build.py hello.bin hello-sim.bin
	cat hello-sim.bin | ./soc_tb

.PHONY: clean
clean:
	rm -fr $(VOBJDR) *.o soc_tb
