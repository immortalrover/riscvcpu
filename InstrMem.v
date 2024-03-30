module InstrMem(
  input  [31:0]   instrAddr,
  output [31:0]		instrData
  );

  reg [31:0] RAM[0:1023];

  assign instrData = RAM[instrAddr[11:2]]; 
endmodule
