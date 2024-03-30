module DataMem(
	input						clk,
	input						memWriteEnable, // 1 => Write, Default Read
  input  [31:0]		memAddr, 
  input  [31:0]		memWriteData, 
	input  [31:0]   PC,
  output [31:0]   memReadData
	);

  reg  [31:0] RAM[0:1023];

  assign memReadData = RAM[memAddr[11:2]]; 

  always @(posedge clk)
    if (memWriteEnable)
      begin
        RAM[memAddr[11:2]] = memWriteData;
        // DO NOT CHANGE THIS display LINE!!!
        // 不要修改下面这行display语句！！！
        // 对于所有的store指令，都输出位于写入目标地址四字节对齐处的32位数据，不需要修改下面的display语句
        /**********************************************************************/
        /* $display("pc = %h: dataaddr = %h, memdata = %h", PC, {memAddr[31:2],2'b00}, RAM[memAddr[11:2]]); */
        /**********************************************************************/
  	  end
endmodule
