`include "Defines.v"
module regFile(
  input										clk,
	input										reset,
  input  [4:0]						regNum0,
  input  [4:0]						regNum1,
  output [`DataWidth-1:0] regReadData0, // DataWidth = 32
  output [`DataWidth-1:0] regReadData1,

  input										regWriteEnable, // 1 => WRITE
  input  [4:0]						regWriteNum,
  input  [`DataWidth-1:0]	regWriteData
);

reg [`DataWidth-1:0] reg[31:0];

integer i;
initial for ( i = 0; i < 32; i=i+1) reg[i] = 0;
always @(*) if (reset) for ( i = 0; i < 32; i=i+1) reg[i] = 0;

// three ported register file
// read two ports combinationally
// write third port on falling edge of clock
// register 0 hardwired to 0

always @(negedge clk)
begin
  if (regWriteEnable && regWriteNum != 0)
  begin
    reg[regWriteNum] <= regWriteData;
    // DO NOT CHANGE THIS display LINE!!!
    // 不要修改下面这行display语句！！！
    /**********************************************************************/
    $display("x%d = %h", regWriteNum, regWriteData);
    /**********************************************************************/
  end
end

assign regReadData0 = (regNum0 != 0) ? reg[regNum0] : 0;
assign regReadData1 = (regNum1 != 0) ? reg[regNum1] : 0;
endmodule
