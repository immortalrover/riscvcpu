`include "Defines.v"
module CPU (
	input											clk,
	input											reset,
	output	[`AddrWidth-1:0]	pcReadData // AddrWidth = 32
);

reg		[2*`AddrWidth-1:0]	PC; // get PC
initial PC = 0;
always @(*) if (reset) PC = 0;

wire	[`InstrWidth-1:0]	instrData;
InstrMem	instrMem(.instrAddr(pcReadData), .instrData(instrData));

wire	[`AddrWidth-1:0]	pcWriteData;
wire	[2:0]							pcOp;
reg		[2*`InstrWidth-1:0]	instr;
Decode ID(clk, reset, instr[`InstrWidth-1:0], pcReadData, pcWriteData, pcOp);

always @(*)
begin
	if (clk)
	begin
		case (pcOp)
			`PCClear:		PC[2*`AddrWidth-1:0]	=	0;
			`PCAdd4:		PC[2*`AddrWidth-1:`AddrWidth]	=	PC[`AddrWidth-1:0] + 4;
			`PCAddImm:	PC[2*`AddrWidth-1:`AddrWidth]	=	PC[`AddrWidth-1:0] + pcWriteData;
			`PCSetImm:	PC[2*`AddrWidth-1:`AddrWidth]	=	pcWriteData;
		endcase
	end
end
always @(posedge clk)
begin
	PC[`AddrWidth-1:0] <= PC[2*`AddrWidth-1:`AddrWidth];
	instr[2*`InstrWidth-1:`InstrWidth]	<= instrData;
	instr[`InstrWidth-1:0]							<= instr[2*`InstrWidth-1:`InstrWidth];
end
assign pcReadData = PC[`AddrWidth-1:0];
endmodule
