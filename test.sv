`timescale 1ns/10ps

task print_mem1;
	for (integer i = 0; i < 16; i = i + 1)
		$write("%h ", test.top.pu0.dmem.dm[i+32]);
	$write(" | ");
	for (integer i = 0; i < 16; i = i + 1)
		$write("%h ", test.top.pu0.dmem.dm[i+32+64]);
	$write("\n");
endtask

task print_mem2;
	for (integer i = 0; i < 256; i++)
		$display("[%d]=%d", i, $signed(test.top.pu0.dmem.dm[i+32]));
endtask

module test;
	logic clk, rst;
	top top(clk, rst);
	always #5 clk = ~clk;

	always @(posedge clk) begin
		// $write("  PU0 ");
		// print_mem1();
		if (top.pu0.pc.pc == 8'h1e) begin
			$display("PU0: partially finished sorting");
			print_mem2();
		end
	end

	initial begin
		$dumpfile("top.vcd");
		$dumpvars(0, top);
		$readmemh("data/1.txt", top.pu0.dmem.dm, 0, 255);
		for (integer i = 255; i >= 0; i--)
			top.pu0.dmem.dm[i+32] = top.pu0.dmem.dm[i];

		clk = 0;
		rst = 1;
		#20
		rst = 0;
		#230500
		print_mem2();
		$finish();
	end

endmodule
