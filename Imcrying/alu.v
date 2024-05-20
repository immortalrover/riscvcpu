`include "defines.v"
module alu (
  input       [`ALUOPWIDTH-1:0]	alu_op, // ALUOPWIDTH = 4
  input       [`ALUWIDTH-1:0]		alu_x, alu_y, // ALUWIDTH = 32
  output	reg	[`ALUWIDTH-1:0]		alu_o
);

always @(*)
case (alu_op)
	`ADD:													alu_o = alu_x +  alu_y;
	`SUB:													alu_o = alu_x -  alu_y;
	`OR:													alu_o = alu_x |  alu_y;
	`XOR:													alu_o = alu_x ^  alu_y;
	`AND:													alu_o = alu_x &  alu_y;
	`LESSERTHANUNSIGNED:					alu_o = alu_x <  alu_y;
	`LESSERTHANSIGNED:						alu_o = $signed(alu_x) < $signed(alu_y);
	`SHIFTRIGHTUNSIGNED:					alu_o = alu_x >> (alu_y[4:0]);
	`SHIFTRIGHTSIGNED:						alu_o = $signed(alu_x) >>> (alu_y[4:0]);
	`SHIFTLEFTUNSIGNED:						alu_o = alu_x << (alu_y[4:0]); 
	`SHIFTLEFTSIGNED:							alu_o = alu_x << (alu_y[4:0]);
	`GREATERTHANOREQUALUNSIGNED:	alu_o = alu_x >= alu_y;
	`GREATERTHANOREQUALSIGNED:		alu_o = $signed(alu_x) >= $signed(alu_y);
	`EQUAL:												alu_o = alu_x == alu_y;
	`NOTEQUAL:										alu_o = alu_x != alu_y;
endcase
endmodule
