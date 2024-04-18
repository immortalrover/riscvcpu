`include "Defines.v"
module Execute (
	input													clk,
	input													reset,
	input				[6:0]							opcode,
	input				[2:0]							func3,
	input				[6:0]							func7,
	input				[`DataWidth-1:0]	regReadData0, // DataWidth = 32
	input				[`DataWidth-1:0]	regReadData1,
	output												regsWriteEnable,
	output			[`DataWidth-1:0]	regWriteData,
	input				[`DataWidth-1:0]	imm,
	input				[`AddrWidth-1:0]	pcReadData, // AddrWidth = 32
	output	reg	[`DataWidth-1:0]	pcWriteData,
	output	reg [2:0]							pcOp
);

reg		[2*`ALUOpWidth-1:0]							aluOp;
reg		[2*`DataWidth-1:0]	aluX;
reg		[2*`DataWidth-1:0]	aluY;
wire	[`DataWidth-1:0]	aluO; //pipe
ALU	alu(aluOp[`ALUOpWidth-1:0], aluX[`DataWidth-1:0], aluY[`DataWidth-1:0], aluO);

reg		[`AddrWidth-1:0]		memReadAddr; // AddrWidth = 32
wire											memReadEnable; // pipe?
wire	[`DataWidth-1:0]		memReadData; // pipe?
reg		[`AddrWidth-1:0]		memWriteAddr; // AddrWidth = 32
wire											memWriteEnable; // pipe?
reg		[2*`DataWidth-1:0]	memWriteData; // pipe?
DataMem mem(
	clk, memReadAddr, memReadEnable, memReadData, 
	memWriteAddr, memWriteEnable, memWriteData[`DataWidth-1:0], 
	pcReadData
);

reg		[2*`StateWidth-1:0]		state; // pipe
Controller control(state[`StateWidth-1:0], regsWriteEnable, memReadEnable, memWriteEnable);

reg		[2*`DataSelectWidth-1:0]	dataSelect; // Control where ALU's output goes
reg		[`Func3Width-1:0]	func3Cache; // need some data support

/* initial begin */
/* 	pcWriteData = 0; */
/* 	pcOp = `PCClear; */
/* end */

reg		[2*`DataWidth-1:0]		regInData;

always @(*)
begin
	if (reset) begin
		aluOp = `ADD;
		aluX = 0;
		aluY = 0;
		pcWriteData = 0;
		pcOp = `PCClear;
		regInData = 0;
		memReadAddr = 0;
		memWriteAddr = 0;
		memWriteData = 0;
		state = `IDLE;
	end
	else if (clk)
	begin
	case (opcode)
		7'b0110011: // FMT R
		begin
			case (func3)
				0: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = func7[5] ? `SUB : `ADD;	// add sub
				1: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `ShiftLeftUnsigned;	// sll
				2: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `LesserThanSigned;	// slt
				3: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `LesserThanUnsigned; // sltu
				4: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `XOR; // xor
				5: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = func7[5] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srl sra
				6: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `OR; // or
				7: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `AND; // and
			endcase
			aluX[2*`DataWidth-1:`DataWidth] = regReadData0;
			aluY[2*`DataWidth-1:`DataWidth] = regReadData1;

			pcOp = `PCAdd4; // WAITING
			dataSelect[2*`DataSelectWidth-1:`DataSelectWidth] = 0;
			state[2*`StateWidth-1:`StateWidth] = `RegsWrite;
		end
		7'b0010011: // FMT I
		begin
			case (func3)
				0: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `ADD;	// addi
				1: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `ShiftLeftUnsigned;	// slli
				2: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `LesserThanSigned;	// slti
				3: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `LesserThanUnsigned; // sltiu
				4: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `XOR; // xori
				5: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = imm[10] ?	`ShiftRightSigned : `ShiftRightUnsigned; // srli srai
				6: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `OR; // ori
				7: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `AND; // andi
			endcase
			aluX[2*`DataWidth-1:`DataWidth] = regReadData0;
			aluY[2*`DataWidth-1:`DataWidth] = imm;

			pcOp = `PCAdd4;
			dataSelect[2*`DataSelectWidth-1:`DataSelectWidth] = 0;
			state[2*`StateWidth-1:`StateWidth] = `RegsWrite;
		end
		7'b0000011: // FMT I lb lh lw lbu lhu
		begin
			aluX[2*`DataWidth-1:`DataWidth] = regReadData0;
			aluY[2*`DataWidth-1:`DataWidth] = imm;
			aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `ADD;

			pcOp = `PCAdd4;
			state[2*`StateWidth-1:`StateWidth] = `MemtoRegs;
		end
		7'b0100011: // FMT S sb sh sw
		begin
			aluX[2*`DataWidth-1:`DataWidth] = regReadData0;
			aluY[2*`DataWidth-1:`DataWidth] = imm;
			aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `ADD;
			
			pcOp = `PCAdd4;
			state[2*`StateWidth-1:`StateWidth]	= `MemWrite;
		end
		7'b1100011: // FMT B
		begin
			case (func3)
				0: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `Equal; // beq
				1: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `NotEqual; // bne
				4: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `LesserThanSigned; // blt
				5: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `GreaterThanOrEqualSigned; // bge
				6: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `LesserThanUnsigned; // bltu
				7: aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `GreaterThanOrEqualUnsigned; // bgeu
			endcase
			aluX[2*`DataWidth-1:`DataWidth] = regReadData0;
			aluY[2*`DataWidth-1:`DataWidth] = regReadData1;

			pcWriteData = imm;
			state[2*`StateWidth-1:`StateWidth] = `PCWrite;
		end
		7'b1101111: // FMT J jal
		begin
			aluX[2*`DataWidth-1:`DataWidth] = pcReadData;
			aluY[2*`DataWidth-1:`DataWidth] = imm;
			aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `ADD;

			pcOp = `PCSetImm;
			regInData[2*`DataWidth-1:`DataWidth] = pcReadData;
			state[2*`StateWidth-1:`StateWidth]	= `RegsWrite;
		end
		7'b1100111: // FMT I jalr
		begin
			aluX[2*`DataWidth-1:`DataWidth] = regReadData0;
			aluY[2*`DataWidth-1:`DataWidth] = imm;
			aluOp[2*`ALUOpWidth-1:`ALUOpWidth] = `ADD;
			
			pcOp = `PCSetImm;
			regInData[2*`DataWidth-1:`DataWidth] = pcReadData;
			state[2*`StateWidth-1:`StateWidth]	=	`RegsWrite;
		end
		7'b0110111: // FMT U lui
		begin
			pcOp = `PCAdd4;
			regInData[2*`DataWidth-1:`DataWidth] = imm;
			state[2*`StateWidth-1:`StateWidth]	=	`RegsWrite;
		end
		7'b0010111: // FMT U auipc
		begin
			aluX[2*`DataWidth-1:`DataWidth] = pcReadData;
			aluY[2*`DataWidth-1:`DataWidth] = imm;
			aluOp[2*`ALUOpWidth-1:`ALUOpWidth]	=	`ADD;

			pcOp = `PCAdd4;
			dataSelect[2*`DataSelectWidth-1:`DataSelectWidth] = 0;
			state[2*`StateWidth-1:`StateWidth]	=	`RegsWrite;
		end
		default: state[2*`StateWidth-1:`StateWidth] = `IDLE;
	endcase
	end

	case (dataSelect[`DataSelectWidth-1:0])
		0:
		begin
			regInData[2*`DataWidth-1:`DataWidth] = aluO;
		end
		1:
		begin
			memReadAddr = aluO;
			case (func3Cache)
				0: regInData[2*`DataWidth-1:`DataWidth]	=	{ { 24{ memReadData[7] } }, memReadData[7:0] }; // lb lbu
				1: regInData[2*`DataWidth-1:`DataWidth] =	{ { 16{ memReadData[15] } }, memReadData[15:0] }; // lh lhu
				2: regInData[2*`DataWidth-1:`DataWidth] =	memReadData; // lw
			endcase
		end
		2:
		begin
			memReadAddr = aluO;
			case (func3Cache)
				0: memWriteData[2*`DataWidth-1:`DataWidth] = { { 24{ regReadData1[7] } }, regReadData1[7:0] }; // sb
				1: memWriteData[2*`DataWidth-1:`DataWidth] = { { 16{ regReadData1[15] } }, regReadData1[15:0] }; // sh
				2: memWriteData[2*`DataWidth-1:`DataWidth] = regReadData1; // sw
			endcase
		end
		3:
		begin
			pcWriteData	=	aluO;
		end
		4:
		begin
			pcOp = aluO ? `PCAddImm : `PCAdd4;
		end
	endcase
end

always @(posedge clk)
begin
	aluX[`DataWidth-1:0] <= aluX[2*`DataWidth-1:`DataWidth];
	aluY[`DataWidth-1:0] <= aluY[2*`DataWidth-1:`DataWidth];
	aluOp[`ALUOpWidth-1:0] <= aluOp[2*`ALUOpWidth-1:`ALUOpWidth];
	state[`StateWidth-1:0] <= state[2*`StateWidth-1:`StateWidth];
	regInData[`DataWidth-1:0] <= regInData[2*`DataWidth-1:`DataWidth];
	memWriteData[`DataWidth-1:0] <= memWriteData[2*`DataWidth-1:`DataWidth];
	memWriteAddr <= memReadAddr;
	func3Cache <= func3;
	dataSelect[`DataSelectWidth-1:0] <= dataSelect[2*`DataSelectWidth-1:`DataSelectWidth];
end

assign regWriteData = regInData[`DataWidth-1:0];
endmodule
