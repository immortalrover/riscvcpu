`timescale 1ns/1ns
module ProgramCounter_tb();
wire	[31:0]		pcReadData;
reg							pcWriteEnable;
reg		[31:0]		pcWriteData;
reg		[2:0]			pcOp;

initial begin
	$dumpfile("build/test.vcd");
	$dumpvars;
	pcOp = 0;
	pcWriteEnable = 1;
	pcWriteData = 0;
end
always #50 pcWriteEnable = ~pcWriteEnable;
always #500 begin
	pcWriteData = pcWriteData + 100;
	pcOp = pcOp ^ 2;
end

ProgramCounter PC(pcReadData, pcWriteEnable, pcWriteData, pcOp);
endmodule
