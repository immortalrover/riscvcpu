`timescale 1ns/1ns
module xgriscv_tb();
    
   reg                  clk, rstn;
   wire[31:0] pc;
   wire  [31:0] instr;
   wire        memWrite;
   wire[31:0]  writeData;
   wire[31:0] aluX;
   wire[31:0] aluY;
   wire[31:0] aluO;
    
   // instantiation of xgriscv_sc
   xgriscv_sc sc(clk, rstn, pc,instr,memWrite,writeData,aluX,aluY,aluO);

   integer counter = 0;
   
   initial begin
      $readmemh("riscv32_sim1.dat", sc.U_imem.RAM);
      clk = 1;
      rstn = 1;
      #5 ;
      rstn = 0;
   end
   
   always begin
      #300 clk = ~clk;
     
      if (clk == 1'b1) 
      begin
         counter = counter + 1;
         //comment out all display line(s) for online judge
         if (pc == 32'h00000030) // set to the address of the last instruction
          begin

            $stop;
          end
      end  
   end //end always
   
endmodule
