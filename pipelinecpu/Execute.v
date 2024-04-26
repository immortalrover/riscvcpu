`include "Defines.v"
module Execute (
	input														clk,
	input														reset,
	input				[`OpcodeWidth-1:0]	opcode, // OpcodeWidth = 7
	input				[`Func3Width-1:0]		func3, // Func3Width = 3
	input				[`Func7Width-1:0]		func7, // Func7Width = 7
	input				[`DataWidth-1:0]		regReadData0, // DataWidth = 32
	input				[`DataWidth-1:0]		regReadData1,
	output													regWriteEnable,
	output			[`DataWidth-1:0]		regWriteData,
	input				[`DataWidth-1:0]		imm,
	input				[`AddrWidth-1:0]		pcReadData, // AddrWidth = 32
	output			[`DataWidth-1:0]		pcWriteData,
	output			[`PCOpWidth-1:0]		pcOp, // PCOpWidth = 2

	input														forward1,
	output			[`DataWidth-1:0]		aluO1
);

reg		[`DataWidth-1:0]		regOutData1[1:0];
reg		[`DataWidth-1:0]		aluOut[1:0];
reg		[`ALUOpWidth-1:0]		aluOp; // ALUOpWidth = 5
reg		[`DataWidth-1:0]		aluX;
reg		[`DataWidth-1:0]		aluY;
wire	[`DataWidth-1:0]		aluO;
reg		[`StateWidth-1:0]		state[1:0]; // StateWidth = 4
reg		[`DataWidth-1:0]		immData[1:0];
wire	[`AddrWidth-1:0]		memAddr;
wire	[`DataWidth-1:0]		memReadData;
wire											memWriteEnable;
wire	[`DataWidth-1:0]		memWriteData;
/* reg		[`AddrWidth-1:0]		memWriteAddr; // AddrWidth = 32 */
reg		[`DataWidth-1:0]		regInData[1:0];
reg		[`Func3Width-1:0]		func3Data[1:0];

always @(*)
begin
	if (reset) begin
		aluOp = `ADD;
		aluX = 0;
		aluY = 0;
		regInData[1] = 0;
		/* state[1] = `IDLE; */
	end
	else if (clk)
	begin
	case (opcode)
		7'b0110011: // FMT R
		begin
			case (func3)
				0: aluOp = func7[5] ? `SUB : `ADD;	// add sub
				1: aluOp = `ShiftLeftUnsigned;	// sll
				2: aluOp = `LesserThanSigned;	// slt
				3: aluOp = `LesserThanUnsigned; // sltu
				4: aluOp = `XOR; // xor
				5: aluOp = func7[5] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srl sra
				6: aluOp = `OR; // or
				7: aluOp = `AND; // and
			endcase
			aluX = regReadData0;
			aluY = regOutData1[1]; // regOutData1 === regReadData1
			state[1] = `RegWrite;
		end
		7'b0010011: // FMT I
		begin
			case (func3)
				0: aluOp = `ADD;	// addi
				1: aluOp = `ShiftLeftUnsigned;	// slli
				2: aluOp = `LesserThanSigned;	// slti
				3: aluOp = `LesserThanUnsigned; // sltiu
				4: aluOp = `XOR; // xori
				5: aluOp = imm[10] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srli srai
				6: aluOp = `OR; // ori
				7: aluOp = `AND; // andi
			endcase
			aluX = regReadData0;
			aluY = imm;
			state[1] = `RegWrite;
		end
		7'b0000011: // FMT I lb lh lw lbu lhu
		begin
			aluX = regReadData0;
			aluY = imm;
			aluOp = `ADD;
			state[1] = `MemReadRegWrite; // Read memory and write register
		end
		7'b0100011: // FMT S sb sh sw
		begin
			aluX = regReadData0;
			aluY = imm;
			aluOp = `ADD;
			state[1]	= `MemWrite;
		end
		7'b1100011: // FMT B
		begin
			case (func3)
				0: aluOp = `Equal; // beq
				1: aluOp = `NotEqual; // bne
				4: aluOp = `LesserThanSigned; // blt
				5: aluOp = `GreaterThanOrEqualSigned; // bge
				6: aluOp = `LesserThanUnsigned; // bltu
				7: aluOp = `GreaterThanOrEqualUnsigned; // bgeu
			endcase
			aluX = regReadData0;
			aluY = regOutData1[1];
			state[1] = `PCSelectWrite;
		end
		7'b1101111: // FMT J jal
		begin
			aluX = pcReadData;
			aluY = imm;
			aluOp = `ADD;
			state[1]	= `RegWrite;
		end
		7'b1100111: // FMT I jalr
		begin
			aluX = regReadData0;
			aluY = imm;
			aluOp = `ADD;
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
			aluX = pcReadData;
			aluY = imm;
			aluOp	=	`ADD;
			state[1]	=	`RegWrite;
		end
		default: state[1] = `IDLE;
	endcase
	end
	immData[1] = imm;
	func3Data[1] = func3;
	regOutData1[1] = regReadData1;
	aluOut[1] = aluO;
end

always @(posedge clk)
begin
	state[0] <= state[1];
	immData[0] <= immData[1];
	func3Data[0] <= func3Data[1];
	regOutData1[0] <= regOutData1[1];
	aluOut[0] <= aluOut[1];
end

assign aluO1 = forward1 ? aluOut[1] : 0;

ALU	alu(aluOp, aluX, aluY, aluO);

Controller control(
	clk, reset,state[0], 
	func3Data[0], immData[0], regOutData1[0], aluOut[0], pcReadData,
	regWriteEnable, regWriteData,
	memAddr, memReadData, memWriteEnable, memWriteData,
	pcOp, pcWriteData
);

DataMem mem(clk, memAddr, memReadData, memWriteEnable, memWriteData, pcReadData);

endmodule
