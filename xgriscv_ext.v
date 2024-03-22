module ext(
    input                   clk,
    input           [11:0]	immTypeI,
    input           [11:0]	immTypeS,
    input           [12:0]	immTypeB,
    input           [19:0]	immTypeU,
    input           [19:0]	immTypeJ,
    input           [2:0]	extOp,
    output       [31:0]  immO
);

reg [31:0]  imm;
always @(*) begin
    case (extOp)
		0:     imm  <=  { 20'b0,              immTypeI[11:0] };
		1:	   imm  <=  { {20{immTypeI[11]}}, immTypeI[11:0] };
		2:	   imm  <=  { {20{immTypeS[11]}}, immTypeS[11:0] };
		3:	   imm  <=  { {19{immTypeB[12]}}, immTypeB[12:0] };
        4:     imm  <=  { immTypeU[19:0], 12'b0              };
        5:     imm  <=  { {12{immTypeJ[19]}}, immTypeJ[19:0] };
	endcase
end
assign  immO    = imm;
endmodule