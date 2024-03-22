`timescale 1ns/1ps
module xgriscv_tb_id();
    
   reg         clk;
   reg   [6:0] opcode;
   reg   [6:0] func7;
   reg   [2:0] func3;
   wire        aluSrc;
   wire  [1:0] dataSel;
   wire        wdSel;
   wire        regWrite; 
   wire        memWrite;
   wire        pcSrc;
   wire  [2:0] dmType;
   wire  [3:0] aluOp;  
   wire  [2:0] extOp;

   initial begin
      clk               = 0;
      opcode            = 7'b0010111;
      func3             = 0;
      func7             = 0;
   end   
   always #50 clk = ~clk;

   id xgriscv_id(clk,opcode,func7,func3,aluSrc,dataSel,wdSel,regWrite,memWrite,pcSrc,dmType,aluOp,extOp);
endmodule
