ZIRCON_PATH := $(abspath ../Zircon)
LLVM_PATH := $(abspath ../llvm-project/build/Debug)

COMPILER := $(ZIRCON_PATH)/bin/zirconc.exe
OTHER_COMPILER := $(abspath bin/zirconc.exe)
INCLUDE := $(ZIRCON_PATH)/include

default: simulate

bin/zas.exe: $(wildcard src/Assembler/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Assembler/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -lucrt -DASSEMBLER

bin/zda.exe: $(wildcard src/Disassembler/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Disassembler/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -lucrt -DDISASSEMBLER

bin/zar.exe: $(wildcard src/Archiver/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Archiver/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -lucrt -DARCHIVER

bin/zld.exe: $(wildcard src/Linker/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Linker/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -lucrt -DLINKER

bin/zemu.exe: $(wildcard src/Emulator/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Emulator/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -lucrt -lvcruntime -DEMULATOR

bin/zym.exe: $(wildcard src/Symbols/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Symbols/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -lucrt -DSYMBOLS

bin/ztr.exe: $(wildcard src/Strings/*.zir) $(wildcard src/Common/*.zir)
	$(COMPILER) src/Strings/Main.zir -o $@ -I$(INCLUDE) -lDbgHelp -lucrt -DSTRINGS

$(OTHER_COMPILER): $(wildcard $(ZIRCON_PATH)/src/*.zir)
	cd $(ZIRCON_PATH) && $(COMPILER) src/Main.zir -o $@ -I$(INCLUDE) -L$(LLVM_PATH)/lib -lLLVM-C -lDbgHelp -DZODIAC -g -v

boot.o: bin/zas.exe boot.s
	$^ -o $@

boot.hex: bin/zld.exe boot.o
	$^ -o $@ --format=hex

start.o: bin/zas.exe start.s
	$^ -o $@

program.s: $(OTHER_COMPILER) program.zir
	set PATH=$(LLVM_PATH)/bin;%PATH% && $^ -o $@ -S -ffreestanding -target zodiac

program.o: program.s
	bin/zas.exe $< -o $@

program.bin: bin/zld.exe start.o program.o
	$^ -o $@ --format=bin --origin=0x40000000

program.hex: bin/zld.exe start.o program.o
	$^ -o $@ --format=hex

ram.sv: boot.hex program.hex

sim.out: $(filter-out top.sv, $(wildcard *.sv))
	iverilog -o $@ -g2012 $^

wave.fst: sim.out boot.hex program.hex
	vvp $< -fst

build: boot.hex program.bin program.hex

simulate: wave.fst
	gtkwave $<

emulate: bin/zemu.exe program.bin
	$^

all: bin/zas.exe bin/zda.exe bin/zar.exe bin/zld.exe bin/zemu.exe bin/zym.exe bin/ztr.exe

bin/Count.exe: scripts/Count.zir
	$(COMPILER) $< -o $@ -I$(INCLUDE)

count: bin/Count.exe
	$<

clean:
	del /Q sim.out wave.fst boot.o boot.hex start.o program.o program.bin program.hex
	del /Q bin\*
