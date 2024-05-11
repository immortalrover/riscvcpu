`include "Defines.v"
module xgriscv_pipeline (
	input													clk, reset,
	output	reg [`AddrWidth-1:0]	PC // AddrWidth = 32
);

reg		[`AddrWidth-1:0]	pcData[5:0]; // reg for PC
reg		[`InstrWidth-1:0]	instrData[1:0]; // reg for instr

wire										hazard, flush, pcWriteEnable;
wire	[`AddrWidth-1:0]	pcWriteData;
wire	[`InstrWidth-1:0]	instr; // InstrWidth = 32

initial pcData[4] = -4;

always @(*)
begin
	PC = pcData[0];
	instrData[1] = instr;
	pcData[5] = pcData[4] + 4;
end

always @(posedge clk)
begin
	if(~hazard)
	begin
		instrData[0] <= instrData[1];
		pcData[4] <= pcWriteEnable ? pcWriteData : pcData[5];
	end
	pcData[0] <= pcData[1];
	pcData[1] <= pcData[2];
	pcData[2] <= pcData[3];
	pcData[3] <= pcData[4];
end
InstrMem U_imem(pcData[4], instr);

Decode ID(clk, reset, flush, pcData[4], instrData[0], hazard, pcWriteEnable, pcWriteData);

Flush flushing(clk, pcWriteEnable, flush);
endmodule
