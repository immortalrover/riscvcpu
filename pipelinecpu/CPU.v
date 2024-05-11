`include "Defines.v"
module xgriscv_pipeline (
	input													clk, reset,
	output	reg [`AddrWidth-1:0]	PC // AddrWidth = 32
);

reg		[`AddrWidth-1:0]	pcData[1:0]; // reg for PC
reg		[`InstrWidth-1:0]	instrData[1:0]; // reg for instr

wire										hazard, flush, pcWriteEnable;
wire	[`AddrWidth-1:0]	pcWriteData;
wire	[`InstrWidth-1:0]	instr; // InstrWidth = 32

initial pcData[0] = -4;

always @(*)
begin
	PC = pcData[0] - 16;
	instrData[1] = instr;
	pcData[1] = pcData[0] + 4;
end

always @(posedge clk)
begin
	if(~hazard)
	begin
		instrData[0] <=  instrdata[1];
		pcdata[0] <=  pcwriteenable ? pcwritedata : pcdata[1];
	end
end
instrmem u_imem(pcdata[0], instr);

decode id(clk, reset, flush, pcdata[0], instrData[0], hazard, pcWriteEnable, pcWriteData);

Flush flushing(clk, reset, pcWriteEnable, flush);
endmodule
