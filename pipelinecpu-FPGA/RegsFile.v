`include "Defines.v"
module RegsFile(
  input												clk, reset, regWriteEnable, // 1 => WRITE
  input  [`DataWidth-1:0]			regWriteData,
  input  [`RegNumWidth-1:0]		regNum0, regNum1, regWriteNum, // RegNumWidth = 5
  output [`DataWidth-1:0]			regReadData0, regReadData1, // DataWidth = 32

	input		[`RegNumWidth-1:0]	regWatchNum,
	output	[`DataWidth-1:0]		regWatchData
);

reg [`DataWidth-1:0] regs[31:0];

assign regReadData0 = (regNum0 != 0) ? regs[regNum0] : 0;
assign regReadData1 = (regNum1 != 0) ? regs[regNum1] : 0;
assign regWatchData = (regWatchNum != 0) ? regs[regWatchNum] : 0;

always @(negedge clk)
if (regWriteEnable && regWriteNum != 0)
begin
  regs[regWriteNum] <= regWriteData;
end

endmodule
