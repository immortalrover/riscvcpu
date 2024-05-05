`include "Defines.v"
module CPU (
	input											clk,
	input											reset,
	output	[`AddrWidth-1:0]	PC // AddrWidth = 32
);

reg		[`AddrWidth-1:0] pcData[1:0]; // get pcData
wire	[`InstrWidth-1:0]	instr; // InstrWidth = 32
wire	[`AddrWidth-1:0]	pcWriteData;
wire	pcWriteEnable;
initial pcData[0] = -4;
assign PC = pcData[0];

always @(*) if (reset) pcData[0] = 0;

always @(*)
begin
	pcData[1] = pcData[0] + 4;
end

always @(posedge clk)
begin
	pcData[0] <= pcWriteEnable ? pcWriteData : pcData[1];
end

InstrMem	instrMem(.instrAddr(pcData[0]), .instrData(instr));

Decode ID(clk, reset, instr, pcData[0], pcWriteEnable, pcWriteData);
endmodule
