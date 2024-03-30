module RegsFile(
  input           clk,
  input  [4:0]  	regsNum0,
  input  [4:0]  	regsNum1,
  output [31:0]   regsReadData0,
  output [31:0]   regsReadData1,
  input           regsWriteEnable, // 1 => WRITE, 0 => READ
  input  [4:0]  	regsWriteNum,
  input  [31:0]   regsWriteData
  );

  reg [31:0] regs[31:0];

  integer i;

  initial begin
    for ( i = 0; i < 32; i=i+1)  regs[i] = 0;
  end

  // three ported register file
  // read two ports combinationally
  // write third port on falling edge of clock
  // register 0 hardwired to 0

  always @(negedge clk)
    if (regsWriteEnable && regsWriteNum != 0)
      begin
        regs[regsWriteNum] <= regsWriteData;
        // DO NOT CHANGE THIS display LINE!!!
        // 不要修改下面这行display语句！！！
        /**********************************************************************/
        $display("x%d = %h", regsWriteNum, regsWriteData);
        /**********************************************************************/
      end

  assign regsReadData0 = (regsNum0 != 0) ? regs[regsNum0] : 0;
  assign regsReadData1 = (regsNum1 != 0) ? regs[regsNum1] : 0;
endmodule
