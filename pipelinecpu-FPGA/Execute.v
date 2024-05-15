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
	output	reg											MemReadEnable,
	output			[`DataWidth-1:0]		pcWriteData,

	input [`RegNumWidth-1:0]	regWatchNum,
	input [`AddrWidth-1:0]		memWatchAddr,
	output	[`DataWidth-1:0]	regWatchData, aluWatchO, memWatchData
);

reg		[1:0]									regInEnable; // reg for regInEnable
reg		[`ALUOpWidth-1:0]			aluOp; // ALUOpWidth = 5
reg		[3*`AddrWidth-1:0]		pcData;
reg		[`DataWidth-1:0]			aluX, aluY;
reg		[2*`DataWidth-1:0]		aluOut; // reg for store alu out data
reg		[2*`DataWidth-1:0]		immData;
reg		[2*`DataWidth-1:0]		regInData; // reg for regWriteData
reg		[2*`DataWidth-1:0]		regOutData1; // reg for storing rs2 data
reg		[2*`Func3Width-1:0]		func3Data; // reg for storing func3 data
reg		[3*`RegNumWidth-1:0]	regInNum;
reg		[2*`StateWidth-1:0]		state; // StateWidth = 4

wire												regWriteEnable;
wire	[1:0]									forwardA, forwardB;
wire	[`DataWidth-1:0]			aluO, data, regReadData0, regReadData1, regWriteData;

assign aluWatchO = aluO;

always @(*)
begin
	MemReadEnable																		= state[2*`StateWidth-1:`StateWidth] == `MemReadRegWrite;
	aluOut			[2*`DataWidth-1		:		`DataWidth]		= aluO;
	func3Data		[2*`Func3Width-1	:		`Func3Width]	= func3;
	immData			[2*`DataWidth-1		:		`DataWidth]		= imm;
	pcData			[3*`AddrWidth-1		:	2*`AddrWidth]		= PC;
	regInData		[2*`DataWidth-1		:		`DataWidth]		= regWriteData;
	regInEnable	[1]																	= regWriteEnable;
	regInNum		[3*`RegNumWidth-1	:	2*`RegNumWidth] = regWriteNum;
	case (forwardB)
		2'b00:				regOutData1[2*`DataWidth-1:`DataWidth] = regReadData1;
		2'b01:				regOutData1[2*`DataWidth-1:`DataWidth] = regInData[`DataWidth-1:0];
		2'b11,2'b10:	regOutData1[2*`DataWidth-1:`DataWidth] = data;
		default:			regOutData1[2*`DataWidth-1:`DataWidth] = regReadData1;
	endcase
	if (reset) begin
		aluOp = `ADD;
		aluX = 0;
		aluY = 0;
		state[2*`StateWidth-1:`StateWidth] = `IDLE;
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
						2'b01: aluX = regInData[`DataWidth-1:0];
						2'b11,2'b10: aluX = data;
						default: aluX = regReadData0;
					endcase
					case (forwardB)
						2'b00: aluY = regReadData1;
						2'b01: aluY = regInData[`DataWidth-1:0];
						2'b11,2'b10: aluY = data;
						default: aluY = regReadData1;
					endcase
					state[2*`StateWidth-1:`StateWidth] = `RegWrite;
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
						2'b01: aluX = regInData[`DataWidth-1:0];
						2'b11,2'b10: aluX = data;
						default: aluX = regReadData0;
					endcase
					aluY = imm;
					state[2*`StateWidth-1:`StateWidth] = `RegWrite;
				end
				7'b0000011: // FMT I lb lh lw lbu lhu
				begin
					case (forwardA)
						2'b00: aluX = regReadData0;
						2'b01: aluX = regInData[`DataWidth-1:0];
						2'b11,2'b10: aluX = data;
						default: aluX = regReadData0;
					endcase
					aluY = imm;
					aluOp = `ADD;
					state[2*`StateWidth-1:`StateWidth] = `MemReadRegWrite; // Read memory and write register
				end
				7'b0100011: // FMT S sb sh sw
				begin
					case (forwardA)
						2'b00: aluX = regReadData0;
						2'b01: aluX = regInData[`DataWidth-1:0];
						2'b11,2'b10: aluX = data;
						default: aluX = regReadData0;
					endcase
					aluY = imm;
					aluOp = `ADD;
					state[2*`StateWidth-1:`StateWidth]	= `MemWrite;
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
						2'b01: aluX = regInData[`DataWidth-1:0];
						2'b11,2'b10: aluX = data;
						default: aluX = regReadData0;
					endcase
					case (forwardB)
						2'b00: aluY = regReadData1;
						2'b01: aluY = regInData[`DataWidth-1:0];
						2'b11,2'b10: aluY = data;
						default: aluY = regReadData1;
					endcase
					state[2*`StateWidth-1:`StateWidth] = `PCSelectWrite;
				end
				7'b1101111: // FMT J jal
				begin
					aluX = pcData[`AddrWidth-1:0];
					aluY = imm;
					aluOp = `ADD;
					state[2*`StateWidth-1:`StateWidth]	= `PCWrite;
				end
				7'b1100111: // FMT I jalr
				begin
					case (forwardA)
						2'b00: aluX = regReadData0;
						2'b01: aluX = regInData[`DataWidth-1:0];
						2'b11,2'b10: aluX = data;
						default: aluX = regReadData0;
					endcase
					aluY = imm;
					aluOp = `ADD;
					state[2*`StateWidth-1:`StateWidth]	=	`PCWrite;
				end
				7'b0110111: // FMT U lui
				begin
					state[2*`StateWidth-1:`StateWidth]	=	`LuiRegWrite;
				end
				7'b0010111: // FMT U auipc
				begin
					aluX = pcData[`AddrWidth-1:0];
					aluY = imm;
					aluOp	=	`ADD;
					state[2*`StateWidth-1:`StateWidth]	=	`RegWrite;
				end
				default: state[2*`StateWidth-1:`StateWidth] = `IDLE;
			endcase
		end
		else begin
			aluX = 0;
			aluY = 0;
			aluOp	= `ADD;
			state[2*`StateWidth-1:`StateWidth] = `IDLE;
		end
	end
end

always @(posedge clk)
begin
	aluOut			[`DataWidth-1			:0]						<= reset ? 0 : aluOut			[2*`DataWidth-1:`DataWidth];
	func3Data		[`Func3Width-1		:0]						<= reset ? 0 : func3Data	[2*`Func3Width-1:`Func3Width];
	immData			[`DataWidth-1			:0]						<= reset ? 0 : immData		[2*`DataWidth-1:`DataWidth];
	pcData			[2*`AddrWidth-1		:`AddrWidth]	<= reset ? 0 : pcData			[3*`AddrWidth-1:2*`AddrWidth];
	pcData			[`AddrWidth-1			:0]						<= reset ? 0 : pcData			[2*`AddrWidth-1:`AddrWidth];
	regInData		[`DataWidth-1			:0]						<= reset ? 0 : regInData	[2*`DataWidth-1:`DataWidth];
	regInEnable	[0]															<= reset ? 0 : regInEnable[1];
	regInNum		[2*`RegNumWidth-1	:`RegNumWidth]<= reset ? 0 : regInNum		[3*`RegNumWidth-1:2*`RegNumWidth];
	regInNum		[`RegNumWidth-1		:0]						<= reset ? 0 : regInNum		[2*`RegNumWidth-1:`RegNumWidth];
	regOutData1	[`DataWidth-1			:0]						<= reset ? 0 : regOutData1[2*`DataWidth-1:`DataWidth];
	state				[`StateWidth-1		:0]						<= reset ? 0 : hazard ? 0 : state[2*`StateWidth-1:`StateWidth];
end

ALU	alu(aluOp, aluX, aluY, aluO);

Controller control(clk, reset, forwardB, PC, immData[`DataWidth-1:0], regOutData1[`DataWidth-1:0], aluOut[`DataWidth-1:0], func3Data[`Func3Width-1:0], state[`StateWidth-1:0], pcWriteEnable, regWriteEnable, pcWriteData, regWriteData, data, memWatchAddr, memWatchData);

Forward Forwarding(clk, reset, flush, regNum0, regNum1, regWriteNum, forwardA, forwardB);

RegsFile RF(PC, clk, reset, regInEnable[0], regInData[`DataWidth-1:0], regNum0, regNum1, regInNum[`RegNumWidth-1:0], regReadData0, regReadData1, regWatchNum, regWatchData);
endmodule
