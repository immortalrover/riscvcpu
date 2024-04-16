`include "Defines.v"
module CPU (
	input											clk,
	input											reset,
	output	[`AddrWidth-1:0]	pcReadData // AddrWidth = 32
);

reg		[`AddrWidth-1:0] PC; // get PC
initial PC = 0;
always @(*) if (reset) PC = 0;

wire	[`InstrWidth-1:0]	instrData;
InstrMem	instrMem(.instrAddr(pcReadData), .instrData(instrData));

wire	[`AddrWidth-1:0]	pcWriteData;
wire	[2:0]							pcOp;
reg	[2*`InstrWidth-1:0]	instr;
Breakdown breakdown(clk, reset, instr[`InstrWidth-1:0], pcReadData, pcWriteData, pcOp);

always @(posedge clk)
begin
	case (pcOp)
		`PCClear:		PC	<=	0;
		`PCAdd4:		PC	<=	PC + 4;
		`PCAddImm:	PC	<=	PC + pcWriteData;
		`PCSetImm:	PC	<=	pcWriteData;
	endcase
	instr	[2*`InstrWidth-1:`InstrWidth] <= instrData;
	instr	[`InstrWidth-1:0]							<= instr[2*`InstrWidth-1:`InstrWidth];
end

assign pcReadData = PC;
endmodule
