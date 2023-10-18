.PHONY: clean

include ../../../mk/toolchain.mk

CFLAGS = -march=rv32i_zicsr_zifencei -mabi=ilp32 -Wall -O0

OBJS = \
    getcycles.o \
    main.o
BIN = main.elf


%.o: %.s
	$(CROSS_COMPILE)gcc $(CFLAGS) -c -o $@ $<

all: $(BIN)

main.s: main.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -S -o $@ $<

$(BIN): $(OBJS)
	 $(CROSS_COMPILE)gcc -o $@ $^

clean:
	$(RM) $(BIN) $(OBJS) main.s
