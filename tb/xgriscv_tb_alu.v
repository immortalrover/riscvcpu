`timescale 1ns/1ps
module xgriscv_tb_alu();
   
reg            clk;
reg   [3:0]	   aluOp;
reg   [31:0]   aluX;
reg   [31:0]   aluY;
wire  [31:0]   aluO;

initial begin
   clk = 1;
   aluOp = 0;
   aluX = 1;
   aluY = 2;
end   
always #50 clk = ~clk;
alu U_alu (.clk(clk),.aluOp(aluOp), .aluX(aluX), .aluY(aluY), .aluO(aluO));

endmodule
