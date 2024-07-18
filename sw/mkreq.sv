`include "sw/sw.vh"
module mkreq(input [`PKTW:0] pkti, pkti2, output logic [`PORT:0] req, input clk, rst);
	logic [`PORT:0] reqp, reqp2;
	always @* begin
		reqp = 0;
		reqp2 = 0;
		reqp[pkti[1:0]] = `ASSERT;
		reqp2[pkti2[1:0]] = `ASSERT;
	end
	always @(negedge clk or posedge rst) begin
		if(rst) req <= 0;
		else begin
			if(pkti[`FLOWBH:`FLOWBL] == `HEAD) req <= reqp;
			if (pkti[`FLOWBH:`FLOWBL] == `TAIL) req <= 0;
			if (pkti2[`FLOWBH:`FLOWBL] == `HEAD) req <= reqp2;
		end
	end
endmodule
