module regfile(
  input             clk,
  input  [4:0]  	ra1, ra2,
  output [31:0]     rd1, rd2,

  input             we3, 
  input  [4:0]  	wa3,
  input  [31:0]     wd3
  );

  reg [31:0] rf[31:0];

  integer i;

  initial begin
    for ( i = 0; i < 32; i=i+1)  rf[i] = 0;
  end

  // three ported register file
  // read two ports combinationally
  // write third port on falling edge of clock
  // register 0 hardwired to 0

  always @(negedge clk)
    if (we3 && wa3 != 0)
      begin
        rf[wa3] <= wd3;
        // DO NOT CHANGE THIS display LINE!!!
        // 不要修改下面这行display语句！！！
        /**********************************************************************/
        $display("x%d = %h", wa3, wd3);
        /**********************************************************************/
      end

  assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
  assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule
