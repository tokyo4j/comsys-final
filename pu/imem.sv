`include "pu/pu.vh"
module imem #(parameter [1:0] pu_num)( // Instruction Memory
	input [`PCS:0] pc,
	output logic [`CMDS:0] o);
	always_comb
		if (pu_num == 0)
			case(pc)
			// synopsys full_case parallel_case
			5'h00: o = 16'b0000_0000_0000_0000; // NOP

			// Send second 64 numbers to PU1
			5'h01: o = 16'b0000_0100_0100_0000; // LI r0, 64
			5'h02: o = 16'b0000_0101_0100_0000; // LI r1, 64
			5'h03: o = 16'b0000_1100_0001_0001; // SEND r0, r1, 1  // address, size, port
			// Wait for transfer to finish
			5'h04: o = 16'b0000_0100_0100_0000; // LI r0, 64
			5'h05: o = 16'b1101_0000_0000_0001; // SUB r0=r0,1
			5'h06: o = 16'b0010_0001_1111_1111; // BR NZ [PC-1]

			// Send third 64 numbers to PU2
			5'h07: o = 16'b0000_0100_1000_0000; // LI r0, 128
			5'h08: o = 16'b0000_0101_0100_0000; // LI r1, 64
			5'h09: o = 16'b0000_1100_0001_0010; // SEND r0, r1, 2  // address, size, port
			// Wait for transfer to finish
			5'h0a: o = 16'b0000_0100_0100_0000; // LI r0, 64
			5'h0b: o = 16'b1101_0000_0000_0001; // SUB r0=r0,1
			5'h0c: o = 16'b0010_0001_1111_1111; // BR NZ [PC-1]

			// Send forth 64 numbers to PU3
			5'h0d: o = 16'b0000_0100_1100_0000; // LI r0, 192
			5'h0e: o = 16'b0000_0101_0100_0000; // LI r1, 64
			5'h0f: o = 16'b0000_1100_0001_0011; // SEND r0, r1, 3  // address, size, port
			// Wait for transfer to finish
			5'h10: o = 16'b0000_0100_0100_0000; // LI r0, 64
			5'h11: o = 16'b1101_0000_0000_0001; // SUB r0=r0,1
			5'h12: o = 16'b0010_0001_1111_1111; // BR NZ [PC-1]

			default: o = 16'b0000_0000_0000_0001; // HALT
			endcase
		else
			case(pc)
			// synopsys full_case parallel_case
			default: o = 16'b0000_0000_0000_0001; // HALT
			endcase
endmodule
