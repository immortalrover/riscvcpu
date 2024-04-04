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
			0: PC <= PC + 4;
			1: PC <= PC + pcWriteData;
			2: PC <= pcWriteData;
		endcase
	end
end
assign pcReadData = PC;

endmodule
