`include "Defines.v"
module InstrMem(
  input  [`AddrWidth-1:0]		instrAddr, // AddrWidth = 32
  output [`InstrWidth-1:0]	instrData // InstrWidth = 32
);

reg [`InstrWidth-1:0] RAM[0:1023];

assign instrData = RAM[instrAddr[11:2]]; 
endmodule
