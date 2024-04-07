`include "Defines.v"
module ALU (
  input         [3:0]   aluOp,
  input         [31:0]  aluX,
  input         [31:0]  aluY,
  output reg    [31:0]  aluO
);

always @(*)
begin
  case (aluOp)
		`ADD:													aluO = aluX +  aluY;
		`SUB:													aluO = aluX -  aluY;
		`OR:													aluO = aluX |  aluY;
		`XOR:													aluO = aluX ^  aluY;
		`AND:													aluO = aluX &  aluY;
		`LesserThanUnsigned:					aluO = aluX <  aluY;
		`LesserThanSigned:						aluO = $signed(aluX) < $signed(aluY);
		`ShiftRightUnsigned:					aluO = aluX >> (aluY[4:0]);
		`ShiftRightSigned:						aluO = $signed(aluX) >>> (aluY[4:0]);
		`ShiftLeftUnsigned:						aluO = aluX << (aluY[4:0]); 
		`ShiftLeftSigned:							aluO = aluX << (aluY[4:0]);
		`GreaterThanOrEqualUnsigned:	aluO = aluX >= aluY;
		`GreaterThanOrEqualSigned:		aluO = $signed(aluX) >= $signed(aluY);
		`Equal:												aluO = aluX == aluY;
		`NotEqual:										aluO = aluX != aluY;
  endcase
end
endmodule
