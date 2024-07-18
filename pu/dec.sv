`include "pu/pu.vh"
`define DEBUG
//`define DEBUG2

`define UC 3'b000
`define Z  3'b001
`define NZ 3'b010
`define G  3'b011
`define GE 3'b100

module dec #(parameter pu_num)( // Decoder
	input [`CMDS:0] o,
	output logic h, we,
	output logic [`RASB:0] wad,
	output logic [`ALUOPS:0] op,
	output logic [`RASB:0] rb, ra,
	output logic [`IMXOPS:0] liop,
	output logic [`HALFWIDTH:0] iv,
	output logic pcwe, dmwe, dms, pcs, send,
	input zf, cf, sf, of // same as x86's flags
);
/*

F E D C B A 9 8 7 6 5 4 3 2 1 0
0 0 0 0 0 0 0 0 0 0 0 0 * * * 0 ; NOP (0)
0 0 0 0 0 0 0 0 0 0 0 0 * * * 1 ; HALT (1)
0 0 0 0 0 0 0 1 op----> a-> b-> ; EVA CAL ra,rb/CMP ra,rb
0 0 0 0 0 1 rw> im------------> ; LI rw,(s)im
0 0 0 0 1 0 b-> im------------> ; SM [(s)im]=rb
0 0 0 0 1 1 * * a-> b-> im----> ; SEND addr(a), size(b), port(im)
0 0 0 1 0(f f f)op----> a-> b-> ; JP/BR flag [ra op rb] (fff:UC,Z,NZ,G,GE)
0 0 0 1 1(f f f)im------------> ; JP/BR flag [(s)im]
0 0 1 0 0(f f f)im------------> ; JP/BR flag [PC + (s)im]
0 0 1 0 1 * rw> op----> a-> b-> ; CAL rw=ra,rb
0 1 0 0 rw> b-> im------------> ; LIL rw,rb,im
0 1 0 1 rw> b-> im------------> ; LIH rw,rb,im
0 1 1 0 rw> 0 0 0 0 0 0 0 S C Z ; LI rw,SR S:sign C:carry Z:zero
0 1 1 0 0 0 1 * op----> a-> b-> ; SM [ra]=rb / SM [ra] = [ra op rb]
1 0 0 0 0 0 rw> im------------> ; LM rw=[im]
1 0 0 0 1 # a-> im------------> ; EVA CAL ra,im (#=0:ADD/1:SUB only)
1 0 0 1 a-> b-> im------------> ; SM [ra + (s)im]=rb
1 0 1 0 rw> * 0 op----> a-> b-> ; LM rw=[ra op rb]
1 0 1 1 rw> a-> im------------> ; LM rw=[ra + (s)im]
1 1 0 # rw> a-> im------------> ; CAL rw=ra,im (#=0:ADD/1:SUB only)
1 1 1 a->(f f f)im------------> ; JP/BR flag [ra + (s)im]

F E D C B A 9 8 7 6 5 4 3 2 1 0
0 0 1 0 0 F rw> 1 1 1 1 0 0 b-> ; MV rw=rb
0 0 0 0 1 0 rw> 0 0 0 0 0 0 0 0 ; RESET rw (LI rw=0)
0 0 0 0 0 0 1 0 0 0 0 1 a-> b-> ; CMP ra,rb (EVA SUB ra,rb)
1 1 0 0 rw> rw> 0 0 0 0 0 0 0 1 ; INC rw
1 1 0 1 rw> rw> 0 0 0 0 0 0 0 1 ; DEC rw
1 1 0 0 rw> ra> 0 0 0 0 0 0 0 1 ; INC rw=ra (rw = ra+1)
1 1 0 1 rw> ra> 0 0 0 0 0 0 0 1 ; DEC rw=ra (rw = ra-1)
0 1 1 0 0 0 1 F 1 1 1 1 a-> b-> ; SM [ra]=rb F
1 0 0 1 a-> b-> 0 0 0 0 0 0 0 0 ; SM [ra]=rb
1 0 1 1 rw> a-> 0 0 0 0 0 0 0 0 ; LM rw=[ra]

ADD 4'b0000 SUB 4'b0001 ASR 4'b0010 RSR 4'b0011
RSL 4'b0100 BST 4'b0101 BRT 4'b0110 BTS 4'b0111
AND 4'b1000 OR  4'b1001 NAD 4'b1010 XOR 4'b1011
MUL 4'b1100 EXT 4'b1101 THA 4'b1110 THB 4'b1111

IMS
LIL 2'b00 LIH 2'b01 IMM 2'b10 THU 2'b11

COND(ALU)
UC 2'b00 ZE 2'b01 CA 2'b10 SG 2'b11

flags:
UC 3'000 Z 3'001 NZ 3'010 G 3'011 GE 3'100

*/

	logic flag;
	always @* begin
		flag = `NEGATE;
		case(o[10:8])
		// synopsys full_case parallel_case
		`UC: flag = `ASSERT;
		`Z:  flag = zf;
		`NZ: flag = ~zf;
		`G:  flag = ~zf && (sf == of);
		`GE: flag = (sf == of);
		endcase
	end
	always_comb begin
		h = `NEGATE;
		ra = 0;
		rb = 0;
		op = `THB;
		we = `NEGATE;
		wad = 0;
		liop = `THU;
		iv = 0;
		pcwe = `NEGATE;
		dmwe = `NEGATE;
		dms = `NEGATE;
		pcs = `NEGATE;
		send = `NEGATE;
`ifdef DEBUG
if (pu_num == 0)
	$write("PU%d: %3d PC[%h] r0[%h]1[%h]2[%h]3[%h] [%s%s%s%s] ", pu_num, $realtime, test.top.pu0.pc.pc,
		test.top.pu0.ra.rega[0],
		test.top.pu0.ra.rega[1],
		test.top.pu0.ra.rega[2],
		test.top.pu0.ra.rega[3],
		zf ? "Z" : "-",
		cf ? "C" : "-",
		sf ? "S" : "-",
		of ? "O" : "-",);
else if (pu_num == 1)
	$write("PU%d: %3d PC[%h] r0[%h]1[%h]2[%h]3[%h] [%s%s%s%s] ", pu_num, $realtime, test.top.pu1.pc.pc,
		test.top.pu1.ra.rega[0],
		test.top.pu1.ra.rega[1],
		test.top.pu1.ra.rega[2],
		test.top.pu1.ra.rega[3],
		zf ? "Z" : "-",
		cf ? "C" : "-",
		sf ? "S" : "-",
		of ? "O" : "-",);
else if (pu_num == 2)
	$write("PU%d: %3d PC[%h] r0[%h]1[%h]2[%h]3[%h] [%s%s%s%s] ", pu_num, $realtime, test.top.pu2.pc.pc,
		test.top.pu2.ra.rega[0],
		test.top.pu2.ra.rega[1],
		test.top.pu2.ra.rega[2],
		test.top.pu2.ra.rega[3],
		zf ? "Z" : "-",
		cf ? "C" : "-",
		sf ? "S" : "-",
		of ? "O" : "-",);
else if (pu_num == 3)
	$write("PU%d: %3d PC[%h] r0[%h]1[%h]2[%h]3[%h] [%s%s%s%s] ", pu_num, $realtime, test.top.pu3.pc.pc,
		test.top.pu3.ra.rega[0],
		test.top.pu3.ra.rega[1],
		test.top.pu3.ra.rega[2],
		test.top.pu3.ra.rega[3],
		zf ? "Z" : "-",
		cf ? "C" : "-",
		sf ? "S" : "-",
		of ? "O" : "-",);
`endif
		casex(o)
		// synopsys full_case parallel_case
		16'b0000_0000_0000_xxx0: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 0 0 0 0 0 0 0 0 0 0 0 * * * 0 ; NOP
`ifdef DEBUG
	$display("NOP");
`endif
		end
		16'b0000_0000_0000_xxx1: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 0 0 0 0 0 0 0 0 0 0 0 * * * 1 ; HALT
			h = `ASSERT;
`ifdef DEBUG
	$display("HALT");
`endif
		end
		16'b0000_0000_0100_xxxx: begin
//PUSH rb to ra (op = 100, SUB)
//Not Implemented
		end
		16'b0000_0000_0101_xxxx: begin
//POP rb from ra (op = 000, ADD)
//Not Implemented
		end
		16'b0000_0000_0110_xxxx: begin
//CALL PC to ra (op = 100, SUB)
//Not Implemented
		end
		16'b0000_0000_0111_xxxx: begin
//RET PC to ra (op = 000, ADD)
//Not Implemented
		end
		16'b0000_0001_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 0 0 0 0 0 0 1 op----> a-> b-> ; EVA CAL ra,rb (F=0)/CMP ra,rb
			op = o[7:4];
			ra = o[3:2];
			rb = o[1:0];
`ifdef DEBUG
	$display("EVA CAL op:%h, ra:%h, rb:%h (F=0)/CMP, ra, rb", op, ra, rb);
`endif
		end
		16'b0000_01xx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 0 0 0 0 1 rw> im------------> ; LI rw,(s)im
			wad = o[9:8];
			we = `ASSERT;
			iv = o[`HALFWIDTH:0];
			liop = `IMM;
`ifdef DEBUG
	$display("LI wr:%h (s)im:%h // liop:%h", wad, iv, liop);
