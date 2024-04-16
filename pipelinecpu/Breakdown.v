`include "Defines.v"
module Breakdown (
	input											clk,
	input											reset,
	input		[`InstrWidth-1:0]	instr, // InstrWidth = 32
	input		[`AddrWidth-1:0]	pcReadData, // AddrWidth = 32
	output	[`DataWidth-1:0]	pcWriteData, // DataWidth = 32
	output	[2:0]							pcOp
);

wire	[6:0]							opcode			= instr[6:0];
wire	[2:0]							func3				= instr[14:12];
wire	[6:0]							func7				= instr[31:25];
wire	[4:0]							regWriteNum	= instr[11:7];
wire	[4:0]							regNum0			= instr[19:15];
wire	[4:0]							regNum1			= instr[24:20];

wire  [`DataWidth-1:0]  regReadData0;
wire  [`DataWidth-1:0]  regReadData1;
wire                    regsWriteEnable;
wire  [`DataWidth-1:0]  regWriteData;
RegsFile RF( 
  clk, reset,regNum0, regNum1, regReadData0, regReadData1, 
  regsWriteEnable, regWriteNum, regWriteData
);

reg [`DataWidth-1:0]	immData;
initial immData = 0;
always @(*)
begin
	case(opcode)
		7'b0010011, 7'b1100111, 7'b0000011:	// FMT I
			case(func3)
				3'b001, 3'b101: 
					immData = { 20'b0, instr[31:20] };
				default:
					immData = { { 20{ instr[31] } }, instr[31:20] };
			endcase
		7'b0100011:	// FMT S
			immData	= { { 20{ instr[31] } }, instr[31:25], instr[11:7] };
		7'b1100011: // FMT B
			immData = { { 20{ instr[31] } }, instr[7], instr[30:25], instr[11:8], 1'b0 };
		7'b0010111, 7'b0110111: // FMT U
			immData = { instr[31:12], 12'b0 };
		7'b1101111: // FMT J
			immData = { { 13{ instr[31] } }, instr[19:12], instr[20], instr[30:21], 1'b0 };
		default:
			immData = 32'bz;
	endcase
end

reg		[2*`DataWidth-1:0]	imm;
reg		[2*`DataWidth-1:0]	regOutData0;
reg		[2*`DataWidth-1:0]	regOutData1;
initial begin
	imm = 0;
	regOutData0 = 0;
	regOutData1	=	0;
end
always @(posedge clk)
begin
	imm [2*`DataWidth-1:`DataWidth]	<= immData;
	imm [`DataWidth-1:0]						<= imm [2*`DataWidth-1:`DataWidth];
	regOutData0 [2*`DataWidth-1:`DataWidth]	<= regReadData0;
	regOutData0	[`DataWidth-1:0]						<= regOutData0 [2*`DataWidth-1:`DataWidth];	
	regOutData1 [2*`DataWidth-1:`DataWidth]	<= regReadData1;
	regOutData1	[`DataWidth-1:0]						<= regOutData1 [2*`DataWidth-1:`DataWidth];	
end

Decode ID(
	clk, reset, opcode, func3, func7, 
	regOutData0 [`DataWidth-1:0], regOutData1[`DataWidth-1:0], regsWriteEnable, regWriteData, imm [`DataWidth-1:0], 
	pcReadData, pcWriteData, pcOp
);
endmodule;
