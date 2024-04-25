`include "Defines.v"
module CPU (
	input											clk,
	input											reset,
	output	[`AddrWidth-1:0]	pcReadData // AddrWidth = 32
);

reg		[`AddrWidth-1:0]	PC[1:0]; // get PC
initial PC[1] = 0;
initial PC[0] = 0;

wire	[`InstrWidth-1:0]	instrData; // InstrWidth = 32
InstrMem	instrMem(.instrAddr(pcReadData), .instrData(instrData));

wire	[`AddrWidth-1:0]	pcWriteData;
wire	[`PCOpWidth-1:0]	pcOp; // PCOpWidth = 2
reg		[`InstrWidth-1:0]	instr[1:0];
Decode ID(clk, reset, instr[0], pcReadData, pcWriteData, pcOp);

always @(*)
begin
	if (clk)
	begin
		case (pcOp)
			`PCClear:		PC[1] =	0;
			`PCAdd4:		PC[1] =	PC[0] + 4;
			`PCAddImm:	PC[1] =	PC[0] + pcWriteData;
			`PCSetImm:	PC[1] =	pcWriteData;
		endcase
	end
	instr[1] = instrData;
end

always @(posedge clk)
begin
	PC[0] <= PC[1];
	instr[0] <= instr[1];
end

assign pcReadData = PC[0];
endmodule
