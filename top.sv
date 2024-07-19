module top(input clk, rst);
	logic [`PKTW:0] i0, i1, i2, i3;
	logic [`PKTW:0] o0, o1, o2, o3;

	pu #(2'h0) pu0(clk, rst, o0, i0);
	pu #(2'h1) pu1(clk, rst, o1, i1);
	pu #(2'h2) pu2(clk, rst, o2, i2);
	pu #(2'h3) pu3(clk, rst, o3, i3);
	sw sw(i0, i1, i2, i3, o0, o1, o2, o3, clk, rst);

endmodule
