`include "Defines.v"
module Decode (
	input											clk, reset, flush,
	input		[`AddrWidth-1:0]	PC, // AddrWidth = 32
	input		[`InstrWidth-1:0]	instr, // InstrWidth = 32
	output										hazard, pcWriteEnable,
	output	[`DataWidth-1:0]	pcWriteData // DataWidth = 32
);

reg		[`OpcodeWidth-1:0]		opcode[1:0]; /* = instr[6:0]; */ // OpcodeWidth = 7
reg		[`Func3Width-1:0]			func3[1:0]; /* = instr[14:12]; */ // Func3Width = 3
reg		[`Func7Width-1:0]			func7[1:0]; /* = instr[31:25]; */ // Func7Width = 7
reg		[`RegNumWidth-1:0]		regWriteNum[1:0]; /* = instr[11:7]; */ // RegNumWidth = 5
reg		[`RegNumWidth-1:0]		regNum0[1:0]; /* = instr[19:15]; */
reg		[`RegNumWidth-1:0]		regNum1[1:0]; /* = instr[24:20]; */
reg		[`DataWidth-1:0]			imm[1:0];

always @(*)
begin
	func3[1] = instr[14:12];
	func7[1] = instr[31:25];
	opcode[1] = instr[6:0];
	regNum0[1] = instr[19:15];
	regNum1[1] = instr[24:20];
	regWriteNum[1] = instr[11:7];
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
end

always @(posedge clk)
if(~hazard)
begin
	func3[0] <= func3[1];
	func7[0] <= func7[1];
	imm[0] <= imm[1];
	opcode[0] <= opcode[1];
	regNum0[0] <= regNum0[1];
	regNum1[0] <= regNum1[1];
	regWriteNum[0] <= regWriteNum[1];
end
else 
begin
	opcode[0] <= 7'b0110011;
	regNum0[0] <= 0;
	regNum1[0] <= 0;
	regWriteNum[0] <= 0;
end

Execute EX(clk, reset, flush, hazard, PC, imm[0], func3[0], func7[0], opcode[0], regNum0[0], regNum1[0], regWriteNum[0], pcWriteEnable, memReadEnable, pcWriteData);

Hazard Hazarding(clk, reset, memReadEnable, regNum0[1], regNum1[1], regWriteNum[0], hazard);
endmodule
