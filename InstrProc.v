module InstrProc (
	input							clk,
	input		[31:0]		instr,
	output  [31:0]		immGen
);

	wire	[6:0]		opcode = instr[6:0];
	wire	[2:0]		func3 = instr[14:12];
	wire	[6:0]		func7 = instr[31:25];

	reg		[31:0]	imm;
	always @(posedge clk)
	begin
		case(opcode)
			7'b0010011, 7'b1100111, 7'b0000011:	// TypeI
				case(func3)
					3'b001, 3'b101: 
						imm <= { 20'b0, instr[31:20] };
					default:
						imm <= { { 21{ instr[31] } }, instr[30:20] };
				endcase
			7'b0100011:	// TypeS
				imm	<= { { 21{ instr[31] } }, instr[30:25], instr[11:7] };
			7'b1100011: // TypeB
				imm <= { { 20{ instr[31] } }, instr[7], instr[30:25], instr[11:8], 1'b0 };
			7'b0010111, 7'b0110111: // TypeU
				imm <= { instr[31:12], 12'b0 };
			7'b1101111: // TypeJ
				imm <= { { 13{ instr[31] } }, instr[19:12], instr[20], instr[30:21], 1'b0 };
		endcase
	end

	assign immGen = imm;
endmodule;
