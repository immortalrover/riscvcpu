`timescale 1ns/1ps
module xgriscv_tb_dmem();
reg            clk;
reg            we;
reg   [31:0]   a; 
reg   [31:0]   wd;
reg   [31:0]   pc;
wire  [31:0]   rd;
dmem U_dmem(clk,we,a,wd,pc,rd);
initial begin
   clk   =  1;
   we    =  0;
   a     =  32'h200;
   wd    =  0;
   pc    =  0;
end
always begin
   #50
   clk = ~clk;
   wd  = wd + 1;
end
always #200 we = ~we;
endmodule
