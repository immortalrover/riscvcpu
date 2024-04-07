`include "Defines.v"
module ProgramCounter (
	input							clk,
	output	[31:0]		pcReadData,
	input							pcWriteEnable,	// 1 <= Write
	input		[31:0]		pcWriteData,
	input		[2:0]			pcOp
);

reg	[31:0] PC;

initial begin
	PC = 0;
end

always @(posedge clk)
begin
	if (pcWriteEnable)
	begin
		case (pcOp)
			`PCAdd4:		PC	<=	PC + 4;
			`PCAddImm:	PC	<=	PC + pcWriteData;
			`PCSetImm:	PC	<=	pcWriteData;
		endcase
	end
end
assign pcReadData = PC;

endmodule
