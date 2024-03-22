`timescale 1ns/1ps
module xgriscv_tb_imem();
   reg [31:0] pc;
   wire [31:0] instr;
   imem U_imem(.a(pc), .rd(instr));
   initial begin
      $readmemh("riscv32_sim1.dat", U_imem.RAM);
      pc = 0;
   end
   always #50 pc = pc + 4;
endmodule
