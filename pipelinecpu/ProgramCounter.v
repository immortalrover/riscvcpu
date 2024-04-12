`include "Defines.v"
module ProgramCounter (
	input							clk,
	input							reset,
	output	[31:0]		pcReadData,
	input		[31:0]		pcWriteData,
	input		[2:0]			pcOp
);

reg	[31:0] PC;

initial begin
	PC = 0;
end

always @(posedge clk, posedge reset)
begin
	if (reset)
	begin
		PC <= 0;
	end
	else
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
