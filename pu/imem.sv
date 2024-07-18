`include "pu/pu.vh"
module imem #(parameter [1:0] pu_num)( // Instruction Memory
	input [`PCS:0] pc,
	output logic [`CMDS:0] o);
	always_comb
		if (pu_num == 0)
			case(pc)
			// synopsys full_case parallel_case
			5'h00: o = 16'b0000_0000_0000_0000; // NOP

			// send 0x1234,5678
			5'h01: o = 16'b0100_0000_0001_0010; // LIL r0,r0 0x12
			5'h02: o = 16'b0101_0000_0011_0100; // LIH r0,r0 0x34
			5'h03: o = 16'b0000_1000_0000_0101; // SM [5]=r0
			5'h04: o = 16'b0100_0000_0101_0110; // LIL r0,r0 0x56
			5'h05: o = 16'b0101_0000_0111_1000; // LIH r0,r0 0x78
			5'h06: o = 16'b0000_1000_0000_0110; // SM [6]=r0
			5'h07: o = 16'b0000_0100_0000_0101; // LI r0, 5 (addr)
			5'h08: o = 16'b0000_0101_0000_0010; // LI r1, 2 (size)
			5'h09: o = 16'b0000_1100_0001_0001; // SEND r0(addr), r1(size), 1(port)

			default: o = 16'b0000_0000_0000_0001; // HALT
			endcase
		else
			case(pc)
			// synopsys full_case parallel_case
			default: o = 16'b0000_0000_0000_0001; // HALT
			endcase
endmodule
