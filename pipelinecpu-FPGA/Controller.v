`include "Defines.v"
module Controller (
	input														clk, reset,
	input				[1:0]								forwordB,
	input				[`AddrWidth-1:0]		PC, // AddrWidth = 32
	input				[`DataWidth-1:0]		imm, regReadData1, aluO, // DataWidth = 32
	input				[`Func3Width-1:0]		func3, // Func3Width = 3
	input				[`StateWidth-1:0]		state, // StateWidth = 4
	output	reg											pcWriteEnable, regWriteEnable,
	output	reg	[`DataWidth-1:0]		pcWriteData, regWriteData, data,

	input				[`AddrWidth-1:0]		memWatchAddr,
	output			[`DataWidth-1:0]		memWatchData
);

reg											memWriteEnable;
reg		[`AddrWidth-1:0]	memAddr;
reg		[`DataWidth-1:0]	memWriteData, pcData[2:0];

wire	[`DataWidth-1:0]	memReadData;

initial pcWriteData = 0;
initial pcWriteEnable = 0;

always @(*) 
begin
	pcData[2] = PC;
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
			regWriteData		= forwordB[0] ? data : memReadData;
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
				pcWriteData			=	pcData[0] + imm - 4;
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
			regWriteData		=	pcData[0];
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
	case (state)
		`MemWrite: data = memWriteData;
		`RegWrite, `MemReadRegWrite, `PCWrite, `LuiRegWrite: data = regWriteData;
	endcase
end

always @(posedge clk)
begin
	pcData[0] <= reset ? 0 : pcData[1];
	pcData[1] <= reset ? 0 : pcData[2];
end

DataMem mem(memWriteEnable, PC, func3, memAddr, memWriteData, memReadData,
	memWatchAddr,
	memWatchData
);
endmodule
