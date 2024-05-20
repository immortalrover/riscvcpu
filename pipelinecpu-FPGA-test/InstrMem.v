`include "Defines.v"
module InstrMem(
  input  [`AddrWidth-1:0]		a, // AddrWidth = 32
  output [`InstrWidth-1:0]	spo // InstrWidth = 32
);

reg [`InstrWidth-1:0] RAM[0:1023];

assign spo = RAM[a[11:2]]; 
endmodule
