`include "pu/pu.vh"
module dmem #(parameter [1:0] pu_num)( // Data Memory
	input [`DMSB:0] ad,
	input [`WIDTH:0] wd,
	input [`PORT:0] port,
	input we, send,
	output logic [`WIDTH:0] rd,
	input logic [`PKTW:0] rx, output logic [`PKTW:0] tx,
	input clk, input rst);

	// ad & wd are also used for address & size of transfer

	logic [`WIDTH:0] dm [`DMS:0];
	logic [`DMSB+1:0] rx_addr;

	assign rd = dm[ad];

	always @(posedge clk) begin
		if (rst) begin
			rx_addr <= 0;
		end else begin
			if (we)
				dm[ad] <= wd;

			if (rx[`FLOWBH:`FLOWBL] == `BODY) begin
				if (rx_addr[0] == 0)
					dm[rx_addr[`DMSB:1]][`FLOWBL-1:0] <= rx[`FLOWBL-1:0];
				else begin
					dm[rx_addr[`DMSB:1]][`WIDTH:`FLOWBL] <= rx[`FLOWBL-1:0];
				end
				$display("PU%d: received 0x%x at 0x%x(%d)", pu_num, rx[`FLOWBL-1:0], rx_addr[`DMSB+1:1], rx_addr[0]);
				rx_addr <= rx_addr+1;
			end
		end
	end

	enum logic [1:0]{INIT, SENDING} state;
	logic [`DMSB+1:0] curr_addr;
	logic [`DMSB:0] curr_size;
	always @(posedge clk or posedge rst) begin
		if (rst) state <= INIT;
		else begin
			case(state)
			INIT:
				if (send) begin
					curr_addr <= {ad, 1'b0};
					curr_size <= {wd[`DMSB:0], 1'b0};
					tx <= {`HEAD, {(`FLOWBL-1-`PORT){1'b0}}, port};
					$display("PU%d: sending HEAD to %d", pu_num, port);
					state <= SENDING;
				end else
					tx <= 0;
			SENDING: begin
				if (send) $display("PU%d: SEND inst. is executed while transferring", pu_num);
				if (curr_size == 0) begin
					tx <= {`TAIL, {(`PKTW+1){1'b0}}};
					$display("PU%d: sending TAIL", pu_num);
					state <= INIT;
					curr_addr <= 0;
					curr_size <= 0;
				end else begin
					if (curr_addr[0] == 0) begin
						tx <= {`BODY, dm[curr_addr[`DMSB+1:1]][`FLOWBL-1:0]};
						$display("PU%d: sending %x", pu_num, dm[curr_addr[`DMSB+1:1]][`FLOWBL-1:0]);
					end else begin
						tx <= {`BODY, dm[curr_addr[`DMSB+1:1]][`WIDTH:`FLOWBL]};
						$display("PU%d: sending %x", pu_num, dm[curr_addr[`DMSB+1:1]][`WIDTH:`FLOWBL]);
					end
					curr_addr = curr_addr+1;
					curr_size = curr_size-1;
				end
			end
			endcase
		end
	end
endmodule
