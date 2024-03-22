`timescale 1ns/1ps
module xgriscv_tb_ext();
   
reg            clk;
reg   [11:0]	immTypeI;
reg   [11:0]	immTypeS;
reg   [12:0]	immTypeB;
reg   [19:0]	immTypeU;
reg   [19:0]	immTypeJ;
reg   [2:0]	   extOp;
wire  [31:0]   immout;

initial begin
   clk               = 0;
   immTypeI          = 1;
   immTypeS          = 2;
   immTypeB          = 3;
   immTypeU          = 20'hF1F2F;
   immTypeJ          = 4;
   extOp             = 3'b100;
end   
always #50 clk = ~clk;

ext xgriscv_ext(
   .clk(clk), 
   .immTypeI(immTypeI), 
   .immTypeS(immTypeS), 
   .immTypeB(immTypeB), 
   .immTypeU(immTypeU), 
   .immTypeJ(immTypeJ), 
   .extOp(extOp), 
   .immout(immout)
);
endmodule
