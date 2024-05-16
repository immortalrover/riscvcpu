`include "Defines.v"
module CPU (
	input						clk, rstn,
  input		[15:0]	sw_i,
  output	[7:0]		disp_seg_o, disp_an_o
);

reg		[2*`AddrWidth-1:0]	PC; // get PC
reg		[`InstrWidth-1:0]		instr;
reg											flush;
reg [2:0] number;
reg										pcWriteEnable;
reg	[`AddrWidth-1:0]	pcWriteData;
reg		[31:0]									clkDiv;
reg		[`MemAddrWidth-1:0]				memWatchAddr;
reg		[`DisplayDataWidth-1:0]	displayData; // DisplayDataWidth = 64
reg		[`RegNumWidth-1:0]			regWatchNum;
reg	[`DataWidth-1:0]	memWatchData;
reg		[`OpcodeWidth-1:0]		opcode; /* = instr[6:0]; */ // OpcodeWidth = 7
reg		[`Func3Width-1:0]			func3; /* = instr[14:12]; */ // Func3Width = 3
reg		[`Func7Width-1:0]			func7; /* = instr[31:25]; */ // Func7Width = 7
reg		[`RegNumWidth-1:0]		regWriteNum; /* = instr[11:7]; */ // RegNumWidth = 5
reg		[`RegNumWidth-1:0]		regNum0; /* = instr[19:15]; */
reg		[`RegNumWidth-1:0]		regNum1; /* = instr[24:20]; */
reg		[2*`DataWidth-1:0]		imm;
reg												memReadEnable;
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
reg		[`DataWidth-1:0] regs[31:0];
reg		[1:0]									forwardA, forwardB;
reg		[1:0]									flushing;
reg		[3*`RegNumWidth-1:0]	regsWriteNum;
reg												regWriteEnable;
reg		[`DataWidth-1:0]	regWriteData;
reg		[`DataWidth-1:0]	data; 
reg												memWriteEnable;
reg		[`AddrWidth-1:0]		memAddr;
reg		[`DataWidth-1:0]		memWriteData;
reg		[`DataWidth-1:0]		memReadData;
reg		[`DataWidth-1:0]		RAM[1023:0];
reg		[`DataWidth-1:0]			aluO;

wire	[`DataWidth-1:0]	regReadData0 = (regNum0 != 0) ? regs[regNum0] : 0;
wire	[`DataWidth-1:0]	regReadData1 = (regNum1 != 0) ? regs[regNum1] : 0; 
wire										hazard = memReadEnable && (regNum0 == regWriteNum || regNum1 == regWriteNum);
wire	[`InstrWidth-1:0]	instrReg; // InstrWidth = 32
wire										CPU_clk = (sw_i[15]) ? clkDiv[27] : clkDiv[24];
wire										reset = ~rstn;
wire	[`DataWidth-1:0]	regWatchData = (regWatchNum != 0) ? regs[regWatchNum] : 0;
wire	[`DataWidth-1:0]	aluWatchO = aluO;

always @(*)
begin
	PC[2*`AddrWidth-1:`AddrWidth] = PC[`AddrWidth-1:0] + 4;

	if (sw_i[0] == 0)
	case (sw_i[14:11])
		4'b0001:displayData = memWatchData;
		4'b0010:displayData = aluWatchO;
		4'b0100:displayData = regWatchData;
		4'b1000:displayData = instr;
		default:displayData = 0;
	endcase
	if (regWatchNum == 32) regWatchNum = 0;
end

always @(posedge clk)
begin
	if(reset)
	begin
		PC[`AddrWidth-1:0] <= 0;
	end else
	if(~hazard)
	begin
		instr <= instrReg;
		PC[`AddrWidth-1:0] <= pcWriteEnable ? pcWriteData : PC[2*`AddrWidth-1:`AddrWidth];
	end
end

always @(posedge clk or posedge reset) clkDiv <= reset ? 0 : clkDiv + 1; 
always @(posedge CPU_clk or posedge reset)
begin
	regWatchNum <= reset ? 0 : regWatchNum + 1;
	memWatchAddr <= reset ? 0 : memWatchAddr + 4;
