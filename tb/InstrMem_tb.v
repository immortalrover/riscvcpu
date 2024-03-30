`timescale 1ns/1ps
module InstrMem_tb();
  reg		[31:0]	PC;
  wire	[31:0]	instrData;

  initial begin
    $readmemh("tb/riscv32_sim1.dat", instr.RAM);
		$dumpfile("build/test.vcd");
		$dumpvars(0, InstrMem_tb);
    PC = 0;
  end
  always #50 PC = PC + 4;
  InstrMem instr(.PC(PC), .instrData(instrData));
endmodule
