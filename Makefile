PATH := C:\Program Files\LLVM\bin;$(PATH)

default: run

bin/zodiac.exe: $(wildcard src/*.zir)
	../Zircon/bin/zirconc.exe src/Main.zir -o bin/zodiac.exe -I ../Zircon/include -lDbgHelp -O0

program.hex: bin/zodiac.exe program.s
	$^

ram.sv: program.hex

sim.out: $(wildcard *.sv)
	iverilog -o $@ -g2012 $^

dump.vcd: sim.out program.hex
	vvp $<

run: dump.vcd
	gtkwave -S $< cpu.gtkw

clean:
	rm -f sim.out dump.vcd