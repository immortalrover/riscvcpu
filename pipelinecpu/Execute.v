`include "Defines.v"
module Execute (
	input														clk,
	input														reset,
	input				[`OpcodeWidth-1:0]	opcode, // OpcodeWidth = 7
	input				[`Func3Width-1:0]		func3, // Func3Width = 3
	input				[`Func7Width-1:0]		func7, // Func7Width = 7
	input				[`DataWidth-1:0]		regReadData0, // DataWidth = 32
	input				[`DataWidth-1:0]		regReadData1a, regReadData1b,
	output													regWriteEnable,
	output			[`DataWidth-1:0]		regWriteData,
	input				[`DataWidth-1:0]		imm,
	input				[`AddrWidth-1:0]		pcReadData, // AddrWidth = 32
	output			[`DataWidth-1:0]		pcWriteData,
	output			[`PCOpWidth-1:0]		pcOp // PCOpWidth = 2
);

reg		[`ALUOpWidth-1:0]		aluOp[1:0]; // ALUOpWidth = 5
reg		[`DataWidth-1:0]		aluX[1:0];
reg		[`DataWidth-1:0]		aluY[1:0];
wire	[`DataWidth-1:0]		aluO;
ALU	alu(aluOp[0], aluX[0], aluY[0], aluO);

reg		[`StateWidth-1:0]		state[1:0]; // StateWidth = 4
reg		[`DataWidth-1:0]		immData[1:0];
wire	[`AddrWidth-1:0]		memReadAddr;
wire	[`AddrWidth-1:0]		memWriteAddr;
wire											memReadEnable;
wire	[`DataWidth-1:0]		memReadData;
wire											memWriteEnable;
wire	[`DataWidth-1:0]		memInData;
reg		[`DataWidth-1:0]		memWriteData[1:0]; // pipe?
Controller control(
	clk, state[0], 
	func3Data[0], immData[0], regReadData1b, aluO, pcReadData,
	regWriteEnable, regWriteData,
	memReadAddr, memWriteAddr,memReadData, memWriteEnable, memInData,
	pcOp, pcWriteData
);

/* reg		[`AddrWidth-1:0]		memWriteAddr; // AddrWidth = 32 */

DataMem mem(clk, memReadAddr, memWriteAddr, memReadData, memWriteEnable, memWriteData[0], pcReadData);

reg		[`DataWidth-1:0]		regInData[1:0];
reg		[`Func3Width-1:0]		func3Data[1:0];

always @(*)
begin
	if (reset) begin
		aluOp[1] = `ADD;
		aluX[1] = 0;
		aluY[1] = 0;
		regInData[1] = 0;
		/* state[1] = `IDLE; */
	end
	else if (clk)
	begin
	case (opcode)
		7'b0110011: // FMT R
		begin
			case (func3)
				0: aluOp[1] = func7[5] ? `SUB : `ADD;	// add sub
				1: aluOp[1] = `ShiftLeftUnsigned;	// sll
				2: aluOp[1] = `LesserThanSigned;	// slt
				3: aluOp[1] = `LesserThanUnsigned; // sltu
				4: aluOp[1] = `XOR; // xor
				5: aluOp[1] = func7[5] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srl sra
				6: aluOp[1] = `OR; // or
				7: aluOp[1] = `AND; // and
			endcase
			aluX[1] = regReadData0;
			aluY[1] = regReadData1a;
			state[1] = `RegWrite;
		end
		7'b0010011: // FMT I
		begin
			case (func3)
				0: aluOp[1] = `ADD;	// addi
				1: aluOp[1] = `ShiftLeftUnsigned;	// slli
				2: aluOp[1] = `LesserThanSigned;	// slti
				3: aluOp[1] = `LesserThanUnsigned; // sltiu
				4: aluOp[1] = `XOR; // xori
				5: aluOp[1] = imm[10] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srli srai
				6: aluOp[1] = `OR; // ori
				7: aluOp[1] = `AND; // andi
			endcase
			aluX[1] = regReadData0;
			aluY[1] = imm;
			state[1] = `RegWrite;
		end
		7'b0000011: // FMT I lb lh lw lbu lhu
		begin
			aluX[1] = regReadData0;
			aluY[1] = imm;
			aluOp[1] = `ADD;
			state[1] = `MemReadRegWrite; // Read memory and write register
		end
		7'b0100011: // FMT S sb sh sw
		begin
			aluX[1] = regReadData0;
			aluY[1] = imm;
			aluOp[1] = `ADD;
			state[1]	= `MemWrite;
		end
		7'b1100011: // FMT B
		begin
			case (func3)
				0: aluOp[1] = `Equal; // beq
				1: aluOp[1] = `NotEqual; // bne
				4: aluOp[1] = `LesserThanSigned; // blt
				5: aluOp[1] = `GreaterThanOrEqualSigned; // bge
				6: aluOp[1] = `LesserThanUnsigned; // bltu
				7: aluOp[1] = `GreaterThanOrEqualUnsigned; // bgeu
			endcase
			aluX[1] = regReadData0;
			aluY[1] = regReadData1a;
			state[1] = `PCSelectWrite;
		end
		7'b1101111: // FMT J jal
		begin
			aluX[1] = pcReadData;
			aluY[1] = imm;
			aluOp[1] = `ADD;
			state[1]	= `RegWrite;
		end
		7'b1100111: // FMT I jalr
		begin
			aluX[1] = regReadData0;
			aluY[1] = imm;
			aluOp[1] = `ADD;
			state[1]	=	`RegWrite;
		end
		7'b0110111: // FMT U lui
		begin
			// WAITING
			regInData[1] = imm;
			state[1]	=	`RegWrite;
		end
		7'b0010111: // FMT U auipc
		begin
			aluX[1] = pcReadData;
			aluY[1] = imm;
			aluOp[1]	=	`ADD;
			state[1]	=	`RegWrite;
		end
		default: state[1] = `IDLE;
	endcase
	end
	immData[1] = imm;
	func3Data[1] = func3;
end

always @(posedge clk)
begin
	aluX[0] <= aluX[1];
	aluY[0] <= aluY[1];
	aluOp[0] <= aluOp[1];
	state[0] <= state[1];
	immData[0] <= immData[1];
	memWriteData[0] <= memWriteData[1];
	func3Data[0] <= func3Data[1];
end
endmodule
