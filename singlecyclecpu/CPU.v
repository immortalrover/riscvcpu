`include "Defines.v"
module CPU (
	input											clk,
	input											reset,
	output	[`AddrWidth-1:0]	PC // AddrWidth = 32
);

reg	[`AddrWidth-1:0] pcData; // get PC
initial pcData = 0;
wire	[`InstrWidth-1:0]	instr; // InstrWidth = 32
wire	[`AddrWidth-1:0]	pcWriteData;
wire	[2:0]							pcOp;
assign PC = pcData;

always @(*) if (reset) pcData = 0;

always @(posedge clk)
begin
	case (pcOp)
		`PCClear:		pcData	<=	0;
		`PCAdd4:		pcData	<=	pcData + 4;
		`PCAddImm:	pcData	<=	pcData + pcWriteData;
		`PCSetImm:	pcData	<=	pcWriteData;
	endcase
end

InstrMem	instrMem(.instrAddr(pcData), .instrData(instr));

Decode ID (clk, reset, instr, pcData, pcWriteData, pcOp);
endmodule
