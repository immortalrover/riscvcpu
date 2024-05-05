`include "Defines.v"
module Decode (
	input											clk, reset,
	input		[`InstrWidth-1:0]	instr, // InstrWidth = 32
	input		[`AddrWidth-1:0]	pcReadData, // AddrWidth = 32
	output										pcWriteEnable,
	output	[`DataWidth-1:0]	pcWriteData // DataWidth = 32
);

wire	[`OpcodeWidth-1:0]	opcode			= instr[6:0]; // OpcodeWidth = 7
wire	[`Func3Width-1:0]		func3				= instr[14:12]; // Func3Width = 3
wire	[`Func7Width-1:0]		func7				= instr[31:25]; // Func7Width = 7
wire	[`RegNumWidth-1:0]	regWriteNum	= instr[11:7]; // RegNumWidth = 5
wire	[`RegNumWidth-1:0]	regNum0			= instr[19:15];
wire	[`RegNumWidth-1:0]	regNum1			= instr[24:20];
reg		[`DataWidth-1:0]		imm;
initial imm = 0;

always @(*)
case(opcode)
	7'b0010011, 7'b1100111, 7'b0000011:	// FMT I
		case(func3)
			3'b001, 3'b101: imm = { 20'b0, instr[31:20] };
			default: imm = { { 20{ instr[31] } }, instr[31:20] };
		endcase
	7'b0100011:	// FMT S
		imm	= { { 20{ instr[31] } }, instr[31:25], instr[11:7] };
	7'b1100011: // FMT B
		imm = { { 20{ instr[31] } }, instr[7], instr[30:25], instr[11:8], 1'b0 };
	7'b0010111, 7'b0110111: // FMT U
		imm = { instr[31:12], 12'b0 };
	7'b1101111: // FMT J
		imm = { { 13{ instr[31] } }, instr[19:12], instr[20], instr[30:21], 1'b0 };
	default: imm = 32'bz;
endcase

Execute EX(
	clk, reset, opcode, func3, func7, 
	regNum0, regNum1, regWriteNum, imm,
	pcReadData, pcWriteEnable, pcWriteData
);
endmodule
