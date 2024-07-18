`include "pu.vh"
module pu( // Processing Unit
	output we,
	output [`WIDTH:0] rwd,
	input clk, rst);
	logic [`WIDTH:0] a2sel, b2alu, a2alu, b2imx, loop, dmrd;
	logic [`HALFWIDTH:0] iv;
	logic [`RASB:0] arad, brad, wad;
	logic [`ALUOPS:0] op;
	logic [`PCS:0] pca;
	logic [`CMDS:0] o;
	logic [`IMXOPS:0] liop;
	ra ra(arad, brad, a2sel, b2imx, we, wad, rwd, clk, rst);
	sel asel(a2sel, {{(`WIDTH-`PCS){1'b0}},pca}, pcs, a2alu); // select a2alu (1st input to ALU) from register A or pc based on pcs
	imx imx(b2imx, iv, liop, b2alu); // create b2alu (2nd input to ALU) from immediate and register B based on liop
	alu alu(a2alu, b2alu, op, loop, ze, ca, sg, clk, rst);
	pc pc(h, pca, pcwe, rwd[`PCS:0], clk, rst); // if pcwe is asserted, rwd (ALU result or memory data) is written to pc
	imem imem(pca, o);
	dec dec(o, h, we, wad, op, brad, arad, liop, iv,
		pcwe, dmwe, dms, pcs, ze, ca, sg);
	dmem dmem(loop[`DMSB:0], b2imx, dmwe, dmrd, clk); // read/write memory at ALU result (read into dmrd/write data in register B)
   // read memory at ALU result into dmrd / write register B into memory at at ALU result
	sel dsel(loop, dmrd, dms, rwd); // select rwd (next pc value / new register value) from ALU result or memory data
endmodule
