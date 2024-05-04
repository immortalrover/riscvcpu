`include "Defines.v"
module Controller (
	input														clk,
	input														reset,
	input				[`StateWidth-1:0]		state, // StateWidth = 4

	input				[`Func3Width-1:0]		func3, // Func3Width = 3
	input				[`DataWidth-1:0]		imm, // DataWidth = 32
	input				[`DataWidth-1:0]		regReadData1,
	input				[`DataWidth-1:0]		aluO,
	input				[`DataWidth-1:0]		PC,

	output	reg											regWriteEnable,
	output	reg	[`DataWidth-1:0]		regWriteData,
	output	reg											pcWriteEnable,
	output	reg	[`DataWidth-1:0]		pcWriteData
);

// MEM
reg		[`AddrWidth-1:0]		memAddr;
wire	[`DataWidth-1:0]		memReadData;
reg												memWriteEnable;
reg		[`DataWidth-1:0]		memWriteData;

initial pcWriteEnable = 0;
always @(*) 
begin
	if (reset) 
	begin
		pcWriteEnable			= 1;
		pcWriteData				= 0;
	end
	else 
	case (state)
		`IDLE:
		begin
			regWriteData		= 0;
			regWriteEnable	=	0;
			memWriteEnable	=	0;
			memWriteData		=	0;
			pcWriteEnable		= 0;
		end
		`RegWrite:
		begin
			regWriteData		= aluO;
			regWriteEnable	=	1;
			memWriteEnable	=	0;
			memWriteData		=	0;
			pcWriteEnable		= 0;
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
			memWriteEnable	=	0;
			memWriteData		=	0;
			pcWriteEnable		= 0;
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
			regWriteData		= 0;
			regWriteEnable	=	0;
			pcWriteEnable		= 0;
		end
		`PCSelectWrite:
		begin
			if (aluO)
			begin
				pcWriteEnable		= 1;
				pcWriteData			=	PC + imm - 12;
			end
			regWriteData		= 0;
			regWriteEnable	=	0;
			memWriteEnable	=	0;
			memWriteData		=	0;
		end
		`PCWrite:
		begin
			pcWriteEnable		= 1;
			pcWriteData			=	aluO;
			regWriteData		=	PC;
			regWriteEnable	=	1;
			memWriteEnable	=	0;
			memWriteData		=	0;
		end
	endcase
end

DataMem mem(clk, memAddr, memReadData, memWriteEnable, memWriteData, PC);

endmodule
