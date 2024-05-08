`timescale 1ns/1ns

module CPU_tb();
reg					clk;
reg					reset;
reg	[15:0]	switches;
wire[7:0]	disp_seg_o, disp_an_o;
    
CPU cpu(clk, reset, switches, disp_seg_o, disp_an_o);

integer counter = 0;

initial begin
	$dumpfile("build/test.vcd");
	$dumpvars;
  /* $readmemh("tb/riscv32_simtest.dat", cpu.instrMem.RAM); */
  clk = 0;
end

always begin
   #300 clk = ~clk;
  
   if (clk == 1'b1) 
   begin
      counter = counter + 1;
      //comment out all display line(s) for online judge
      if (counter == 500) // set to the address of the last instruction
       begin

         $stop;
       end
   end  
end //end always

endmodule
