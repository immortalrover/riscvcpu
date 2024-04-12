module CPU (
	input							clk,
	input							reset,
	output	[31:0]		pcReadData
);

reg		[31:0]	pcWriteData;
reg		[2:0]		pcOp;
ProgramCounter PC(clk, reset,	pcReadData, pcWriteData, pcOp);

wire	[31:0]	instrA;
InstrMem	instrMem(.instrAddr(pcReadData), .instrData(instrA));
wire	[31:0]	instrB;
DTypeFlipFlop	instrDFF(clk, reset, instrA, instrB);

Breakdown breakdown(clk, reset, instrB, pc);
endmodule
