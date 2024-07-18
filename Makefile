SRCS = \
	sw/sw.sv \
	sw/ib.sv \
	sw/ibsm.sv \
	sw/fifo.sv \
	sw/mkreq.sv \
	sw/mkwe.sv \
	sw/arb.sv \
	sw/cb.sv \
	sw/cbsel.sv \
	sw/ackor.sv \
	pu/pu.sv \
	pu/alu.sv \
	pu/pc.sv \
	pu/imem.sv \
	pu/ra.sv \
	pu/dec.sv \
	pu/imx.sv \
	pu/sel.sv \
	pu/dmem.sv \
	test.sv \
	top.sv

DEPS = $(SRCS) \
	inst/primary.inst \
	inst/secondary.inst

# TESTSRC = test.sv
# ALLSRCS = sw.vh $(SRCS)
# TESTSRCS = $(TESTSRC) $(SRCS)
# VCDFILE = sw.vcd
# YOSYSSCRIPT = sw.ys
# OUTFILE = a.out
# GATEFILE = gate.v
# SYNTHFILE = synth.v
# DOTFILE = show.dot
# CELLFILE = ../osu018_stdcells.v

a.out: $(DEPS)
#	iverilog -g2012 $(SRCS) 2>&1 | grep -v -e "sorry:" -e "warning: System task"
	iverilog -g2012 $(SRCS)

inst/primary.inst: inst/primary.txt inst/msort.txt
	python inst/asm.py $^ $@

inst/secondary.inst: inst/secondary.txt inst/msort.txt
	python inst/asm.py $^ $@

.PHONY: wave
wave:
	gtkwave top.vcd

.PHONY: clean
clean:
	rm -f a.out *.vcd inst/*.inst
