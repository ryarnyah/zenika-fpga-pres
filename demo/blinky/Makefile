current_dir := ${CURDIR}
XDC = ${current_dir}/common/basys3.xdc
SIMULATIONS := ${current_dir}/src/sim/*.sv
FORMALS := ${current_dir}/src/formal/*.sby
TARGET := basys3
TOP := top
SOURCES := ${current_dir}/src/main/top.sv

.PHONY: all
all: vsim

.PHONY: sim
sim: clean target $(SIMULATIONS)

.PHONY: $(SIMULATIONS)
$(SIMULATIONS): 
	$(CONDA_ACTIVATE) iverilog -g 2012 -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=10 -DCPU_FREQ=10 -o target/sim.vvp -I "${current_dir}/src/main" ${SOURCES} $@
	$(CONDA_ACTIVATE) vvp target/sim.vvp

.PHONY: vsim
vsim:
	$(CONDA_ACTIVATE) make -C src/cpp run

target:
	mkdir -p target

.PHONY: clean
clean:
	$(CONDA_ACTIVATE) make -C src/cpp clean
	find . -name "*.vvp" -delete
	rm -fr src/test/sim_build src/test/__pycache__

fclean: clean
	rm -fr target

.PHONY: formal
formal: $(FORMALS)

.PHONY: $(FORMALS)
$(FORMALS):
	$(CONDA_ACTIVATE) sby -f $@ -t

include ${current_dir}/common/common.mk

include ${current_dir}/common/setup.mk
CONDA_ACTIVATE = . $$($(CONDA) info --base)/etc/profile.d/conda.sh ; conda activate xc7 ;

F4PGA_PACKAGES = install-xc7 xc7a50t_test
F4PGA_TIMESTAMP = 20220920-124259
F4PGA_HASH = 007d1c1

.PHONY: setup
setup: .setup-conda .setup-f4pga

.setup-conda:
	make install-conda
	touch .setup-conda

.setup-f4pga:
	for PKG in $(F4PGA_PACKAGES); do \
	wget -qO- https://storage.googleapis.com/symbiflow-arch-defs/artifacts/prod/foss-fpga-tools/symbiflow-arch-defs/continuous/install/$(F4PGA_TIMESTAMP)/symbiflow-arch-defs-$$PKG-$(F4PGA_HASH).tar.xz | tar -xJC $(CONDA_HOME)/envs/$(ENV_NAME); \
	done
	touch .setup-f4pga
