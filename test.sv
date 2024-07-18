`timescale 1ns/10ps
module test;
	logic clk, rst;
	top top(clk, rst);
	always #5 clk = ~clk;
	initial begin
		$dumpfile("top.vcd");
		$dumpvars(0, test);
		clk = 0;
		rst = 1;
		#20
		rst = 0;
		#1000
		$finish();
	end

endmodule
