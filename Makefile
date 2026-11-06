ZIRCON_PATH := $(abspath ../Zircon)
LLVM_PATH := $(abspath ../llvm-project)

COMPILER := $(ZIRCON_PATH)/bin/zirconc.exe
TRANSPILER := $(ZIRCON_PATH)/bin/zirgen.exe
INCLUDE := $(ZIRCON_PATH)/include

default: simulate

bin/svarog-as.exe: $(wildcard src/Assembler/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Assembler/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -DASSEMBLER

bin/svarog-objdump.exe: $(wildcard src/Disassembler/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Disassembler/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -DDISASSEMBLER

bin/svarog-ar.exe: $(wildcard src/Archiver/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Archiver/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -DARCHIVER

bin/svarog-ld.exe: $(wildcard src/Linker/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Linker/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -DLINKER

bin/svarog-emu.exe: $(wildcard src/Emulator/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Emulator/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -lucrt -DEMULATOR

bin/svarog-nm.exe: $(wildcard src/Symbols/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Symbols/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -DSYMBOLS

bin/svarog-strings.exe: $(wildcard src/Strings/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Strings/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -DSTRINGS

%.o: bin/svarog-as.exe %.s
	$^ -o $@

boot.hex: bin/svarog-ld.exe boot.o
	$^ -o $@ --format=hex

program.s: program.zir
	$(COMPILER) $< -o $@ -S -target svarog -emit-hir -emit-mir -emit-lir

program.bin: bin/svarog-ld.exe start.o program.o end.o
	$^ -o $@ --format=bin --origin=0x40000000

program.hex: bin/svarog-ld.exe start.o program.o end.o
	$^ -o $@ --format=hex

ram.sv: boot.hex program.hex

sim.out: $(filter-out top.sv, $(wildcard *.sv))
	iverilog -o $@ -g2012 $^

wave.fst: sim.out boot.hex program.hex
	vvp $< -fst

build: boot.hex program.bin program.hex

simulate: wave.fst
	gtkwave $<

emulate: bin/svarog-emu.exe boot.hex program.bin
	$< boot.hex --flash=program.bin

all: bin/svarog-as.exe bin/svarog-objdump.exe bin/svarog-ar.exe bin/svarog-ld.exe bin/svarog-emu.exe bin/svarog-nm.exe bin/svarog-strings.exe

bin/Count.exe: scripts/Count.zir
	$(COMPILER) $< -o $@ -I$(INCLUDE)

count: bin/Count.exe
	$<

clean:
	del /Q *.out *.fst *.o *.bin *.hex bin\*.exe *.hir *.mir *.lir
