`include "Defines.v"
module InstrDec (
	input						clk,
	input		[6:0]		opcode,
	input		[2:0]		func3,
	input		[6:0]		func7,
	input		[31:0]	imm,
	input		[4:0]		regNum0,
	input		[4:0]		regNum1,
	output	[31:0]	aluO
	/* output [3:0] aluOp */
);

wire	[31:0]	regReadData0;
wire	[31:0]	regReadData1;
wire					regsWriteEnable;
wire	[4:0]		regWriteNum;
wire	[31:0]	regWriteData;

RegsFile RF(clk, regNum0, regNum1, regReadData0, regReadData1, regsWriteEnable, regWriteNum, regWriteData);

reg [3:0] aluOp;
reg	[3:0]	currentState;

always @(posedge clk)
begin
	case (opcode)
		7'b0110011: // FMT R
		begin
			case (func3)
				0: aluOp		<= func7[5] ? `SUB : `ADD;	// add sub
				1: aluOp		<= `ShiftLeftUnsigned;	// sll
				2: aluOp		<= `LesserThanSigned;	// slt
				3: aluOp		<= `LesserThanUnsigned; // sltu
				4: aluOp		<= `XOR; // xor
				5: aluOp		<= func7[5] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srl sra
				6: aluOp		<= `OR; // or
				7: aluOp		<= `AND; // and
			endcase
			aluX					<= regReadData0;
			aluY					<= regReadData1;
			currentState	<= 0;							//Wait
		end
		7'b0110011: // FMT I
		begin
			case (func3)
				0: aluOp		<= `ADD;	// addi
				1: aluOp		<= `ShiftLeftUnsigned;	// slli
				2: aluOp		<= `LesserThanSigned;	// slti
				3: aluOp		<= `LesserThanUnsigned; // sltiu
				4: aluOp		<= `XOR; // xori
				5: aluOp		<= imm[10] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srli srai
				6: aluOp		<= `OR; // ori
				7: aluOp		<= `AND; // andi
			endcase
			aluX					<= regReadData0;
			aluY					<= imm;
			currentState	<= 0;							//Wait
		end
		7'b0000011: // FMT I
		begin
			case (func3)
				0: aluOp		<= func7[5] ? `SUB : `ADD;	// add sub
				1: aluOp		<= `ShiftLeftUnsigned;	// sll
				2: aluOp		<= `LesserThanSigned;	// slt
				3: aluOp		<= `LesserThanUnsigned; // sltu
				4: aluOp		<= `XOR; // xor
				5: aluOp		<= func7[5] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srl sra
				6: aluOp		<= `OR; // or
				7: aluOp		<= `AND; // and
			endcase
			aluX					<= regReadData0;
			aluY					<= regReadData1;
			currentState	<= 0;							//Wait
		end
	endcase
end

ALU	alu(clk, aluOp, aluX, aluY, aluO);
/* assign aluOp = OP; */
endmodule
