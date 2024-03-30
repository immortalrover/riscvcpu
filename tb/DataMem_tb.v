`timescale 1ns/1ns
module DataMem_tb();
reg            clk;
reg            memWriteEnable;
reg   [31:0]   memAddr; 
reg   [31:0]   memWriteData;
reg   [31:0]   PC;
wire  [31:0]   memReadData;
DataMem mem(clk,memWriteEnable,memAddr,memWriteData,PC,memReadData);
initial begin
	$dumpfile("build/test.vcd");	
	$dumpvars(0, DataMem_tb);
  clk = 1;
  memWriteEnable = 0;
  memAddr = 32'h200;
  memWriteData = 0;
  PC = 0;
end
always begin
  #50
  clk = ~clk;
  memWriteData  = memWriteData + 1;
end
always #200 memWriteEnable = ~memWriteEnable;
endmodule
