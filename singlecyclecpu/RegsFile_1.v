`include "Defines.v"
module RegsFile(
  input												clk,
	input												reset,
  input  [`RegNumWidth-1:0]		regNum0, // RegNumWidth = 5
  input  [`RegNumWidth-1:0]		regNum1,
  output [`DataWidth-1:0]			regReadData0, // DataWidth = 32
  output [`DataWidth-1:0]			regReadData1,

  input												regWriteEnable, // 1 => WRITE
  input  [`RegNumWidth-1:0]		regWriteNum,
  input  [`DataWidth-1:0]			regWriteData,

	input	 [`AddrWidth-1:0]			PC
);

reg [`DataWidth-1:0] regs[31:0];
reg	[`AddrWidth-1:0] pcData[4:0];

integer i;
initial for ( i = 0; i < 32; i=i+1) regs[i] = 0;
always @(*) if (reset) for ( i = 0; i < 32; i=i+1) regs[i] = 0;
always @(*) pcData[4] = PC;

// three ported register file
// read two ports combinationally
// write third port on falling edge of clock
// register 0 hardwired to 0

always @(negedge clk)
begin
  if (regWriteEnable && regWriteNum != 0)
  begin
    regs[regWriteNum] <= regWriteData;
    // DO NOT CHANGE THIS display LINE!!!
    // 不要修改下面这行display语句！！！
    /**********************************************************************/
    $display("pc = %h: x%d = %h", pcData[0], regWriteNum, regWriteData);
    /**********************************************************************/
  end
end

always @(posedge clk)
begin
	pcData[3] <= pcData[4];
	pcData[2] <= pcData[3];
	pcData[1] <= pcData[2];
	pcData[0] <= pcData[1];
end

assign regReadData0 = (regNum0 != 0) ? regs[regNum0] : 0;
assign regReadData1 = (regNum1 != 0) ? regs[regNum1] : 0;
endmodule
