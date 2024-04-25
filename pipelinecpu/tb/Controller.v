`include "Defines.v"
module Controller (
	input														clk,
	input				[`StateWidth-1:0]		state, // StateWidth = 4

	input				[`Func3Width-1:0]		func3, // Func3Width = 3
	input				[`DataWidth-1:0]		imm, // DataWidth = 32
	input				[`DataWidth-1:0]		regReadData1,
	input				[`DataWidth-1:0]		aluO,
	input				[`DataWidth-1:0]		pcReadData,

	output													regWriteEnable,
	output			[`DataWidth-1:0]		regWriteData,

	output			[`AddrWidth-1:0]		memReadAddr, // AddrWidth = 32
	output			[`AddrWidth-1:0]		memWriteAddr, // AddrWidth = 32
	input				[`DataWidth-1:0]		memReadData,
	output													memWriteEnable,
	output			[`DataWidth-1:0]		memWriteData,

	output	reg	[`PCOpWidth-1:0]		pcOp, // PCOpWidth = 2
	output	reg	[`DataWidth-1:0]		pcWriteData
);

reg										regInEnable[1:0];
reg	[`DataWidth-1:0]	regInData[1:0];
reg										memInEnable[1:0];
reg [`DataWidth-1:0]	memInData[1:0];
reg	[`AddrWidth-1:0]	memAddr[1:0];

always @(*) 
begin
	case (state)
		/* `IDLE: */
		/* begin */
		/* 	regInData[1]		= 0; */
		/* 	regInEnable[1]	=	0; */
		/* 	memInEnable[1]	=	0; */
		/* 	pcOp						= `PCClear; */
		/* end */
		`RegWrite:
		begin
			regInData[1]		= aluO;
			regInEnable[1]	=	1;
			pcOp						= `PCAdd4;
		end	
		`MemReadRegWrite:
		begin
			memAddr[0]			= aluO;
      case (func3)
        0: regInData[1] = { { 24{ memReadData[7] } }, memReadData[7:0] }; // lb lbu
        1: regInData[1] = { { 16{ memReadData[15] } }, memReadData[15:0] }; // lh lhu
        2: regInData[1] = memReadData; // lw
      endcase
			regInEnable[1]	=	1;
			pcOp						= `PCAdd4;
		end
		`MemWrite:
		begin
			memAddr[1]				=	aluO;
      case (func3)
        0: memInData[1] = { { 24{ regReadData1[7] } }, regReadData1[7:0] }; // sb
        1: memInData[1] = { { 16{ regReadData1[15] } }, regReadData1[15:0] }; // sh
        2: memInData[1] = regReadData1; // sw
      endcase
			memInEnable[1]	=	1;
			pcOp						= `PCAdd4;
		end
		`PCSelectWrite:
		begin
			pcOp						=	aluO ? `PCAddImm : `PCAdd4;
			pcWriteData			=	imm;
		end
		`PCWrite:
		begin
			pcOp						=	`PCSetImm;
			pcWriteData			=	aluO;
			regInData[1]		=	pcReadData;
		end
	endcase
end

always @(posedge clk)
begin
	regInEnable[0] <= regInEnable[1];
	regInData[0] <= regInData[1];
	memInEnable[0] <= memInEnable[1];
	memInData[0] <= memInData[1];
	memAddr[0] <= memAddr[1];
end

assign regWriteEnable = regInEnable[0];
assign regWriteData = regInData[0];
assign memWriteData = memInData[0];
assign memReadAddr = memAddr[1];
assign memWriteAddr = memAddr[0];
assign memWriteEnable = memInEnable[0];
endmodule
