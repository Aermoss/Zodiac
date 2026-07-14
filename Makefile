COMPILER = "../Zircon/bin/zirconc.exe"
OTHER_COMPILER = "../Zircon/bin/zirconc2.exe"
INCLUDE = "../Zircon/include"

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

boot.o: bin/zas.exe boot.s
	$^ -o $@

program.o: export PATH := C:\Users\rencb\Documents\GitHub\llvm-project\build\Debug\bin;$(PATH)
program.o: test.zir
	$(OTHER_COMPILER) $< -o program.s -S -ffreestanding -target zodiac
	bin/zas.exe program.s -o $@

program.hex: bin/zld.exe boot.o program.o
	$^ -o $@

ram.sv: program.hex

sim.out: $(filter-out top.sv, $(wildcard *.sv))
	iverilog -o $@ -g2012 $^

dump.vcd: sim.out program.hex
	vvp $<

build: program.hex

simulate: dump.vcd
	gtkwave -S $< cpu.gtkw

emulate: bin/zemu.exe program.hex
	$^

all: bin/zas.exe bin/zda.exe bin/zar.exe bin/zld.exe bin/zemu.exe bin/zym.exe bin/ztr.exe

bin/Count.exe: scripts/Count.zir
	$(COMPILER) $< -o $@ -I$(INCLUDE)

count: bin/Count.exe
	$<

clean:
	del /Q dump.vcd sim.out boot.o program.o program.hex
	del /Q bin\*
