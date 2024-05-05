`include "Defines.v"
module Decode (
	input											clk,
	input											reset,
	input		[`InstrWidth-1:0]	instr, // InstrWidth = 32
	input		[`AddrWidth-1:0]	PC, // AddrWidth = 32
	output	[`DataWidth-1:0]	pcWriteData, // DataWidth = 32
	output	[2:0]							pcOp
);

wire	[6:0]							opcode			= instr[6:0];
wire	[2:0]							func3				= instr[14:12];
wire	[6:0]							func7				= instr[31:25];
wire	[4:0]							regWriteNum	= instr[11:7];
wire	[4:0]							regNum0			= instr[19:15];
wire	[4:0]							regNum1			= instr[24:20];
reg		[`DataWidth-1:0]	imm;
initial imm = 0;

always @(*)
begin
	case(opcode)
		7'b0010011, 7'b1100111, 7'b0000011:	// FMT I
			case(func3)
				3'b001, 3'b101: 
					imm = { 20'b0, instr[31:20] };
				default:
					imm = { { 20{ instr[31] } }, instr[31:20] };
			endcase
		7'b0100011:	// FMT S
			imm	= { { 20{ instr[31] } }, instr[31:25], instr[11:7] };
		7'b1100011: // FMT B
			imm = { { 20{ instr[31] } }, instr[7], instr[30:25], instr[11:8], 1'b0 };
		7'b0010111, 7'b0110111: // FMT U
			imm = { instr[31:12], 12'b0 };
		7'b1101111: // FMT J
			imm = { { 13{ instr[31] } }, instr[19:12], instr[20], instr[30:21], 1'b0 };
		default:
			imm = 32'bz;
	endcase
end

Execute EX(clk, reset, opcode, func3, func7, regWriteNum, regNum0, regNum1, imm, PC, pcWriteData, pcOp);
endmodule;
