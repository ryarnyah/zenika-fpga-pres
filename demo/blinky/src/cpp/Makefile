VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
BASE=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

VMOD := top
VOBJDR	:= $(BASE)/obj_dir
VSOURCES := $(BASE)/../main/$(VMOD).sv
VTLIB := $(VOBJDR)/V$(VMOD)__ALL.a
VLIB := $(BASE)/../main

CXX = g++
CPPFLAGS := -Og -g -Wall -faligned-new

all: top_tb

.PHONY: $(VTLIB)
$(VTLIB): 
	verilator -O3 -Wall --MMD -trace -y $(VLIB) --Mdir $(VOBJDR) -cc $(VSOURCES)
	make --no-print-directory -C $(VOBJDR) -f V$(VMOD).mk

top_tb.o: $(VTLIB)
	$(CXX) $(CPPFLAGS) -I$(VERILATOR_ROOT)/include -I$(VOBJDR) -c top_tb.cpp -o top_tb.o

verilated.o:
	$(CXX) $(CPPFLAGS) -I$(VERILATOR_ROOT)/include -c $(VERILATOR_ROOT)/include/verilated.cpp -o verilated.o

verilated_vcd_c.o:
	$(CXX) $(CPPFLAGS) -I$(VERILATOR_ROOT)/include -c $(VERILATOR_ROOT)/include/verilated_vcd_c.cpp -o verilated_vcd_c.o

top_tb: verilated_vcd_c.o verilated.o top_tb.o
	$(CXX) $(CPPFLAGS) -I$(VERILATOR_ROOT)/include -I$(VOBJDR) top_tb.o verilated.o verilated_vcd_c.o $(VTLIB) -o top_tb

.PHONY: run
run: top_tb
	./top_tb

.PHONY: clean
clean:
	rm -fr $(VOBJDR) *.o top_tb
