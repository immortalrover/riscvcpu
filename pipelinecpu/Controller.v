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

reg		[`DataWidth-1:0]		pcData[3:0];
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
			regWriteData		= memReadData;
			regWriteEnable	=	1;
			memWriteEnable	=	0;
			memWriteData		=	0;
			pcWriteEnable		= 0;
		end
		`MemWrite:
		begin
			memAddr					=	aluO;
			memWriteData		= regReadData1;
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
				pcWriteData			=	pcData[0] + imm;
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
			regWriteData		=	pcData[1];
			regWriteEnable	=	1;
			memWriteEnable	=	0;
			memWriteData		=	0;
		end
		`LuiRegWrite:
		begin
			regWriteData		= imm;
			regWriteEnable	= 1;
			memWriteEnable	=	0;
			memWriteData		=	0;
			pcWriteEnable		= 0;
		end
	endcase
	pcData[3] = PC;
end

always @(posedge clk)
begin
	pcData[2] <= pcData[3];
	pcData[1] <= pcData[2];
	pcData[0] <= pcData[1];
end
DataMem mem(clk, memAddr, memReadData, memWriteEnable, memWriteData, PC, func3);

endmodule
