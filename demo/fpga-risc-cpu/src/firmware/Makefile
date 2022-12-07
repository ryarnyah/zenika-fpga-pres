BASE=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

ARCH=rv32i
ABI=ilp32
OPTIMIZE=-Os

RV = riscv32-elf

RVAS=$(RV)-as
RVLD=$(RV)-ld
RVOBJCOPY=$(RV)-objcopy
RVOBJDUMP=$(RV)-objdump
RVGCC=$(RV)-gcc
RVAR=$(RV)-ar
RVRANLIB=$(RV)-ranlib

all: firmware.hex hello.bin

include $(BASE)../../common/setup.mk
RVTOOLCHAIN_LIB_DIR = $(CONDA_HOME)/envs/$(ENV_NAME)/$(RV)/lib
RVTOOLCHAIN_GCC_LIB_DIR = $(CONDA_HOME)/envs/$(ENV_NAME)/lib/gcc/$(RV)/10.1.0/$(ARCH)/$(ABI)/

# Note: it is also possible to comment this line, and use replacement functions
# for a small subset of libc, see comments in LIBFEMTOC/Makefile. 
RVGCC_LIB= $(RVTOOLCHAIN_LIB_DIR)/libc.a \
           $(RVTOOLCHAIN_LIB_DIR)/libm.a \
	   $(RVTOOLCHAIN_GCC_LIB_DIR)/libgcc.a

RVCFLAGS=$(OPTIMIZE) $(RVINCS) -fno-pic -march=$(ARCH) -mabi=$(ABI) \
         -fno-stack-protector -w -Wl,--no-relax 
        # Note: --no-relax because I'm using gp for fast access to mapped IO.
RVASFLAGS=-march=$(ARCH) -mabi=$(ABI)
RVLDFLAGS=-m elf32lriscv -b elf32-littleriscv --no-relax 
RVCPPFLAGS=-fno-exceptions -fno-enforce-eh-specs

OBJECTS = crt0.o main.o

#Rule to compile C objects
.c.o: $< $(RV_BINARIES)
	$(RVGCC) $(RVCFLAGS) $(RVUSERCFLAGS) -S $<
	$(RVGCC) $(RVCFLAGS) $(RVUSERCFLAGS) -c $<
#Rule to compile ASM objects
.S.o: $< $(RV_BINARIES)
	$(RVAS) $(RVASFLAGS) $(RVUSERASFLAGS) $< -o $@ 

hello.bin: hello.elf
	$(RVOBJCOPY) -O binary $< $@

hello.elf: hello.o crt0-user.o $(RV_BINARIES)
	$(RVLD) $(RVLDFLAGS) -T bram-user.ld hello.o -o $@ $(RVGCC_LIB)

firmware.elf: $(OBJECTS) $(RV_BINARIES)
	$(RVLD) $(RVLDFLAGS) -T bram.ld $(OBJECTS) -o $@ $(RVGCC_LIB)

firmware.bin: firmware.elf
	$(RVOBJCOPY) -O binary $< $@

firmware.hex: firmware.bin
	python3 makehex.py firmware.bin 2048 > firmware.hex

clean:
	rm -f $(OBJECTS) *.elf *.hex *.bin *.s *.o