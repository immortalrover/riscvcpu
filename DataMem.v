module DataMem(
	input							clk,
  input		[31:0]		memAddr, 
	input							memReadEnable, // 1 => Read
  output	[31:0]		memReadData,
	input							memWriteEnable, // 1 => Write
  input		[31:0]		memWriteData, 
	input		[31:0]		pcReadData
);

reg  [31:0] RAM[0:1023];

assign memReadData = memReadEnable ? RAM[memAddr[11:2]] : 0; 
always @(*)
begin
	if (memWriteEnable)
	begin
		RAM[memAddr[11:2]] = memWriteData;
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
		$display("pc = %h: dataaddr = %h, memdata = %h", pcReadData, {memAddr[31:2],2'b00}, RAM[memAddr[11:2]]);
		/******************************************************************************************************/
	end
end
endmodule
