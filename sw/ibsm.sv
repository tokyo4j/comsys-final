`include "sw/sw.vh"

module isbm(input [1:0] pout, output logic re, input empty,
	input [`PORT:0] reqi, output logic [`PORT:0] req, input ack, input clk, rst);
	logic state, nstate;


	// INIT -> REQ and awaiting ACK -> TRANSFER -> INIT

	always @(posedge clk) begin	// so we ensure the synchronization ...
		if (rst) state <= `INIT; // ...
		else state <= nstate;	// ... here!
	end

	always_comb begin
		nstate = state; // necessary for RESET
		re = `NEGATE;	// output re should be negate so I am NOT in transfer mode.
		req = 0;	// output req default is no request whatever reqi says.
		case(state)

		`INIT: begin
			if (reqi != 0) begin
				req = reqi;
				if (ack == `ASSERT) begin	// Request is approved!
					nstate = `XFER;		// Let's gooooo
					re = `ASSERT;		// transfer mode
				end
			end
		end

		`XFER: begin
			re = `ASSERT;			// still in transfer mode
			req = reqi;			// Keep my request until the transfer has completed

			if (pout == `TAIL) begin	// It looks the end of transfer data
				nstate = `INIT;
			end
		end
		endcase
	end
endmodule
