SRCS = \
	sw/ackor.sv \
	sw/arb.sv \
	sw/cb.sv \
	sw/cbsel.sv \
	sw/fifo.sv \
	sw/ib.sv \
	sw/ibsm.sv \
	sw/mkreq.sv \
	sw/mkwe.sv \
	sw/sw.sv \
	pu/alu.sv \
	pu/dec.sv \
	pu/dmem.sv \
	pu/imem.sv \
	pu/imx.sv \
	pu/pc.sv \
	pu/pu.sv \
	pu/ra.sv \
	pu/sel.sv \
	top.sv

DEPS = $(SRCS) \
	test.sv \
	inst/asm.py \
	inst/primary.inst \
	inst/secondary.inst \
	pu/pu.vh \
	sw/sw.vh \
	top.ys

a.out: $(DEPS)
	iverilog -g2012 $(SRCS) test.sv

inst/primary.inst: inst/primary.txt inst/msort.txt
	python inst/asm.py $^ $@

inst/secondary.inst: inst/secondary.txt inst/msort.txt
	python inst/asm.py $^ $@

.PHONY: wave
wave:
	gtkwave top.vcd

.PHONY: yosys
yosys:
	yosys top.ys
gate.v synth.v:
	yosys top.ys

.PHONY: clean
clean:
	rm -f a.out *.vcd inst/*.inst
