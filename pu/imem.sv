`include "pu/pu.vh"
module imem #(parameter [1:0] pu_num)( // Instruction Memory
	input [`PCS:0] pc,
	output logic [`CMDS:0] o);
	always_comb
		if (pu_num == 0)
			case(pc)
			// synopsys full_case parallel_case
			5'h00: o = 16'b0000_0000_0000_0000; // NOP
			// addr=0x0100 (MMIO region)
			5'h01: o = 16'b0100_0000_0000_0000; // LIL r0,r0,0x00
			5'h02: o = 16'b0101_0000_0000_0001; // LIH r0,r0,0x01
			// packet=0x2_01 (HEAD/port1)
			5'h03: o = 16'b0100_0101_0000_0001; // LIL r1,r1,0x01
			5'h04: o = 16'b0101_0101_0000_0010; // LIH r1,r1,0x02
			5'h05: o = 16'b1001_0001_0000_0000; // SM [r0+0]=r1
			// packet=0x1_ca (BODY/0xca)
			5'h06: o = 16'b0100_0101_1100_1010; // LIL r1,r1,0xca
			5'h07: o = 16'b0101_0101_0000_0001; // LIH r1,r1,0x01
			5'h08: o = 16'b1001_0001_0000_0000; // SM [r0+0]=r1
			// packet=0x1_fe (BODY/0xfe)
			5'h09: o = 16'b0100_0101_1111_1110; // LIL r1,r1,0xfe
			5'h0a: o = 16'b0101_0101_0000_0001; // LIH r1,r1,0x01
			5'h0b: o = 16'b1001_0001_0000_0000; // SM [r0+0]=r1
			// packet=0x3_00 (TAIL)
			5'h0c: o = 16'b0100_0101_0000_0000; // LIL r1,r1,0x00
			5'h0d: o = 16'b0101_0101_0000_0011; // LIH r1,r1,0x02
			5'h0e: o = 16'b1001_0001_0000_0000; // SM [r0+0]=r1

			default: o = 16'b0000_0000_0000_0001; // HALT
			endcase
		else
			case(pc)
			// synopsys full_case parallel_case
			default: o = 16'b0000_0000_0000_0001; // HALT
			endcase
endmodule
