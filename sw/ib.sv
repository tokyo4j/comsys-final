`include "sw/sw.vh"
module ib(input [`PKTW:0] pkti, output [`PKTW:0] pkto, output [`PORT:0] req, input ack,
	output full, input clk, rst);
	logic [`PORT:0] reqi;
	logic [`PKTW:0] pkto2;
	mkwe mkwe(pkti, we);
	fifo fifo(pkti, we, full, pkto, pkto2, re, empty, clk, rst);
	isbm isbm(pkto[`FLOWBH:`FLOWBL], re, empty, reqi, req, ack, clk, rst);
	mkreq mkreq(pkto, pkto2, reqi, clk, rst);
endmodule

