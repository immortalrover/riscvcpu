`timescale 1ns/1ns

module RegsFile_tb;
  reg						clk;
	reg		[4:0]		regsNum0;
	reg		[4:0]		regsNum1;
	wire	[31:0]	regsReadData0;
	wire	[31:0]	regsReadData1;

	reg						regsWriteEnable;
	reg		[31:0]  regsWriteNum;
	reg		[31:0]  regsWriteData;

	integer i;
	initial begin
		$dumpfile("build/test.vcd");
		$dumpvars(0, RegsFile_tb);
		clk = 0;
		regsNum0 = 0;
		regsNum1 = 1;

		regsWriteEnable = 0;
		regsWriteNum = 1;
		regsWriteData = 1;
	end
	always #50 clk = ~clk;
	always #500 regsWriteEnable = ~regsWriteEnable;
	always #300 if(regsWriteNum < 31)regsWriteNum = regsWriteNum+1; 
	always #100 regsWriteData = regsWriteData + 1;
	always #1000 regsNum1 = regsNum1 + 1;

	RegsFile regs(clk, regsNum0, regsNum1, regsReadData0, regsReadData1, regsWriteEnable, regsWriteNum, regsWriteData);

endmodule
