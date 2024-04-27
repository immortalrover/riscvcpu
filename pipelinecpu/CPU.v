`include "Defines.v"
module CPU (
	input													clk,
	input													reset,
	output	reg [`AddrWidth-1:0]	PC // AddrWidth = 32
);

reg		[`AddrWidth-1:0]	pcData[1:0];
reg		[`InstrWidth-1:0]	instrData[1:0];
wire	[`InstrWidth-1:0]	instr; // InstrWidth = 32
wire	[`AddrWidth-1:0]	pcWriteData;
wire										pcWriteEnable;
wire										hazard;
initial begin
	PC = 0;
	pcData[1] = 0;
	pcData[0] = -4;
end

always @(*)
begin
	pcData[1] = pcData[0] + 4;
	instrData[1] = instr;
	PC = pcData[0];
end

always @(posedge clk)
begin
	if(~hazard && ~pcWriteEnable)
	begin
		instrData[0] <= instrData[1];
		pcData[0] <= pcData[1];
	end
	else if (pcWriteEnable) pcData[0] <= pcWriteData;
end

wire [`InstrWidth-1:0] test = pcData[1];
wire [`InstrWidth-1:0] test1 = pcData[0];

InstrMem	instrMem(.instrAddr(PC), .instrData(instr));

Decode ID(clk, reset, instrData[0], PC, pcWriteData, pcWriteEnable, hazard);
endmodule
