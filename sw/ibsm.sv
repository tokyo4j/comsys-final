`include "sw/sw.vh"

module isbm(input [1:0] pout, output logic re, input empty, input ack, input clk, rst);
	logic state, nstate;

	always @(posedge clk) begin
		if (rst) state <= `INIT;
		else state <= nstate;
	end

	always_comb begin
		nstate = state; // necessary for RESET
		re = `NEGATE;	// output re should be negate so I am NOT in transfer mode.
		case(state)

		`INIT: begin
			if (ack == `ASSERT) begin	// Request is approved!
				nstate = `XFER;		// Let's gooooo
				re = `ASSERT;		// transfer mode
			end
		end

		`XFER: begin
			re = `ASSERT;			// still in transfer mode
			if (pout == `TAIL) begin	// It looks the end of transfer data
				nstate = `INIT;
			end
		end
		endcase
	end
endmodule
