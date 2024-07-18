`include "pu.vh"
module imem( // Instruction Memory
	input [`PCS:0] pc,
	output logic [`CMDS:0] o);
	always_comb
		case(pc)
		// synopsys full_case parallel_case
		5'h00: o = 16'b0000_0000_0000_0000; // NOP

    // store 3,0,2 in memory at 0,1,2
		5'h01: o = 16'b0000_0100_0000_0011; // LI r0, 3
		5'h02: o = 16'b0000_1000_0000_0000; // SM [0]=r0 ; store P(0)=3 at 0
		5'h03: o = 16'b0000_0100_0000_0000; // LI r0, 0
		5'h04: o = 16'b0000_1000_0000_0001; // SM [1]=r0 ; store P(1)=0 at 1
		5'h05: o = 16'b0000_0100_0000_0010; // LI r0, 2
		5'h06: o = 16'b0000_1000_0000_0010; // SM [2]=r0 ; store P(2)=2 at 2

		5'h07: o = 16'b0000_0100_0000_0000; // LI r0, 0

    // loop
		5'h08: o = 16'b1011_0100_0000_0000; // LM r1=[r0+0] ; load P(n-3)
		5'h09: o = 16'b1011_1000_0000_0001; // LM r2=[r0+1] ; load P(n-2)
		5'h0a: o = 16'b0010_1001_0000_0110; // ADD r1=r1+r2
		5'h0b: o = 16'b1001_0001_0000_0011; // SM [r0+3]=r1 ; store P(n)

		5'h0c: o = 16'b1100_0000_0000_0001; // ADD r0=r0+1 ; increment address

    // loop until r0+3==16
		5'h0d: o = 16'b1101_0100_0000_1101; // SUB r1=r0,13
		5'h0e: o = 16'b0010_0001_1111_1010; // BR NZ [PC-6]

    // calculate sum

    5'h0f: o = 16'b0000_0100_0000_0000; // LI r0, 0
    5'h10: o = 16'b0000_0110_0000_0000; // LI r2, 0
    // loop
		5'h11: o = 16'b1011_0100_0000_0000; // LM r1=[r0+0]
		5'h12: o = 16'b0010_1010_0000_0110; // ADD r2=r1+r2 ; store sum in r2

		5'h13: o = 16'b1100_0000_0000_0001; // ADD r0=r0+1 ; increment address

    // loop until r0==16
		5'h14: o = 16'b1101_0100_0001_0000; // SUB r1=r0,16
		5'h15: o = 16'b0010_0001_1111_1100; // BR NZ [PC-4]

		5'h16: o = 16'b1001_0010_0000_0000; // SM [r0+0]=r2

		default: o = 16'b0000_0000_0000_0001; // HALT
		endcase
endmodule
