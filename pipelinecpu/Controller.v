`include "Defines.v"
module Controller (
	input														clk,
	input														reset,
	input				[`StateWidth-1:0]		state, // StateWidth = 4

	input				[`Func3Width-1:0]		func3, // Func3Width = 3
	input				[`DataWidth-1:0]		imm, // DataWidth = 32
	input				[`DataWidth-1:0]		regReadData1,
	input				[`DataWidth-1:0]		aluO,
	input				[`DataWidth-1:0]		pcReadData,

	output	reg											regWriteEnable,
	output	reg	[`DataWidth-1:0]		regWriteData,

	output	reg	[`AddrWidth-1:0]		memAddr, // AddrWidth = 32
	input				[`DataWidth-1:0]		memReadData,
	output	reg											memWriteEnable,
	output	reg	[`DataWidth-1:0]		memWriteData,

	output	reg	[`PCOpWidth-1:0]		pcOp, // PCOpWidth = 2
	output	reg	[`DataWidth-1:0]		pcWriteData
);

always @(*) 
begin
	if (reset) pcOp			= `PCClear;
	else 
	case (state)
		`IDLE:
		begin
			regWriteData		= 0;
			regWriteEnable	=	0;
			memWriteEnable	=	0;
			memWriteData		=	0;
			pcOp						= `PCAdd4;
		end
		`RegWrite:
		begin
			regWriteData		= aluO;
			regWriteEnable	=	1;
			pcOp						= `PCAdd4;
			memWriteEnable	=	0;
			memWriteData		=	0;
		end	
		`MemReadRegWrite:
		begin
			memAddr					= aluO;
      case (func3)
        0: regWriteData = { { 24{ memReadData[7] } }, memReadData[7:0] }; // lb lbu
        1: regWriteData = { { 16{ memReadData[15] } }, memReadData[15:0] }; // lh lhu
        2: regWriteData = memReadData; // lw
      endcase
			regWriteEnable	=	1;
			pcOp						= `PCAdd4;
			memWriteEnable	=	0;
			memWriteData		=	0;
		end
		`MemWrite:
		begin
			memAddr					=	aluO;
      case (func3)
        0: memWriteData = { { 24{ regReadData1[7] } }, regReadData1[7:0] }; // sb
        1: memWriteData = { { 16{ regReadData1[15] } }, regReadData1[15:0] }; // sh
        2: memWriteData = regReadData1; // sw
      endcase
			memWriteEnable	=	1;
			pcOp						= `PCAdd4;
			regWriteData		= 0;
			regWriteEnable	=	0;
		end
		`PCSelectWrite:
		begin
			pcOp						=	aluO ? `PCAddImm : `PCAdd4;
			pcWriteData			=	imm;
			regWriteData		= 0;
			regWriteEnable	=	0;
			memWriteEnable	=	0;
			memWriteData		=	0;
		end
		`PCWrite:
		begin
			pcOp						=	`PCSetImm;
			pcWriteData			=	aluO;
			regWriteData		=	pcReadData;
			regWriteEnable	=	1;
			memWriteEnable	=	0;
			memWriteData		=	0;
		end
	endcase
end
endmodule
