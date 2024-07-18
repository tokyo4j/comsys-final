`include "pu/pu.vh"
module dmem #(parameter [1:0] pu_num)( // Data Memory
	input [`WIDTH:0] ad,
	input [`WIDTH:0] wd,
	input we,
	output logic [`WIDTH:0] rd,
	input logic [`PKTW:0] rx, output logic [`PKTW:0] tx,
	input clk, input rst);

	logic [`WIDTH:0] dm [`DMS:0];
	logic [`DMSB+1:0] rx_addr;

	`define ad_lo ad[`DMSB:0]
	`define ad_hi ad[`WIDTH:`DMSB+1]

	always_comb begin
		if (`ad_hi == 0)
			rd = dm[`ad_lo];
		else
			rd = 0;
	end
	always @(posedge clk) begin
		if (rst) begin
			rx_addr <= 0;
		end else begin
			if (we)
				if (`ad_hi == 0)
					dm[`ad_lo] <= wd;
				else begin
					tx <= wd[`PKTW:0];
					$display("PU%d: sending 0x%x", pu_num, wd[`PKTW:0]);
				end
			else
				tx <= 0;

			if (rx[`FLOWBH:`FLOWBL] == `BODY) begin
				if (rx_addr[0])
					dm[rx_addr[`DMSB:1]][`FLOWBL-1:0] <= rx[`FLOWBL-1:0];
				else begin
					dm[rx_addr[`DMSB:1]][`WIDTH:`FLOWBL] <= rx[`FLOWBL-1:0];
				end
				$display("PU%d: received 0x%x at 0x%x(%d)", pu_num, rx[`FLOWBL-1:0], rx_addr[`DMSB+1:1], rx_addr[0]);
				rx_addr <= rx_addr+1;
			end
		end
	end
endmodule
