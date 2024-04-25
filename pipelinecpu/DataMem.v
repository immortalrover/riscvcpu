`include "Defines.v"
module DataMem(
	input											clk,
  input		[`AddrWidth-1:0]	memReadAddr, // AddrWidth = 32
  input		[`AddrWidth-1:0]	memWriteAddr, // AddrWidth = 32
  output	[`DataWidth-1:0]	memReadData, // DataWidth = 32
	input											memWriteEnable, // 1 => Write
  input		[`DataWidth-1:0]	memWriteData, 
	input		[`AddrWidth-1:0]	pcReadData // AddrWidth = 32
);

reg  [`DataWidth-1:0] RAM[1023:0];

always @(*)
begin
	if (memWriteEnable)
	begin
		RAM[memWriteAddr[11:2]] = memWriteData;
	end
end

always @(posedge clk)
begin
	if(memWriteEnable)
	begin
		// DO NOT CHANGE THIS display LINE!!!
		// 不要修改下面这行display语句！！！
		// 对于所有的store指令，都输出位于写入目标地址四字节对齐处的32位数据，不需要修改下面的display语句
		/******************************************************************************************************/
		$display("pc = %h: dataaddr = %h, memdata = %h", pcReadData, {memWriteAddr[31:2],2'b00}, RAM[memWriteAddr[11:2]]);
		/******************************************************************************************************/
	end
end

assign memReadData = RAM[memReadAddr[11:2]]; 
endmodule
