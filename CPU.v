module CPU (
	input							clk,
	output	[31:0]		pc
);

wire	[31:0]	instr;
InstrMem	instrMem(.instrAddr(pc), .instrData(instr));
Breakdown breakdown(clk, instr, pc);
endmodule
