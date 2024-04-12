`include "Defines.v"
module CPU (
	input											clk,
	input											reset,
	output	[`AddrWidth-1:0]	pcReadData // AddrWidth = 32
);

reg	[`AddrWidth-1:0] PC; // get PC
initial PC = 0;
always @(*) if (reset) PC = 0;

wire	[`InstrWidth-1:0]	instr; // InstrWidth = 32
InstrMem	instrMem(.instrAddr(pcReadData), .instrData(instr));

wire										pcWriteEnable;
wire	[`AddrWidth-1:0]	pcWriteData;
wire	[2:0]							pcOp;
Breakdown breakdown(clk, reset, instr, pcReadData, pcWriteEnable, pcWriteData, pcOp);

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
