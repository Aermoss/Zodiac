default: run

ram.sv: assembler.py program.s
	python3 $^

sim.out: ram.sv alu.sv cpu.sv tb.sv
	iverilog -o $@ -g2012 $^

dump.vcd: sim.out
	vvp $<

run: dump.vcd
	gtkwave -S $< cpu.gtkw

clean:
	rm -f sim.out dump.vcd