`timescale 1ns/1ns
module ALU_tb();
reg            clk;
reg   [3:0]	   aluOp;
reg   [31:0]   aluX;
reg   [31:0]   aluY;
wire  [31:0]   aluO;

initial begin
	$dumpfile("build/test.vcd");
	$dumpvars;
	clk = 1;
  aluOp = 0;
  aluX = 1;
  aluY = 2;
end   
always #50 clk = ~clk;
always #300 aluOp = aluOp + 1;
ALU alu(.clk(clk),.aluOp(aluOp), .aluX(aluX), .aluY(aluY), .aluO(aluO));

endmodule
