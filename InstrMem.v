module InstrMem(
  input  [31:0]   PC,
  output [31:0]		instrData
  );

  reg [31:0] RAM[0:1023];

  assign instrData = RAM[PC[11:2]]; 
endmodule
