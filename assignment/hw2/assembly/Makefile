.PHONY: clean

include ../../../mk/toolchain.mk

ASFLAGS = -march=rv32i_zicsr_zifencei -mabi=ilp32 
LDFLAGS = --oformat=elf32-littleriscv -O2

%.o: %.S
	$(CROSS_COMPILE)as -R $(ASFLAGS) -o $@ $<

all: main.elf

main.elf: main.o 
	 $(CROSS_COMPILE)ld -o $@ -T main.ld $(LDFLAGS) $<

clean:
	$(RM) main.elf main.o

