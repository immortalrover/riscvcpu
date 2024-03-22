module alu (
  input                 clk,
  input         [3:0]   aluOp,
  input         [31:0]  aluX,
  input         [31:0]  aluY,
  output        [31:0]  aluO
);

// ALU Operations
parameter ADD                             = 4'h0;
parameter SUB                             = 4'h1;
parameter OR                              = 4'h2;
parameter XOR                             = 4'h3;
parameter AND                             = 4'h4;
parameter LesserThanUnsigned              = 4'h5;
parameter LesserThanSigned                = 4'h6;
parameter ShiftRightUnsigned              = 4'h7;
parameter ShiftRightSigned                = 4'h8;
parameter ShiftLeftUnsigned               = 4'h9;
parameter GreaterThanOrEqualUnsigned      = 4'hB;
parameter GreaterThanOrEqualSigned        = 4'hC;
parameter Equal                           = 4'hD;
parameter NotEqual                        = 4'hE;

reg [31:0] result;

always @(*) begin
  if (clk) begin    
    case (aluOp)
      ADD:                        result <= aluX +  aluY;
      SUB:                        result <= aluX -  aluY;
      OR:                         result <= aluX |  aluY;
      XOR:                        result <= aluX ^  aluY;
      AND:                        result <= aluX &  aluY;
      LesserThanUnsigned:         result <= aluX <  aluY;
      LesserThanSigned:           result <= $signed(aluX) < $signed(aluY);
      ShiftRightUnsigned:         result <= aluX >> (aluY[4:0]);
      ShiftRightSigned:           result <= $signed(aluX) >>> (aluY[4:0]);
      ShiftLeftUnsigned:          result <= aluX << (aluY[4:0]);
      GreaterThanOrEqualUnsigned: result <= aluX >= aluY;
      GreaterThanOrEqualSigned:   result <= $signed(aluX) >= $signed(aluY);
      Equal:                      result <= aluX == aluY;
      NotEqual:                   result <= aluX != aluY;
    endcase
  end
end

assign aluO = result;

endmodule

