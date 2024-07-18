`timescale 1ns/10ps
module test;
	logic clk, rst;
	top top(clk, rst);
	always #5 clk = ~clk;

	// always @(posedge clk) begin
	// 		$write("  ");
	// 		for (integer i = 0; i < 16; i = i + 1)
	// 			$write("%h ", top.pu0.dmem.dm[i]);
	// 		$write(" | ");
	// 		for (integer i = 0; i < 16; i = i + 1)
	// 			$write("%h ", top.pu0.dmem.dm[i+16]);
	// 		$write("\n");
	// 	end

	initial begin
		$dumpfile("top.vcd");
		$dumpvars(0, top);
		$readmemh("data/1.txt", top.pu0.dmem.dm, 0, 255);

		clk = 0;
		rst = 1;
		#20
		rst = 0;
		#101100
		for (integer i = 0; i < 64; i++)
			$display("%d", $signed(top.pu0.dmem.dm[i]));
		$finish();
	end

endmodule
