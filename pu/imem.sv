`include "pu/pu.vh"
module imem #(parameter [1:0] pu_num=0)( // Instruction Memory
	input [`PCS:0] pc,
	output logic [`CMDS:0] o);
	always_comb
		if (pu_num == 0)
			case(pc)
			// synopsys full_case parallel_case
			`include "inst/primary.inst"
			default: o = 16'b0000_0000_0000_0001; // HALT
			endcase
		else
			case(pc)
			// synopsys full_case parallel_case
			`include "inst/secondary.inst"
			default: o = 16'b0000_0000_0000_0001; // HALT
			endcase
endmodule
