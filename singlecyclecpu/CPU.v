`include "Defines.v"
module CPU (
	input											clk,
	input											reset,
	output	[`AddrWidth-1:0]	pc // AddrWidth = 32
);

wire	[`InstrWidth-1:0]	instr; // InstrWidth = 32
InstrMem	instrMem(.instrAddr(pc), .instrData(instr));
Breakdown breakdown(clk, reset, instr, pc);
endmodule
