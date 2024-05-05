`include "Defines.v"
module RegsFile(
  input											clk, reset,
  input  [`RegNumWidth-1:0]	regNum0, regNum1, // RegNumWidth = 5
  output [`DataWidth-1:0]		regReadData0, regReadData1, // DataWidth = 32
  input											regsWriteEnable, // 1 => WRITE
  input  [`RegNumWidth-1:0]	regWriteNum,
  input  [`DataWidth-1:0]		regWriteData
);

reg [`DataWidth-1:0] regs[31:0];
integer i;
initial for ( i = 0; i < 32; i=i+1) regs[i] = 0;
assign regReadData0 = (regNum0 != 0) ? regs[regNum0] : 0;
assign regReadData1 = (regNum1 != 0) ? regs[regNum1] : 0;

always @(*) if (reset) for ( i = 0; i < 32; i=i+1) regs[i] = 0;

always @(negedge clk)
begin
  if (regsWriteEnable && regWriteNum != 0)
  begin
    regs[regWriteNum] <= regWriteData;
    $display("x%d = %h", regWriteNum, regWriteData);
  end
end

endmodule
