`include "Defines.v"
module Execute (
	input														clk, reset, flush, hazard,
	input				[`AddrWidth-1:0]		PC, // AddrWidth = 32
	input				[`DataWidth-1:0]		imm,
	input				[`Func3Width-1:0]		func3, // Func3Width = 3
	input				[`Func7Width-1:0]		func7, // Func7Width = 7
	input				[`OpcodeWidth-1:0]	opcode, // OpcodeWidth = 7
	input				[`RegNumWidth-1:0]	regNum0, regNum1, regWriteNum, // RegNumWidth = 5
	output													pcWriteEnable, 
	output	reg											memReadEnable,
	output			[`DataWidth-1:0]		pcWriteData
);

reg												regInEnable[1:0]; // reg for regInEnable
reg		[`ALUOpWidth-1:0]		aluOp; // ALUOpWidth = 5
reg		[`AddrWidth-1:0]		pcData[2:0];
reg		[`DataWidth-1:0]		aluX, aluY,
													aluOut[1:0], // reg for store alu out data
													immData[1:0],
													regInData[1:0], // reg for regWriteData
													regOutData1[1:0]; // reg for storing rs2 data
reg		[`Func3Width-1:0]		func3Data[1:0]; // reg for storing func3 data
reg		[`RegNumWidth-1:0]	regInNum[2:0];
reg		[`StateWidth-1:0]		state[1:0]; // StateWidth = 4

wire											regWriteEnable;
wire	[1:0]								forwardA, forwardB;
wire	[`DataWidth-1:0]		aluO, data, regReadData0, regReadData1, regWriteData;

always @(*)
begin
	immData[1] = imm;
	func3Data[1] = func3;
	aluOut[1] = aluO;
	pcData[2] = PC;
	regInData[1] = regWriteData;
	regInEnable[1] = regWriteEnable;
	regInNum[2] = regWriteNum;
	memReadEnable = state[1] == `MemReadRegWrite;
	case (forwardB)
		2'b00: regOutData1[1] = regReadData1;
		2'b01: regOutData1[1] = regInData[0];
		2'b11,2'b10: regOutData1[1] = data;
		default: regOutData1[1] = regReadData1;
	endcase
	if (reset) begin
		aluOp = `ADD;
		aluX = 0;
		aluY = 0;
		state[1] = `IDLE;
	end
	else if (clk)
	begin
		if (~flush)
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
					case (forwardA)
						2'b00: aluX = regReadData0;
						2'b01: aluX = regInData[0];
						2'b11,2'b10: aluX = data;
						default: aluX = regReadData0;
					endcase
					case (forwardB)
						2'b00: aluY = regReadData1;
						2'b01: aluY = regInData[0];
						2'b11,2'b10: aluY = data;
						default: aluY = regReadData1;
					endcase
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
					case (forwardA)
						2'b00: aluX = regReadData0;
						2'b01: aluX = regInData[0];
						2'b11,2'b10: aluX = data;
						default: aluX = regReadData0;
					endcase
					aluY = imm;
					state[1] = `RegWrite;
				end
				7'b0000011: // FMT I lb lh lw lbu lhu
				begin
					case (forwardA)
						2'b00: aluX = regReadData0;
						2'b01: aluX = regInData[0];
						2'b11,2'b10: aluX = data;
						default: aluX = regReadData0;
					endcase
					aluY = imm;
					aluOp = `ADD;
					state[1] = `MemReadRegWrite; // Read memory and write register
				end
				7'b0100011: // FMT S sb sh sw
				begin
					case (forwardA)
						2'b00: aluX = regReadData0;
						2'b01: aluX = regInData[0];
						2'b11,2'b10: aluX = data;
						default: aluX = regReadData0;
					endcase
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
					case (forwardA)
						2'b00: aluX = regReadData0;
						2'b01: aluX = regInData[0];
						2'b11,2'b10: aluX = data;
						default: aluX = regReadData0;
					endcase
					case (forwardB)
						2'b00: aluY = regReadData1;
						2'b01: aluY = regInData[0];
						2'b11,2'b10: aluY = data;
						default: aluY = regReadData1;
					endcase
					state[1] = `PCSelectWrite;
				end
				7'b1101111: // FMT J jal
				begin
					aluX = pcData[0];
					aluY = imm;
					aluOp = `ADD;
					state[1]	= `PCWrite;
				end
				7'b1100111: // FMT I jalr
				begin
					case (forwardA)
						2'b00: aluX = regReadData0;
						2'b01: aluX = regInData[0];
						2'b11,2'b10: aluX = data;
						default: aluX = regReadData0;
					endcase
					aluY = imm;
					aluOp = `ADD;
					state[1]	=	`PCWrite;
				end
				7'b0110111: // FMT U lui
				begin
					state[1]	=	`LuiRegWrite;
				end
				7'b0010111: // FMT U auipc
				begin
					aluX = pcData[0];
					aluY = imm;
					aluOp	=	`ADD;
					state[1]	=	`RegWrite;
				end
				default: state[1] = `IDLE;
			endcase
		end
		else begin
			aluX = 0;
			aluY = 0;
			aluOp	= `ADD;
			state[1] = `IDLE;
		end
	end
end

always @(posedge clk)
begin
	aluOut[0] <=  aluOut[1];
	func3Data[0] <=  func3Data[1];
	immData[0] <=  immData[1];
	pcData[0] <=  pcData[1];
	pcData[1] <=  pcData[2];
	regInData[0] <=  regInData[1];
	regInEnable[0] <=  regInEnable[1];
	regInNum[0] <=  regInNum[1];
	regInNum[1] <=  regInNum[2];
	regOutData1[0] <=  regOutData1[1];
	state[0] <=  state[1];
end

ALU	alu(aluOp, aluX, aluY, aluO);

Controller control(clk, reset, forwardB, PC, immData[0], regOutData1[0], aluOut[0], func3Data[0], state[0], pcWriteEnable, regWriteEnable, pcWriteData, regWriteData, data);

Forward Forwarding(clk, reset, flush, regNum0, regNum1, regWriteNum, forwardA, forwardB);

RegsFile RF(PC, clk, reset, regInEnable[0], regInData[0], regNum0, regNum1, regInNum[0], regReadData0, regReadData1);
endmodule
