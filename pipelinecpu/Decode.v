`include "Defines.v"
module Decode (
	input											clk,
	input											reset,
	input		[`InstrWidth-1:0]	instr, // InstrWidth = 32
	input		[`AddrWidth-1:0]	PC, // AddrWidth = 32
	output	[`DataWidth-1:0]	pcWriteData, // DataWidth = 32
	output										pcWriteEnable,
	output										hazard
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
reg		[`DataWidth-1:0]			regInData[1:0];
reg													regInEnable[1:0];
reg		[`DataWidth-1:0]			imm[1:0];
reg		[`DataWidth-1:0]			regOutData0[1:0];
reg		[`DataWidth-1:0]			regOutData1[1:0];
wire	[`DataWidth-1:0]			aluO1;
wire forwardA1, forwardA2, forwardB1, forwardB2;
wire forward1 = forwardA1 | forwardB1;

wire	[1:0]									forwardA = {forwardA1, forwardA2};
wire	[1:0]									forwardB = {forwardB1, forwardB2};

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
	case (forwardA)
		2'b00:
			regOutData0[1] = regReadData0;
		2'b10, 2'b11:
			regOutData0[1] = aluO1;
		2'b01:
			regOutData0[1] = regWriteData;
		default:
			regOutData0[1] = regReadData0;
	endcase
	case (forwardB)
		2'b00:
			regOutData1[1] = regReadData1;
		2'b10, 2'b11:
			regOutData1[1] = aluO1;
		2'b01:
			regOutData1[1] = regWriteData;
		default:
			regOutData1[1] = regReadData1;
	endcase
	/* regOutData0[1] = forwardA1 ? aluO1 : forwardA2 ? regInData[1] : regReadData0; */
	/* regOutData1[1] = forwardB1 ? aluO1 : forwardB2 ? regInData[1] : regReadData1; */
	regInData[1] = regWriteData;
	regInEnable[1] = regWriteEnable;
end

always @(posedge clk)
begin
	if(~hazard)
	begin
		opcode[0] <= opcode[1];
		func3[0] <= func3[1];
		func7[0] <= func7[1];
		imm[0] <= imm[1];
		regOutData0[0] <= regOutData0[1];	
		regOutData1[0] <= regOutData1[1];	
		regWriteNum[2] <= regWriteNum[3];
	end
	else regWriteNum[2] <= 0;
	regWriteNum[1] <= regWriteNum[2];
	regWriteNum[0] <= regWriteNum[1];
	regInData[0] <= regInData[1];
	regInEnable[0] <= regInEnable[1];
end

wire [`DataWidth-1:0] testa1 = regOutData0[1];
wire [`DataWidth-1:0] testa2 = regOutData0[0];
wire [`DataWidth-1:0] testb1 = regOutData1[1];
wire [`DataWidth-1:0] testb2 = regOutData1[0];

wire [`RegNumWidth-1:0] testr1 = regWriteNum[1];
wire [`RegNumWidth-1:0] testr2 = regWriteNum[2];
wire [`RegNumWidth-1:0] testr3 = regWriteNum[3];

RegsFile RF( 
  clk, reset, regNum0, regNum1, regReadData0, regReadData1, 
  regInEnable[0], regWriteNum[0], regInData[0]
);

Execute EX(
	clk, reset, opcode[0], func3[0],func7[0], 
	regOutData0[0], regOutData1[0], regWriteEnable, regWriteData, 
	imm[0], PC, pcWriteData, pcWriteEnable, forward1, aluO1, hazard
);

Forward Forwarding(
	clk, regNum0, regNum1, regWriteNum[2], forwardA1, forwardA2, forwardB1, forwardB2
);

Hazard hazarding(clk, forward1, opcode[0], hazard);
endmodule
