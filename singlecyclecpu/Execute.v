`include "Defines.v"
module Execute (
	input												clk, reset,
	input		[`OpcodeWidth-1:0]	opcode, // OpcodeWidth = 7
	input		[`Func3Width-1:0]		func3, // Func3Width = 3
	input		[`Func7Width-1:0]		func7, // Func7Width = 7
	input		[`RegNumWidth-1:0]	regNum0, regNum1, regWriteNum, // RegNumWidth = 5
	input		[`DataWidth-1:0]		imm, // DataWidth = 32
	input		[`AddrWidth-1:0]		PC, // AddrWidth = 32
	output											pcWriteEnable,
	output	[`DataWidth-1:0]		pcWriteData
);

reg		[`ALUOpWidth-1:0]	aluOp; // ALUOpWidth = 5
reg		[`DataWidth-1:0]	aluX, aluY;
wire	[`DataWidth-1:0]	aluO;
wire	[`DataWidth-1:0]	regReadData0, regReadData1;
wire										regWriteEnable;
wire	[`DataWidth-1:0]	regWriteData;
reg		[`AddrWidth-1:0]	memAddr; // AddrWidth = 32
wire										memReadEnable;
wire	[`DataWidth-1:0]	memReadData;
wire										memWriteEnable;
reg		[`DataWidth-1:0]	memWriteData;
reg		[`StateWidth-1:0] state;

always @(*)
begin
	if (reset) begin
		aluOp						=	`ADD;
		aluX						=	0;
		aluY						=	0;
		state						=	`IDLE;
	end
	else if (clk)
	begin
	case (opcode)
		7'b0110011: // FMT R
		begin
			case (func3)
				0: aluOp		=	func7[5] ? `SUB : `ADD;	// add sub
				1: aluOp		=	`ShiftLeftUnsigned;	// sll
				2: aluOp		=	`LesserThanSigned;	// slt
				3: aluOp		=	`LesserThanUnsigned; // sltu
				4: aluOp		=	`XOR; // xor
				5: aluOp		=	func7[5] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srl sra
				6: aluOp		=	`OR; // or
				7: aluOp		=	`AND; // and
			endcase
			aluX					=	regReadData0;
			aluY					=	regReadData1;
			state					=	`RegWrite;
		end
		7'b0010011: // FMT I
		begin
			case (func3)
				0: aluOp		=	`ADD;	// addi
				1: aluOp		=	`ShiftLeftUnsigned;	// slli
				2: aluOp		=	`LesserThanSigned;	// slti
				3: aluOp		=	`LesserThanUnsigned; // sltiu
				4: aluOp		=	`XOR; // xori
				5: aluOp		=	imm[10] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srli srai
				6: aluOp		=	`OR; // ori
				7: aluOp		=	`AND; // andi
			endcase
			aluX					=	regReadData0;
			aluY					=	imm;
			state					=	`RegWrite;
		end
		7'b0000011: // FMT I lb lh lw lbu lhu
		begin
			aluX					=	regReadData0;
			aluY					=	imm;
			aluOp					=	`ADD;
			state					=	`MemReadRegWrite;
		end
		7'b0100011: // FMT S sb sh sw
		begin
			aluX					=	regReadData0;
			aluY					=	imm;
			aluOp					=	`ADD;
			state					=	`MemWrite;
		end
		7'b1100011: // FMT B
		begin
			case (func3)
				0: aluOp		=	`Equal; // beq
				1: aluOp		=	`NotEqual; // bne
				4: aluOp		=	`LesserThanSigned; // blt
				5: aluOp		=	`GreaterThanOrEqualSigned; // bge
				6: aluOp		=	`LesserThanUnsigned; // bltu
				7: aluOp		=	`GreaterThanOrEqualUnsigned; // bgeu
			endcase
			aluX					=	regReadData0;
			aluY					=	regReadData1;
			state					=	`PCSelectWrite;
		end
		7'b1101111: // FMT J jal
		begin
			aluX					=	PC;
			aluY					=	imm;
			aluOp					=	`ADD;
			state					=	`PCWrite;
		end
		7'b1100111: // FMT I jalr
		begin
			aluX					=	regReadData0;
			aluY					=	imm;
			aluOp					=	`ADD;
			state					=	`PCWrite;
		end
		7'b0110111: // FMT U lui
		begin
			state					=	`LuiRegWrite;
		end
		7'b0010111: // FMT U auipc
		begin
			aluX					=	PC;
			aluY					=	imm;
			aluOp					=	`ADD;
			state					=	`RegWrite;
		end
		default: state	= `IDLE;
	endcase
	end
end

ALU	alu(aluOp, aluX, aluY, aluO);

Controller control(
	clk, reset, state, 
	func3, imm, regReadData1, aluO, PC,
	regWriteEnable, regWriteData, pcWriteEnable, pcWriteData
);

RegsFile RF(
	clk, reset, regNum0, regNum1, regReadData0, regReadData1, 
	regWriteEnable, regWriteNum, regWriteData
);
endmodule
