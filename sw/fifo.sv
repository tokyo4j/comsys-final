`include "sw/sw.vh"
module fifo(input [`PKTW:0] in, input we, output logic full,
	output logic [`PKTW:0] out, out2, input re, output logic empty, input clk, rst);
	logic [`FIFOLB:0] head, tail,tail2, headi;
	logic [`PKTW:0] mem [`FIFOL:0];
	logic [`PKTW:0] pout, pout2;
	logic empty2;
	assign tail2 = tail + 1;
	assign pout = mem[tail];
	assign pout2 = mem[tail2];
	always_comb begin
		if(empty2) out2 = 0;
		else begin
			out2 = pout2;
		end
		if(empty) begin 
			out = 0;
			out2 = 0;
		end else begin
			out = pout;
		end
	end
	always @(posedge clk) if(we) mem[head] <= in;

	assign headi = head+1;
	always @(posedge clk) begin
		if(rst) begin
			head <= 0;
			tail <= 0;
		end else begin
			if(we) head <= headi;
			if(re) tail <= tail + 1;
		end
	end
	always_comb begin
		if(head == tail) empty = `ASSERT;
		else empty = `NEGATE;
		if (head == tail2) empty2 = `ASSERT;
		else empty2 = `NEGATE;
		if(headi == tail) full = `ASSERT;
		else full = `NEGATE;
	end
endmodule
