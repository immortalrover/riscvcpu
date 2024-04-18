`include "Defines.v"
module Decode (
	input											clk,
	input											reset,
	input		[`InstrWidth-1:0]	instr, // InstrWidth = 32
	input		[`AddrWidth-1:0]	pcReadData, // AddrWidth = 32
	output	[`DataWidth-1:0]	pcWriteData, // DataWidth = 32
	output	[2:0]							pcOp
);

reg		[2*`OpcodeWidth-1:0]	opcode; /* = instr[6:0]; */
reg		[2*`Func3Width-1:0]		func3; /* = instr[14:12]; */
reg		[2*`Func7Width-1:0]		func7; /* = instr[31:25]; */
reg		[3*`RegNumWidth-1:0]	regWriteNum; /* = instr[11:7]; */
wire	[`RegNumWidth-1:0]		regNum0 = instr[19:15];
wire	[`RegNumWidth-1:0]		regNum1 = instr[24:20];
wire  [`DataWidth-1:0]			regReadData0;
wire  [`DataWidth-1:0]			regReadData1;
wire												regsWriteEnable;
wire  [`DataWidth-1:0]			regWriteData;

RegsFile RF( 
  clk, reset, regNum0, regNum1, regReadData0, regReadData1, 
  regsWriteEnable, regWriteNum[`RegNumWidth-1:0], regWriteData
);

reg		[`DataWidth-1:0]			immData;
reg		[2*`DataWidth-1:0]		imm;
reg		[2*`DataWidth-1:0]		regOutData0;
reg		[2*`DataWidth-1:0]		regOutData1;

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
			imm[2*`DataWidth-1:`DataWidth]	= { { 20{ instr[31] } }, instr[31:25], instr[11:7] };
		7'b1100011: // FMT B
			imm[2*`DataWidth-1:`DataWidth] = { { 20{ instr[31] } }, instr[7], instr[30:25], instr[11:8], 1'b0 };
		7'b0010111, 7'b0110111: // FMT U
			imm[2*`DataWidth-1:`DataWidth] = { instr[31:12], 12'b0 };
		7'b1101111: // FMT J
			imm[2*`DataWidth-1:`DataWidth] = { { 13{ instr[31] } }, instr[19:12], instr[20], instr[30:21], 1'b0 };
		default:
			imm[2*`DataWidth-1:`DataWidth] = 32'bz;
	endcase
	opcode[2*`OpcodeWidth-1:`OpcodeWidth] = instr[6:0];
	func3[2*`Func3Width-1:`Func3Width] = instr[14:12];
	func7[2*`Func7Width-1:`Func7Width] = instr[31:25];
	regWriteNum[3*`RegNumWidth-1:2*`RegNumWidth] = instr[11:7];
	/* imm[2*`DataWidth-1:`DataWidth] = immData; */
	regOutData0[2*`DataWidth-1:`DataWidth] = regReadData0;
	regOutData1[2*`DataWidth-1:`DataWidth] = regReadData1;
end

always @(posedge clk)
begin
	opcode[`OpcodeWidth-1:0] <= opcode[2*`OpcodeWidth-1:`OpcodeWidth];
	func3[`Func3Width-1:0] <= func3[2*`Func3Width-1:`Func3Width];
	func7[`Func7Width-1:0] <= func7[2*`Func7Width-1:`Func7Width];
	regWriteNum[2*`RegNumWidth-1:`RegNumWidth] <= regWriteNum[3*`RegNumWidth-1:2*`RegNumWidth];
	regWriteNum[`RegNumWidth-1:0] <= regWriteNum[2*`RegNumWidth-1:`RegNumWidth];
	imm[`DataWidth-1:0]	<= imm[2*`DataWidth-1:`DataWidth];
	regOutData0[`DataWidth-1:0]	<= regOutData0[2*`DataWidth-1:`DataWidth];	
	regOutData1[`DataWidth-1:0]	<= regOutData1[2*`DataWidth-1:`DataWidth];	
end

Execute EX(
	clk, reset, opcode[`OpcodeWidth-1:0], func3[`Func3Width-1:0], func7[`Func7Width-1:0], 
	regOutData0[`DataWidth-1:0], regOutData1[`DataWidth-1:0], regsWriteEnable, regWriteData, 
	imm[`DataWidth-1:0], pcReadData, pcWriteData, pcOp
);
endmodule;
