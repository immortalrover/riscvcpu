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
	`LesserThanUnsigned:					alu_o = alu_x <  alu_y;
	`LesserThanSigned:						alu_o = $signed(alu_x) < $signed(alu_y);
	`ShiftRightUnsigned:					alu_o = alu_x >> (alu_y[4:0]);
	`ShiftRightSigned:						alu_o = $signed(alu_x) >>> (alu_y[4:0]);
	`ShiftLeftUnsigned:						alu_o = alu_x << (alu_y[4:0]); 
	`ShiftLeftSigned:							alu_o = alu_x << (alu_y[4:0]);
	`GreaterThanOrEqualUnsigned:	alu_o = alu_x >= alu_y;
	`GreaterThanOrEqualSigned:		alu_o = $signed(alu_x) >= $signed(alu_y);
	`Equal:												alu_o = alu_x == alu_y;
	`NotEqual:										alu_o = alu_x != alu_y;
endcase
endmodule
