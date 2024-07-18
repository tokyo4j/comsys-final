`include "sw/sw.vh"

module isbm(input [1:0] pout, output logic re, input empty,
	input [`PORT:0] reqi, output logic [`PORT:0] req, input ack, input clk, rst);
	typedef enum logic [1:0] {INIT, AREQ, XFER} ISBMTYPE;
	ISBMTYPE state, nstate;


	// INIT -> REQ and awaiting ACK -> TRANSFER -> INIT

	always @(posedge clk) begin	// so we ensure the synchronization ...
		if (rst) state <= INIT; // ...
		else state <= nstate;	// ... here!
	end

	always_comb begin
		nstate = state; // necessary for RESET
		re = `NEGATE;	// output re should be negate so I am NOT in transfer mode.
		req = 0;	// output req default is no request whatever reqi says.
		case(state)
		INIT: begin
			// re = `NEGATE
			// req = 0; 	// req should be kept 0 until something (i.e. transfer data) comes from pout
					// The beginning of the transfer data should be a HEADER; therefore `HEAD
			if (pout == `HEAD) begin
				nstate = AREQ;
			//	req = reqi;			// Please approve my request!
			//	if (ack == `ASSERT) begin	// Request is approved!
			//		nstate = XFER;		// Let's gooooo
			//		re = `ASSERT;		// transfer mode
			//	end
			end
		end

		AREQ: begin
			// re = `NEGATE
			req = reqi;			// Please approve my request!
			if (ack == `ASSERT) begin	// Request is approved!
				nstate = XFER;		// Let's gooooo
					re = !empty;		// transfer mode
			end
		end

		XFER: begin
			re = !empty;			// still in transfer mode
			req = reqi;			// Keep my request until the transfer has completed

			if (pout == `TAIL) begin	// It looks the end of transfer data
				nstate = INIT;		// Go back to INIT
				// re = `ASSERT;	// <- should be ASSERT to transfer the last data.
				// req = 0;		// <- ditto
			end
		end
		endcase
	end
endmodule
