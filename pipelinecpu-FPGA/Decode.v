`include "Defines.v"
module Decode (
	input											clk, reset, flush,
	input		[`AddrWidth-1:0]	PC, // AddrWidth = 32
	input		[`InstrWidth-1:0]	instr, // InstrWidth = 32
	output										hazard, pcWriteEnable,
	output	[`DataWidth-1:0]	pcWriteData, // DataWidth = 32
	
	input		[`RegNumWidth-1:0] regWatchNum,
	input		[`AddrWidth-1:0]	 memWatchAddr,
	output	[`DataWidth-1:0]	regWatchData, aluWatchO, memWatchData
);

reg		[`OpcodeWidth-1:0]		opcode; /* = instr[6:0]; */ // OpcodeWidth = 7
reg		[`Func3Width-1:0]			func3; /* = instr[14:12]; */ // Func3Width = 3
reg		[`Func7Width-1:0]			func7; /* = instr[31:25]; */ // Func7Width = 7
reg		[`RegNumWidth-1:0]		regWriteNum; /* = instr[11:7]; */ // RegNumWidth = 5
reg		[`RegNumWidth-1:0]		regNum0; /* = instr[19:15]; */
reg		[`RegNumWidth-1:0]		regNum1; /* = instr[24:20]; */
reg		[2*`DataWidth-1:0]		imm;

always @(*)
begin
	case({instr[6:0]}) // opcode
		7'b0010011, 7'b1100111, 7'b0000011:	// FMT I
			case({instr[14:12]}) // func3
				3'b001, 3'b101: 
					imm[2*`DataWidth-1:`DataWidth] = { 20'b0, instr[31:20] };
				default:
					imm[2*`DataWidth-1:`DataWidth] = { { 20{ instr[31] } }, instr[31:20] };
			endcase
		7'b0100011:	// FMT S
			imm[2*`DataWidth-1:`DataWidth] = { { 20{ instr[31] } }, instr[31:25], instr[11:7] };
		7'b1100011: // FMT B
			imm[2*`DataWidth-1:`DataWidth] = { { 20{ instr[31] } }, instr[7], instr[30:25], instr[11:8], 1'b0 };
		7'b0010111, 7'b0110111: // FMT U
			imm[2*`DataWidth-1:`DataWidth] = { instr[31:12], 12'b0 };
		7'b1101111: // FMT J
			imm[2*`DataWidth-1:`DataWidth] = { { 13{ instr[31] } }, instr[19:12], instr[20], instr[30:21], 1'b0 };
		default:
			imm[2*`DataWidth-1:`DataWidth] = 32'bz;
	endcase
end

always @(posedge clk)
if(~hazard)
begin
	func3 <= reset ? 0 : instr[14:12];
	func7 <= reset ? 0 : instr[31:25];
	imm[`DataWidth-1:0] <= reset ? 0 : imm[2*`DataWidth-1:`DataWidth];
	opcode <= reset ? 0 : instr[6:0];
	regNum0 <= reset ? 0 : instr[19:15];
	regNum1 <= reset ? 0 : instr[24:20];
	regWriteNum <= reset ? 0 : instr[11:7];
end

Execute EX(clk, reset, flush, hazard, PC, imm[`DataWidth-1:0], func3, func7, opcode, regNum0, regNum1, regWriteNum, pcWriteEnable, memReadEnable, pcWriteData, regWatchNum, memWatchAddr, regWatchData, aluWatchO, memWatchData);

Hazard Hazarding(clk, reset, memReadEnable, regNum0, regNum1, regWriteNum, hazard);
endmodule
