`include "Defines.v"
module Decode (
	input						clk,
	input						reset,
	input		[6:0]		opcode,
	input		[2:0]		func3,
	input		[6:0]		func7,
	input		[4:0]		regWriteNum,
	input		[4:0]		regNum0,
	input		[4:0]		regNum1,
	input		[31:0]	imm,
	output	[31:0]	pcReadData
);

reg		[3:0]		aluOpA;
reg		[31:0]	aluXA;
reg		[31:0]	aluYA;
wire	[3:0]		aluOpB;
wire	[31:0]	aluXB;
wire	[31:0]	aluYB;
DTypeFlipFlop #(4) aluOpDFF(clk, reset, aluOpA, aluOpB);
DTypeFlipFlop aluXDFF(clk, reset, aluXA, aluXB);
DTypeFlipFlop aluYDFF(clk, reset, aluYA, aluYB);
wire	[31:0]	aluO;
ALU	alu(aluOpB, aluXB, aluYB, aluO);

wire	[31:0]	regReadData0;
wire	[31:0]	regReadData1;
wire					regsWriteEnable;
reg		[31:0]	regWriteDataA;
wire	[31:0]	regWriteDataB;
DTypeFlipFlop	regWriteDataDFF(clk, reset, regWriteDataA, regWriteDataB);
RegsFile RF(clk, reset,regNum0, regNum1, regReadData0, regReadData1, regsWriteEnable, regWriteNum, regWriteDataB);

reg		[31:0]	memAddrA;
wire					memReadEnable;
wire	[31:0]	memReadData;
wire					memWriteEnable;
reg		[31:0]	memWriteDataA;
wire	[31:0]	memAddrB;
wire	[31:0]	memWriteDataB;
DTypeFlipFlop	memAddrDFF(clk, reset, memAddrA, memAddrB);
DTypeFlipFlop	memWriteDataDFF(clk, reset, memWriteDataA, memWriteDataB);
DataMem mem(clk, memAddrB, memReadEnable, memReadData, memWriteEnable, memWriteDataB, pcReadData);

reg		[2:0]		state;
Controller control(state, regsWriteEnable, memReadEnable, memWriteEnable, pcWriteEnable);

always @(*)
begin
	if (reset) begin
		aluOpA						=	`ADD;
		aluXA							=	0;
		aluYA							=	0;
		regWriteDataA			=	0;
		memAddrA					=	0;
		memWriteDataA			=	0;
		state							=	`IDLE;
	end
	else if (clk)
	begin
	case (opcode)
		7'b0110011: // FMT R
		begin
			case (func3)
				0: aluOpA		=	func7[5] ? `SUB : `ADD;	// add sub
				1: aluOpA		=	`ShiftLeftUnsigned;	// sll
				2: aluOpA		=	`LesserThanSigned;	// slt
				3: aluOpA		=	`LesserThanUnsigned; // sltu
				4: aluOpA		=	`XOR; // xor
				5: aluOpA		=	func7[5] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srl sra
				6: aluOpA		=	`OR; // or
				7: aluOpA		=	`AND; // and
			endcase
			aluXA					=	regReadData0;
			aluYA					=	regReadData1;

			pcOpA					=	`PCAdd4;
			regWriteDataA	=	aluO;
			state					=	`RegsWrite;
		end
		7'b0010011: // FMT I
		begin
			case (func3)
				0: aluOpA		=	`ADD;	// addi
				1: aluOpA		=	`ShiftLeftUnsigned;	// slli
				2: aluOpA		=	`LesserThanSigned;	// slti
				3: aluOpA		=	`LesserThanUnsigned; // sltiu
				4: aluOpA		=	`XOR; // xori
				5: aluOpA		=	imm[10] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srli srai
				6: aluOpA		=	`OR; // ori
				7: aluOpA		=	`AND; // andi
			endcase
			aluXA					=	regReadData0;
			aluYA					=	imm;

			pcOpA					=	`PCAdd4;
			regWriteDataA	=	aluO;
			state					=	`RegsWrite;
		end
		7'b0000011: // FMT I lb lh lw lbu lhu
		begin
			aluX					=	regReadData0;
			aluY					=	imm;
			aluOp					=	`ADD;

			pcOp					=	`PCAdd4;
			memAddr				=	aluO;
			state					=	`MemtoRegs;
			case (func3)
				0: regWriteData	=	{ { 24{ memReadData[7] } }, memReadData[7:0] }; // lb lbu
				1: regWriteData =	{ { 16{ memReadData[15] } }, memReadData[15:0] }; // lh lhu
				2: regWriteData =	memReadData; // lw
			endcase
		end
		7'b0100011: // FMT S sb sh sw
		begin
			aluX					=	regReadData0;
			aluY					=	imm;
			aluOp					=	`ADD;
			
			pcOp					=	`PCAdd4;
			memAddr				=	aluO;
			case (func3)
				0: memWriteData	=	{ { 24{ regReadData1[7] } }, regReadData1[7:0] }; // sb
				1: memWriteData =	{ { 16{ regReadData1[15] } }, regReadData1[15:0] }; // sh
				2: memWriteData =	regReadData1; // sw
			endcase
			state					=	`MemWrite;
		end
		7'b1100011: // FMT B
		begin
			case (func3)
				0: aluOp		=	`Equal; // beq
				1: aluOp		=	`NotEqual; // bne
				4: aluOp		=	`LesserThanSigned; // blt
				5: aluOp		=	`GreaterThanOrEqualSigned; // bge
				6: aluOp		=	`LesserThanUnsigned; // bltu
				7: aluOp		=	`GreaterThanOrEqualUnsigned; // bgeu
			endcase
			aluX					=	regReadData0;
			aluY					=	regReadData1;

			pcOp					=	aluO ? `PCAddImm : `PCAdd4;
			pcWriteData		=	imm;
			state					=	`PCWrite;
		end
		7'b1101111: // FMT J jal
		begin
			aluX					=	pcReadData;
			aluY					=	imm;
			aluOp					=	`ADD;

			pcOp					=	`PCSetImm;
			pcWriteData		=	aluO;
			regWriteData	=	pcReadData;
			state					=	`RegsWrite;
		end
		7'b1100111: // FMT I jalr
		begin
			aluX					=	regReadData0;
			aluY					=	imm;
			aluOp					=	`ADD;
			
			pcOp					=	`PCSetImm;
			pcWriteData		=	aluO;
			regWriteData	=	pcReadData;
			state					=	`RegsWrite;
		end
		7'b0110111: // FMT U lui
		begin
			pcOp					=	`PCAdd4;
			regWriteData	=	imm;
			state					=	`RegsWrite;
		end
		7'b0010111: // FMT U auipc
		begin
			aluX					=	pcReadData;
			aluY					=	imm;
			aluOp					=	`ADD;

			pcOp					=	`PCAdd4;
			regWriteData	=	aluO;
			state					=	`RegsWrite;
		end
		default: state	= `IDLE;
	endcase
	end
end
endmodule
