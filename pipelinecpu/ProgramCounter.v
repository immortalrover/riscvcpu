`include "Defines.v"
module ProgramCounter (
	input											clk,
	input											reset,
	output	[`AddrWidth-1:0]	pcReadData, // AddrWidth = 32
	input											pcWriteEnable, // 1 <= Write
	input		[`AddrWidth-1:0]	pcWriteData,
	input		[2:0]							pcOp
);

reg	[`AddrWidth-1:0] PC;

initial begin
	PC = 0;
end

always @(*)
begin
	if (reset)
	begin
		PC = 0;
	end
end

always @(posedge clk)
begin
	if (pcWriteEnable)
	begin
		case (pcOp)
			`PCAdd4:		PC	<=	PC + 4;
			`PCAddImm:	PC	<=	PC + pcWriteData;
			`PCSetImm:	PC	<=	pcWriteData;
			`PCClear:		PC	<=	0;
		endcase
	end
end
assign pcReadData = PC;
endmodule
