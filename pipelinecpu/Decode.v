`include "Defines.v"
module Decode (
	input											clk,
	input											reset,
	input		[`InstrWidth-1:0]	instr, // InstrWidth = 32
	input		[`AddrWidth-1:0]	pcReadData, // AddrWidth = 32
	output	[`DataWidth-1:0]	pcWriteData, // DataWidth = 32
	output	[`PCOpWidth-1:0]	pcOp // PCOpWidth = 2
);

reg		[`OpcodeWidth-1:0]		opcode[1:0]; /* = instr[6:0]; */ // OpcodeWidth = 7
reg		[`Func3Width-1:0]			func3[1:0]; /* = instr[14:12]; */ // Func3Width = 3
reg		[`Func7Width-1:0]			func7[1:0]; /* = instr[31:25]; */ // Func7Width = 7
reg		[`RegNumWidth-1:0]		regWriteNum[3:0]; /* = instr[11:7]; */ // RegNumWidth = 5
wire	[`RegNumWidth-1:0]		regNum0 = instr[19:15];
wire	[`RegNumWidth-1:0]		regNum1 = instr[24:20];
wire  [`DataWidth-1:0]			regReadData0;
wire  [`DataWidth-1:0]			regReadData1;
wire												regWriteEnable;
wire  [`DataWidth-1:0]			regWriteData;

RegsFile RF( 
  clk, reset, regNum0, regNum1, regReadData0, regReadData1, 
  regWriteEnable, regWriteNum[0], regWriteData
);

reg		[`DataWidth-1:0]			imm[1:0];
reg		[`DataWidth-1:0]			regOutData0[1:0];
reg		[`DataWidth-1:0]			regOutData1[2:0];

always @(*)
begin
	case({instr[6:0]}) // opcode
		7'b0010011, 7'b1100111, 7'b0000011:	// FMT I
			case({instr[14:12]}) // func3
				3'b001, 3'b101: 
					imm[1] = { 20'b0, instr[31:20] };
				default:
					imm[1] = { { 20{ instr[31] } }, instr[31:20] };
			endcase
		7'b0100011:	// FMT S
			imm[1]	= { { 20{ instr[31] } }, instr[31:25], instr[11:7] };
		7'b1100011: // FMT B
			imm[1] = { { 20{ instr[31] } }, instr[7], instr[30:25], instr[11:8], 1'b0 };
		7'b0010111, 7'b0110111: // FMT U
			imm[1] = { instr[31:12], 12'b0 };
		7'b1101111: // FMT J
			imm[1] = { { 13{ instr[31] } }, instr[19:12], instr[20], instr[30:21], 1'b0 };
		default:
			imm[1] = 32'bz;
	endcase
	opcode[1] = instr[6:0];
	func3[1] = instr[14:12];
	func7[1] = instr[31:25];
	regWriteNum[3] = instr[11:7];
	regOutData0[1] = forwardA ? regWriteData : regReadData0;
	regOutData1[2] = regReadData1;
end

always @(posedge clk)
begin
	opcode[0] <= opcode[1];
	func3[0] <= func3[1];
	func7[0] <= func7[1];
	regWriteNum[2] <= regWriteNum[3];
	regWriteNum[1] <= regWriteNum[2];
	regWriteNum[0] <= regWriteNum[1];
	imm[0] <= imm[1];
	regOutData0[0] <= regOutData0[1];	
	regOutData1[1] <= regOutData1[2];	
	regOutData1[0] <= regOutData1[1];	
end

Execute EX(
	clk, reset, opcode[0], func3[0],func7[0], 
	regOutData0[0], regOutData1[1], regOutData1[0], regWriteEnable, regWriteData, 
	imm[0], pcReadData, pcWriteData, pcOp
);

wire forwardA, forwardB;
Forward Forwarding(
	regNum0, regNum1, regWriteNum, forwardA, forwardB
);
endmodule;
