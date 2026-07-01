default: run

bin/zas.exe: export PATH := C:\Program Files\LLVM\bin;$(PATH)
bin/zas.exe: $(wildcard src/Assembler/*.zir) $(wildcard src/Common/*.zir)
	../Zircon/bin/zirconc.exe src/Assembler/Main.zir -o $@ -I ../Zircon/include -lDbgHelp -lucrt -O0 -DASSEMBLER

bin/zld.exe: export PATH := C:\Program Files\LLVM\bin;$(PATH)
bin/zld.exe: $(wildcard src/Linker/*.zir) $(wildcard src/Common/*.zir)
	../Zircon/bin/zirconc.exe src/Linker/Main.zir -o $@ -I ../Zircon/include -lDbgHelp -lucrt -O0 -DLINKER

boot.o: bin/zas.exe boot.s
	$^ -o $@

program.o: export PATH := C:\Users\rencb\Documents\GitHub\llvm-project\build\Debug\bin;$(PATH)
program.o: test.zir
	../Zircon/bin/zirconc2.exe $< -o program.s -S -ffreestanding -O0 -target zodiac
	bin/zas.exe program.s -o $@

program.hex: bin/zld.exe boot.o program.o
	$^ -o $@

ram.sv: program.hex

sim.out: $(filter-out top.sv, $(wildcard *.sv))
	iverilog -o $@ -g2012 $^

dump.vcd: sim.out program.hex
	vvp $<

run: dump.vcd
	gtkwave -S $< cpu.gtkw

build: program.hex

clean:
	rm -f dump.vcd sim.out program.hex bin/zld.exe boot.o program.o bin/zas.exe