end

always @(*) flush = number[2];

always @(posedge pcWriteEnable) number = 3'b101;

always @(posedge clk)
begin
	if (reset) number <= 0;
	else if (flush) number <= number + 1;
	else number <= 0;
end

always @(*)
begin
	case({instr[6:0]}) // opcode
		7'b0010011, 7'b1100111, 7'b0000011:	// FMT I
			case({instr[14:12]}) // func3
				3'b001, 3'b101: 
					imm[2*`DataWidth-1:`DataWidth] = { 20'b0, instr[31:20] };
				default:
					imm[2*`DataWidth-1:`DataWidth] = { { 20{ instr[31] } }, instr[31:20] };
			endcase
		7'b0100011:	// FMT S
			imm[2*`DataWidth-1:`DataWidth] = { { 20{ instr[31] } }, instr[31:25], instr[11:7] };
		7'b1100011: // FMT B
			imm[2*`DataWidth-1:`DataWidth] = { { 20{ instr[31] } }, instr[7], instr[30:25], instr[11:8], 1'b0 };
		7'b0010111, 7'b0110111: // FMT U
			imm[2*`DataWidth-1:`DataWidth] = { instr[31:12], 12'b0 };
		7'b1101111: // FMT J
			imm[2*`DataWidth-1:`DataWidth] = { { 13{ instr[31] } }, instr[19:12], instr[20], instr[30:21], 1'b0 };
		default:
			imm[2*`DataWidth-1:`DataWidth] = 32'bz;
	endcase
end

always @(posedge clk)
if(~hazard)
begin
	func3 <= reset ? 0 : instr[14:12];
	func7 <= reset ? 0 : instr[31:25];
	imm[`DataWidth-1:0] <= reset ? 0 : imm[2*`DataWidth-1:`DataWidth];
	opcode <= reset ? 0 : instr[6:0];
	regNum0 <= reset ? 0 : instr[19:15];
	regNum1 <= reset ? 0 : instr[24:20];
	regWriteNum <= reset ? 0 : instr[11:7];
end

always @(*)
begin
	memReadEnable																		= state[2*`StateWidth-1:`StateWidth] == `MemReadRegWrite;
	aluOut			[2*`DataWidth-1		:		`DataWidth]		= aluO;
	func3Data		[2*`Func3Width-1	:		`Func3Width]	= func3;
	immData			[2*`DataWidth-1		:		`DataWidth]		= imm[`DataWidth-1:0];
	pcData			[3*`AddrWidth-1		:	2*`AddrWidth]		= PC[`AddrWidth-1:0];
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
					aluY = imm[`DataWidth-1:0];
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
					aluY = imm[`DataWidth-1:0];
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
					aluY = imm[`DataWidth-1:0];
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
					aluY = imm[`DataWidth-1:0];
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
					aluY = imm[`DataWidth-1:0];
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
					aluY = imm[`DataWidth-1:0];
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

always @(negedge clk)
if (regInEnable[0] && regInNum[`RegNumWidth-1:0] != 0)
begin
  regs[regInNum[`RegNumWidth-1:0]] <= regInData[`DataWidth-1:0];
end

always @(*)
begin
	flushing[1] = flush;
	regsWriteNum[`RegNumWidth-1:0] = regWriteNum;
	if (~flushing[0])
	begin
		if (regNum0 != 0)
		begin
			if (regNum0 == regsWriteNum[3*`RegNumWidth-1:2*`RegNumWidth]) forwardA = 2'b01;
			else if (regNum0 == regsWriteNum[2*`RegNumWidth-1:`RegNumWidth]) forwardA = 2'b10;
			else forwardA = 2'b00;
		end else forwardA = 2'b00;
		if (regNum1 != 0)
		begin
			if (regNum1 == regsWriteNum[3*`RegNumWidth-1:2*`RegNumWidth]) forwardB = 2'b01;
			else if (regNum1 == regsWriteNum[2*`RegNumWidth-1:`RegNumWidth]) forwardB = 2'b10;
			else forwardB = 2'b00;
		end else forwardB = 2'b00;
	end
	else 
	begin
		forwardA = 2'b00;
		forwardB = 2'b00;
	end
end

always @(posedge clk)
begin
	flushing[0] <= reset ? 0 : flushing[1];
	regsWriteNum[2*`RegNumWidth-1:`RegNumWidth] <= reset ? 0 : regsWriteNum[`RegNumWidth-1:0];
	regsWriteNum[3*`RegNumWidth-1:2*`RegNumWidth] <= reset ? 0 : regsWriteNum[2*`RegNumWidth-1:`RegNumWidth];
end

always @(*) 
begin
	if (reset) 
	begin
		pcWriteEnable			= 1;
		pcWriteData				= 0;
			memAddr					= 0;
	end
	else 
	case (state[`StateWidth-1:0])
		`IDLE:
		begin
			regWriteData		= 0;
			regWriteEnable	=	0;
			memWriteEnable	=	0;
			memWriteData		=	0;
			pcWriteEnable		= 0;
			memAddr					= 0;
		end
		`RegWrite:
		begin
			regWriteData		= aluOut[`DataWidth-1:0];
			regWriteEnable	=	1;
			memWriteEnable	=	0;
			memWriteData		=	0;
			pcWriteEnable		= 0;
			memAddr					= 0;
		end	
		`MemReadRegWrite:
		begin
			memAddr					= aluOut[`DataWidth-1:0];
			regWriteData		= forwardB[0] ? data : memReadData;
			regWriteEnable	=	1;
			memWriteEnable	=	0;
			memWriteData		=	0;
			pcWriteEnable		= 0;
		end
		`MemWrite:
		begin
			memAddr					=	aluOut[`DataWidth-1:0];
			memWriteData		= regOutData1[`DataWidth-1:0];
			memWriteEnable	=	1;
			regWriteData		= 0;
			regWriteEnable	=	0;
			pcWriteEnable		= 0;
		end
		`PCSelectWrite:
		begin
			if (aluOut[`DataWidth-1:0])
			begin
				pcWriteEnable		= 1;
				pcWriteData			=	pcData[`AddrWidth-1:0] + immData[`DataWidth-1:0] - 4;
			end
			regWriteData		= 0;
			regWriteEnable	=	0;
			memWriteEnable	=	0;
			memWriteData		=	0;
			memAddr					= 0;
		end
		`PCWrite:
		begin
			pcWriteEnable		= 1;
			pcWriteData			=	aluOut[`DataWidth-1:0];
			regWriteData		=	pcData[`AddrWidth-1:0];
			regWriteEnable	=	1;
			memWriteEnable	=	0;
			memWriteData		=	0;
			memAddr					= 0;
		end
		`LuiRegWrite:
		begin
			regWriteData		= immData[`DataWidth-1:0];
			regWriteEnable	= 1;
			memWriteEnable	=	0;
			memWriteData		=	0;
			pcWriteEnable		= 0;
			memAddr					= 0;
		end
	endcase
	case (state[`StateWidth-1:0])
		`MemWrite: data = memWriteData;
		`RegWrite, `MemReadRegWrite, `PCWrite, `LuiRegWrite: data = regWriteData;
	endcase
end

always @(*)
begin
	if (memWriteEnable) 
	case (memAddr[1:0])
		0:
		case (func3Data[`Func3Width-1:0])
	    0: RAM[memAddr[11:2]][7:0]	= memWriteData[7:0]; // sb
	    1: RAM[memAddr[11:2]][15:0]	= memWriteData[15:0]; // sh
	    2: RAM[memAddr[11:2]]				= memWriteData; // sw
	  endcase
		1:
		case (func3Data[`Func3Width-1:0])
	    0: RAM[memAddr[11:2]][15:8] = memWriteData[7:0]; // sb
	    1: RAM[memAddr[11:2]][23:8]	= memWriteData[15:0]; // sh
	  endcase
		2:
		case (func3Data[`Func3Width-1:0])
	    0: RAM[memAddr[11:2]][23:16]= memWriteData[7:0]; // sb
	    1: RAM[memAddr[11:2]][31:16]= memWriteData[15:0]; // sh
	  endcase
		3:
		case (func3Data[`Func3Width-1:0])
	    0: RAM[memAddr[11:2]][31:24]= memWriteData[7:0]; // sb
	  endcase
	endcase

	case (memAddr[1:0])
		0:
		case (func3Data[`Func3Width-1:0])
			0: memReadData = { { 24{ RAM[memAddr[11:2]][7] } }, RAM[memAddr[11:2]][7:0] }; // lb
			1: memReadData = { { 16{ RAM[memAddr[11:2]][15] } }, RAM[memAddr[11:2]][15:0] }; // lh lhu
			2: memReadData = RAM[memAddr[11:2]]; // lw
			4: memReadData = { 24'b0 , RAM[memAddr[11:2]][7:0] }; // lbu
			5: memReadData = { 16'b0 , RAM[memAddr[11:2]][15:0] }; // lhu
	  endcase
		1:
		case (func3Data[`Func3Width-1:0])
			0: memReadData = { { 24{ RAM[memAddr[11:2]][15] } }, RAM[memAddr[11:2]][15:8] }; // lb lbu
			1: memReadData = { { 16{ RAM[memAddr[11:2]][23] } }, RAM[memAddr[11:2]][23:8] }; // lh lhu
			4: memReadData = { 24'b0 , RAM[memAddr[11:2]][15:8] }; // lbu
			5: memReadData = { 16'b0 , RAM[memAddr[11:2]][23:8] }; // lhu
	  endcase
		2:
		case (func3Data[`Func3Width-1:0])
			0: memReadData = { { 24{ RAM[memAddr[11:2]][23] } }, RAM[memAddr[11:2]][23:16] }; // lb lbu
			1: memReadData = { { 16{ RAM[memAddr[11:2]][31] } }, RAM[memAddr[11:2]][31:16] }; // lh lhu
			4: memReadData = { 24'b0 , RAM[memAddr[11:2]][23:16] }; // lbu
			5: memReadData = { 16'b0 , RAM[memAddr[11:2]][31:16] }; // lhu
	  endcase
		3:
		case (func3Data[`Func3Width-1:0])
			0: memReadData = { { 24{ RAM[memAddr[11:2]][31] } }, RAM[memAddr[11:2]][31:24] }; // lb lbu
			4: memReadData = { 24'b0 , RAM[memAddr[11:2]][31:24] }; // lbu
	  endcase
	endcase

	memWatchData = RAM[memWatchAddr[11:2]];
end

always @(*)
case (aluOp)
	`ADD:													aluO = aluX +  aluY;
	`SUB:													aluO = aluX -  aluY;
	`OR:													aluO = aluX |  aluY;
	`XOR:													aluO = aluX ^  aluY;
	`AND:													aluO = aluX &  aluY;
	`LesserThanUnsigned:					aluO = aluX <  aluY;
	`LesserThanSigned:						aluO = $signed(aluX) < $signed(aluY);
	`ShiftRightUnsigned:					aluO = aluX >> (aluY[4:0]);
	`ShiftRightSigned:						aluO = $signed(aluX) >>> (aluY[4:0]);
	`ShiftLeftUnsigned:						aluO = aluX << (aluY[4:0]); 
	`ShiftLeftSigned:							aluO = aluX << (aluY[4:0]);
	`GreaterThanOrEqualUnsigned:	aluO = aluX >= aluY;
	`GreaterThanOrEqualSigned:		aluO = $signed(aluX) >= $signed(aluY);
	`Equal:												aluO = aluX == aluY;
	`NotEqual:										aluO = aluX != aluY;
endcase

InstrMem instrMem(.a(PC[`AddrWidth-1:0]), .spo(instrReg));

seg7x16 u_seg7x16(clk, rstn, sw_i[0], displayData, disp_seg_o, disp_an_o);


endmodule
