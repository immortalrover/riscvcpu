`include "Defines.v"
module ALU (
  input                 clk, // TARGET: delete the clk
  input         [3:0]   aluOp,
  input         [31:0]  aluX,
  input         [31:0]  aluY,
  output        [31:0]  aluO
);

reg [31:0] result;
always @(posedge clk)
begin
  case (aluOp)
		`ADD:                        result <= aluX +  aluY;
		`SUB:                        result <= aluX -  aluY;
		`OR:                         result <= aluX |  aluY;
		`XOR:                        result <= aluX ^  aluY;
		`AND:                        result <= aluX &  aluY;
		`LesserThanUnsigned:         result <= aluX <  aluY;
		`LesserThanSigned:           result <= $signed(aluX) < $signed(aluY);
		`ShiftRightUnsigned:         result <= aluX >> (aluY[4:0]);
		`ShiftRightSigned:           result <= $signed(aluX) >>> (aluY[4:0]);
		`ShiftLeftUnsigned:          result <= aluX << (aluY[4:0]);
		`GreaterThanOrEqualUnsigned: result <= aluX >= aluY;
		`GreaterThanOrEqualSigned:   result <= $signed(aluX) >= $signed(aluY);
		`Equal:                      result <= aluX == aluY;
		`NotEqual:                   result <= aluX != aluY;
  endcase
end
assign aluO = result;

endmodule
