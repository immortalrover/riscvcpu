`include "Defines.v"
module Execute (
	input														clk,
	input														reset,
	input				[`OpcodeWidth-1:0]	opcode, // OpcodeWidth = 7
	input				[`Func3Width-1:0]		func3, // Func3Width = 3
	input				[`Func7Width-1:0]		func7, // Func7Width = 7

	input				[`RegNumWidth-1:0]	regNum0,
	input				[`RegNumWidth-1:0]	regNum1,
	input				[`RegNumWidth-1:0]	regWriteNum,
	input				[`DataWidth-1:0]		imm,

	input				[`AddrWidth-1:0]		PC, // AddrWidth = 32
	output			[`DataWidth-1:0]		pcWriteData,
	output													pcWriteEnable,

	output				reg								hazard,
	input														flush
);

reg		[`AddrWidth-1:0]		pcData[2:0];
reg		[`DataWidth-1:0]		aluOut[1:0]; // reg for store alu out data
reg		[`ALUOpWidth-1:0]		aluOp; // ALUOpWidth = 5
reg		[`DataWidth-1:0]		aluX;
reg		[`DataWidth-1:0]		aluY;
wire	[`DataWidth-1:0]		aluO;
reg		[`StateWidth-1:0]		state[1:0]; // StateWidth = 4
reg		[`DataWidth-1:0]		immData[1:0];
reg		[`Func3Width-1:0]		func3Data[1:0]; // reg for storing func3 data
reg		[`DataWidth-1:0]		regOutData1[1:0]; // reg for storing rs2 data
wire	[`DataWidth-1:0]		data;
wire	[1:0]								forwardA;
wire	[1:0]								forwardB;
wire	[`DataWidth-1:0]		regReadData0;
wire	[`DataWidth-1:0]		regReadData1;
// WB
wire												regWriteEnable;
wire  [`DataWidth-1:0]			regWriteData;
reg		[`DataWidth-1:0]		regInData[1:0]; // reg for regWriteData
reg													regInEnable[1:0]; // reg for regInEnable
reg		[`RegNumWidth-1:0]		regInNum[2:0];

reg													waithazard;

initial hazard = 0;
initial waithazard = 0;
always @(*)
begin
	if (reset) begin
		aluOp = `ADD;
		aluX = 0;
		aluY = 0;
		regInData[1] = 0;
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
						2'b00:
							aluX = regReadData0;
						2'b01:
							aluX = regInData[0];
						2'b11,2'b10:
							aluX = data;
						default:
							aluX = regReadData0;
					endcase

					case (forwardB)
						2'b00:
							aluY = regReadData1;
						2'b01:
							aluY = regInData[0];
						2'b11,2'b10:
							aluY = data;
						default:
							aluY = regReadData1;
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
						2'b00:
							aluX = regReadData0;
						2'b01:
							aluX = regInData[0];
						2'b11,2'b10:
							aluX = data;
						default:
							aluX = regReadData0;
					endcase

					aluY = imm;

					state[1] = `RegWrite;
				end
				7'b0000011: // FMT I lb lh lw lbu lhu
				begin
					case (forwardA)
						2'b00:
							aluX = regReadData0;
						2'b01:
							aluX = regInData[0];
						2'b11,2'b10:
							aluX = data;
						default:
							aluX = regReadData0;
					endcase

					aluY = imm;

					aluOp = `ADD;

					state[1] = `MemReadRegWrite; // Read memory and write register

				end
				7'b0100011: // FMT S sb sh sw
				begin
					case (forwardA)
						2'b00:
							aluX = regReadData0;
						2'b01:
							aluX = regInData[0];
						2'b11,2'b10:
							aluX = data;
						default:
							aluX = regReadData0;
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
						2'b00:
							aluX = regReadData0;
						2'b01:
							aluX = regInData[0];
						2'b11,2'b10:
							aluX = data;
						default:
							aluX = regReadData0;
					endcase

					case (forwardB)
						2'b00:
							aluY = regReadData1;
						2'b01:
							aluY = regInData[0];
						2'b11,2'b10:
							aluY = data;
						default:
							aluY = regReadData1;
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
						2'b00:
							aluX = regReadData0;
						2'b01:
							aluX = regInData[0];
						2'b11,2'b10:
							aluX = data;
						default:
							aluX = regReadData0;
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
	immData[1] = imm;
	func3Data[1] = func3;
	case (forwardB)
		2'b00:
			regOutData1[1] = regReadData1;
		2'b01:
			regOutData1[1] = regInData[0];
		2'b11,2'b10:
			regOutData1[1] = data;
		default:
			regOutData1[1] = regReadData1;
	endcase
	aluOut[1] = aluO;
	pcData[2] = PC;
	regInData[1] = regWriteData;
	regInEnable[1] = regWriteEnable;
	regInNum[2] = regWriteNum;
end

always @(posedge clk)
begin
	if (~hazard) begin
		state[0] <=  state[1];
	end else begin
		state[0] <= 0;
	end
	immData[0] <= immData[1];
	func3Data[0] <= func3Data[1];
	regOutData1[0] <= regOutData1[1];
	aluOut[0] <= aluOut[1];
	pcData[1] <= pcData[2];
	pcData[0] <= pcData[1];
	hazard <= waithazard;
	waithazard <= 0;
	regInData[0] <= regInData[1];
	regInEnable[0] <= regInEnable[1];
	regInNum[1] <= regInNum[2];
	regInNum[0] <= regInNum[1];
end

ALU	alu(aluOp, aluX, aluY, aluO);

Controller control(
	clk, reset,state[0], 
	func3Data[0], immData[0], regOutData1[0], aluOut[0], PC, forwardB, data,
	regWriteEnable, regWriteData, pcWriteEnable, pcWriteData
);

Forward Forwarding(
	clk, regNum0, regNum1, regWriteNum, flush, forwardA, forwardB
);

RegsFile RF( 
  clk, reset, regNum0, regNum1, regReadData0, regReadData1, 
  regInEnable[0], regInNum[0], regInData[0], PC
);
endmodule
