default: simulate

bin/zas.exe: export PATH := C:\Program Files\LLVM\bin;$(PATH)
bin/zas.exe: $(wildcard src/Assembler/*.zir) $(wildcard src/Common/*.zir)
	../Zircon/bin/zirconc.exe src/Assembler/Main.zir -o $@ -I ../Zircon/include -lDbgHelp -lucrt -DASSEMBLER

bin/zda.exe: export PATH := C:\Program Files\LLVM\bin;$(PATH)
bin/zda.exe: $(wildcard src/Disassembler/*.zir) $(wildcard src/Common/*.zir)
	../Zircon/bin/zirconc.exe src/Disassembler/Main.zir -o $@ -I ../Zircon/include -lDbgHelp -lucrt -DDISASSEMBLER

bin/zar.exe: export PATH := C:\Program Files\LLVM\bin;$(PATH)
bin/zar.exe: $(wildcard src/Archiver/*.zir) $(wildcard src/Common/*.zir)
	../Zircon/bin/zirconc.exe src/Archiver/Main.zir -o $@ -I ../Zircon/include -lDbgHelp -lucrt -DARCHIVER

bin/zld.exe: export PATH := C:\Program Files\LLVM\bin;$(PATH)
bin/zld.exe: $(wildcard src/Linker/*.zir) $(wildcard src/Common/*.zir)
	../Zircon/bin/zirconc.exe src/Linker/Main.zir -o $@ -I ../Zircon/include -lDbgHelp -lucrt -DLINKER

bin/zemu.exe: export PATH := C:\Program Files\LLVM\bin;$(PATH)
bin/zemu.exe: $(wildcard src/Emulator/*.zir) $(wildcard src/Common/*.zir)
	../Zircon/bin/zirconc.exe src/Emulator/Main.zir -o $@ -I ../Zircon/include -lDbgHelp -lucrt -lvcruntime -DEMULATOR

bin/zym.exe: export PATH := C:\Program Files\LLVM\bin;$(PATH)
bin/zym.exe: $(wildcard src/Symbols/*.zir) $(wildcard src/Common/*.zir)
	../Zircon/bin/zirconc.exe src/Symbols/Main.zir -o $@ -I ../Zircon/include -lDbgHelp -lucrt -DSYMBOLS

bin/ztr.exe: export PATH := C:\Program Files\LLVM\bin;$(PATH)
bin/ztr.exe: $(wildcard src/Strings/*.zir) $(wildcard src/Common/*.zir)
	../Zircon/bin/zirconc.exe src/Strings/Main.zir -o $@ -I ../Zircon/include -lDbgHelp -lucrt -DSTRINGS

boot.o: bin/zas.exe boot.s
	$^ -o $@

program.o: export PATH := C:\Users\rencb\Documents\GitHub\llvm-project\build\Debug\bin;$(PATH)
program.o: test.zir
	../Zircon/bin/zirconc2.exe $< -o program.s -S -ffreestanding -target zodiac
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

clean:
	rm -f dump.vcd sim.out boot.o program.o program.hex
	rm -rf bin/*