`endif
		end
		16'b0000_10xx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 0 0 0 1 0 b-> im------------> ; SM [(s)im]=rb
			rb = o[9:8];
			dmwe = `ASSERT;
			iv = o[`HALFWIDTH:0];
			liop = `IMM;
`ifdef DEBUG
	$display("SM [(s)im:%h]=rb:%h", iv, rb);
`endif
		end
		16'b0000_11xx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 0 0 0 1 1 * * a-> b-> im----> ; SEND addr(a), size(b), port(im)
			ra = o[7:6];
			rb = o[5:4];
			iv = o[3:0];
			op = `THA;
			send = `ASSERT;
`ifdef DEBUG
	$display("SEND addr(a):%h size(b):%h port(im):%h", ra, rb, iv[3:0]);
`endif
		end
		16'b0001_0xxx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 0 0 1 0(f f f)op----> a-> b-> ; JP/BR flag [ra op rb]
			if(flag == `ASSERT) begin
				ra = o[3:2];
				op = o[7:4];
				rb = o[1:0];
				pcwe = `ASSERT;
			end
`ifdef DEBUG
	$display("JP/BR flag:%h(%d) [ra:%h op:%h rb:%h]", o[10:8], flag, ra, op, rb);
`endif
		end
		16'b0001_1xxx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 0 0 1 1(f f f)im------------> ; JP/BR flag [(s)im]
			if(flag == `ASSERT) begin
        iv = o[`HALFWIDTH:0];
        liop = `IMM;
        pcwe = `ASSERT;
			end
`ifdef DEBUG
	$display("JP/BR flag:%h(%d) [liop:%h, (s)IM:%h]", o[10:8], flag, liop, iv);
`endif
		end
		16'b0010_0xxx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 0 1 0 0(f f f)im------------> ; JP/BR pf [PC + (s)im]
			if(flag == `ASSERT) begin
        pcwe = `ASSERT;
        liop = `IMM;
        op = `ADD;
        iv = o[`HALFWIDTH:0];
        pcs = `ASSERT;
			end
`ifdef DEBUG
	$display("JP/BR flag:%h(%d) [PC + liop:%h, (s)IM:%h]", o[10:8], flag, liop, iv);
`endif
		end
		16'b0010_1xxx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 0 1 0 1 * rw> op----> a-> b-> ; CAL rw=ra,rb
      we = `ASSERT;
      wad = o[9:8];
      ra = o[3:2];
      rb = o[1:0];
      op = o[7:4];
`ifdef DEBUG
	$display("CAL rw:%h = ra:%h op:%h rb:%h", wad, ra, op, rb);
`endif
		end
		16'b0100_xxxx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 1 0 0 rw> b-> im------------> ; LIL rw,rb,im
      we = `ASSERT;
      liop = `LIL;
      wad = o[11:10];
      rb = o[9:8];
      iv = o[`HALFWIDTH:0];
`ifdef DEBUG
	$display("LIL wr:%h liop:%h, IM:%h (rb:%h)", wad, liop, iv, rb);
`endif
		end
		16'b0101_xxxx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 1 0 1 rw> b-> im------------> ; LIH rw,rb,im
      we = `ASSERT;
      liop = `LIH;
      wad = o[11:10];
      rb = o[9:8];
      iv = o[`HALFWIDTH:0];
`ifdef DEBUG
	$display("LIH wr:%h liop:%h, IM:%h (rb:%h)", wad, liop, iv, rb);
`endif
		end
		16'b0110_xx00_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 1 1 0 rw> 0 0 0 0 0 0 f f f f ; LI rw,SR (ffff=zf,cf,sf,of)
			wad = o[11:10];
			we = `ASSERT;
			iv = {4'h00, zf, cf, sf, of};
			liop = `IMM;
`ifdef DEBUG
	$display("LI rw:%h, SR liop:%h, IM:%h", wad, liop, iv);
`endif
		end
		16'b0110_001x_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//0 1 1 0 0 0 1 F op----> a-> b-> ; SM [ra]=rb / SM [ra] = [ra op rb] *MM
      dmwe = `ASSERT;
      op = o[7:4];
      ra = o[3:2];
      rb = o[1:0];
`ifdef DEBUG
	$display("SM [ra:%h]= ra:%h op rb:%h F:%h", ra, ra, op, rb);
`endif
		end
		16'b1000_00xx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//1 0 0 0 0 0 rw> im------------> ; LM rw=[im]
			wad = o[9:8];
			we = `ASSERT;
			iv = o[`HALFWIDTH:0];
			liop = `IMM;
			dms = `ASSERT;
`ifdef DEBUG
	$display("LM rw:%h = [liop:%h IM:%h]", wad, liop, iv);
`endif
		end
		16'b1000_1xxx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//1 0 0 0 1 # a-> im------------> ; EVA CAL ra,im (#=0:ADD/1:SUB only)
			iv = o[`HALFWIDTH:0];
			ra = o[9:8];
      op = (o[10] == 0) ? `ADD
                        : `SUB;
      liop = `IMM;
`ifdef DEBUG
	$display("EVA CAL op:%h, ra:%h, im:%h", op, ra, iv);
`endif
		end

		16'b1001_xxxx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//1 0 0 1 a-> b-> im------------> ; SM [ra + (s)im]=rb
      dmwe = `ASSERT;
      ra = o[11:10];
      rb = o[9:8];
      iv = o[`HALFWIDTH:0];
      liop = `IMM;
      op = `ADD;
`ifdef DEBUG
	$display("SM [ra:%h + liop:%h (s)IM:%h] = rb:%h", ra, liop, iv, rb);
`endif
		end
		16'b1010_xxxx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//1 0 1 0 rw> F 0 op----> a-> b-> ; LM rw=[ra op rb]
      we = `ASSERT;
      wad = o[11:10];
      op = o[7:4];
      ra = o[3:2];
      rb = o[1:0];
      dms = `ASSERT;
`ifdef DEBUG
	$display("LM rw:%d = [ra:%h op:%h rb:%h]", wad, ra, op, rb);
`endif
		end
		16'b1011_xxxx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//1 0 1 1 rw> a-> im------------> ; LM rw=[ra + (s)im]
      we = `ASSERT;
      wad = o[11:10];
      ra = o[9:8];
      iv = o[`HALFWIDTH:0];
      liop = `IMM;
      op = `ADD;
      dms = `ASSERT;
`ifdef DEBUG
	$display("LM rw:%h = [ra:%h + liop:%h IM:%h]", wad, ra, liop, iv);
`endif
		end
		16'b110x_xxxx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//1 1 0 # rw> a-> im------------> ; CAL rw=ra,im (#=0:ADD/1:SUB only)
      we = `ASSERT;
      wad = o[11:10];
      ra = o[9:8];
      iv = o[`HALFWIDTH:0];
      op = (o[12] == 0) ? `ADD
                        : `SUB;
      liop = `IMM;
`ifdef DEBUG
	$display("CAL rw:%h = ra:%h, op#:%h IM:%h(#=0:ADD/1:SUB only)", wad, ra, op, iv);
`endif
		end
		16'b111x_xxxx_xxxx_xxxx: begin
//F E D C B A 9 8 7 6 5 4 3 2 1 0
//1 1 1 a->(f f f)im------------> ; JP/BR pf [ra + (s)im]
			if(flag == `ASSERT) begin
        pcwe = `ASSERT;
        ra = o[12:11];
        iv = o[`HALFWIDTH:0];
        op = `ADD;
        liop = `IMM;
			end
`ifdef DEBUG
	$display("JP/BR pf:%h(%d) [ra:%h + liop:%h (s)IM:%h]", o[10:8], flag, ra, liop, iv);
`endif
		end
		endcase
`ifdef DEBUG2
$display("----DEBUG----(%f)", $realtime);
$display("PC[%h]we[%h]CODE:%h", test.top.pu0.pc.pc, pcwe, o);
$display("RA a[%h], b[%h], w[%h](%h)", ra, rb, wad, we);
$display("ALU op[%h], status Z[%h] C[%h] S[%h]", op, ze, ca, sg);
$display("IMX[%h] IM[%h] PCS[%h]", liop, iv, pcs);
$display("DMEM we[%h] sel[%h]", dmwe, dms);
$display("r0[%h]1[%h]2[%h]3[%h]", test.top.pu0.ra.rega[0], test.top.pu0.ra.rega[1],
	test.top.pu0.ra.rega[2], test.top.pu0.re.rega[3]);
$display("-------------");
`endif
	end
endmodule
