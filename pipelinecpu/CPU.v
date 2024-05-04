`include "Defines.v"
module CPU (
	input													clk,
	input													reset,
	output	reg [`AddrWidth-1:0]	PC // AddrWidth = 32
);

reg		[`AddrWidth-1:0]	pcData[1:0]; // reg for PC
reg		[`InstrWidth-1:0]	instrData[1:0]; // reg for instr
wire	[`InstrWidth-1:0]	instr; // InstrWidth = 32
wire	[`AddrWidth-1:0]	pcWriteData;
wire										pcWriteEnable;
wire										hazard;

initial pcData[0] = -4;

always @(*)
begin
	pcData[1] = pcData[0] + 4;
	instrData[1] = instr;
	PC = pcData[0] - 16; // WAITING
end

always @(posedge clk)
begin
	if(~hazard)
	begin
		instrData[0] <= instrData[1];
		pcData[0] <= pcWriteEnable ? pcWriteData : pcData[1];
	end
end

wire [`InstrWidth-1:0] test = pcData[1];
wire [`InstrWidth-1:0] test1 = pcData[0];

InstrMem instrMem(pcData[0], instr);

Decode ID(clk, reset, instrData[0], pcData[0], pcWriteData, pcWriteEnable, hazard);
endmodule
