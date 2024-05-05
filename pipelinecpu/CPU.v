`include "Defines.v"
module CPU (
	input													clk,
	input													reset,
	output	reg [`AddrWidth-1:0]	PC // AddrWidth = 32
);

reg		[`AddrWidth-1:0]	pcData[5:0]; // reg for PC
reg		[`InstrWidth-1:0]	instrData[1:0]; // reg for instr
wire	[`InstrWidth-1:0]	instr; // InstrWidth = 32
wire	[`AddrWidth-1:0]	pcWriteData;
wire										pcWriteEnable;
wire										hazard;
wire										flush;

initial pcData[4] = -4;

always @(*)
begin
	pcData[5] = pcData[4] + 4;
	instrData[1] = instr;
	PC = pcData[0];
end

always @(posedge clk)
begin
	if(~hazard)
	begin
		instrData[0] <= instrData[1];
		pcData[4] <= pcWriteEnable ? pcWriteData : pcData[5];
	end
	pcData[3] <= pcData[4];
	pcData[2] <= pcData[3];
	pcData[1] <= pcData[2];
	pcData[0] <= pcData[1];
end

wire [`InstrWidth-1:0] test = pcData[5];
wire [`InstrWidth-1:0] test1 = pcData[4];

InstrMem instrMem(pcData[4], instr);

Decode ID(clk, reset, instrData[0], pcData[4], pcWriteData, pcWriteEnable, hazard, flush);

Flush flushing(clk, pcWriteEnable, flush);
endmodule
