module CPU (
	input							clk,
	input							reset,
	output	[31:0]		pc
);

ProgramCounter PC(clk, reset,	pcReadData, pcWriteData);
wire	[31:0]	instrA;
InstrMem	instrMem(.instrAddr(pc), .instrData(instrA));
wire	[31:0]	instrB;
DTypeFlipFlop	instrDFF(clk, reset, instrA, instrB);
Breakdown breakdown(clk, reset, instrB, pc);
endmodule
