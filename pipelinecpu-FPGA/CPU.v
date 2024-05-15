`include "Defines.v"
module CPU (
	input						clk, rstn,
  input		[15:0]	sw_i,
  output	[7:0]		disp_seg_o, disp_an_o
);

reg		[2*`AddrWidth-1:0]	PC; // get PC
reg		[`InstrWidth-1:0]		instr;

wire										hazard, flush, pcWriteEnable;
wire	[`AddrWidth-1:0]	pcWriteData;
wire	[`InstrWidth-1:0]	instrReg; // InstrWidth = 32

reg		[31:0]									clkDiv;
reg		[`AddrWidth-1:0]				memWatchAddr;
reg		[`DisplayDataWidth-1:0]	displayData; // DisplayDataWidth = 64
reg		[`RegNumWidth-1:0]			regWatchNum;
wire										CPU_clk = (sw_i[15]) ? clkDiv[27] : clkDiv[24];
wire										reset = ~rstn;
wire	[`DataWidth-1:0]	regWatchData, aluWatchO, memWatchData;
always @(*)
begin
	PC[2*`AddrWidth-1:`AddrWidth] = PC[`AddrWidth-1:0] + 4;

	if (sw_i[0] == 0)
	case (sw_i[14:11])
		4'b0001:displayData = memWatchData;
		4'b0010:displayData = aluWatchO;
		4'b0100:displayData = regWatchData;
		4'b1000:displayData = instrData[`InstrWidth-1:0];
		default:displayData = 0;
	endcase
	if (regWatchNum == 32) regWatchNum = 0;
end

always @(posedge clk)
begin
	if(reset)
	begin
		PC[`AddrWidth-1:0] <= 0;
	end else
	if(~hazard)
	begin
		instr <= instrReg;
		PC[`AddrWidth-1:0] <= pcWriteEnable ? pcWriteData : PC[2*`AddrWidth-1:`AddrWidth];
	end
end

always @(posedge clk or posedge reset) clkDiv <= reset ? 0 : clkDiv + 1; 
always @(posedge CPU_clk or posedge reset)
begin
	regWatchNum <= reset ? 0 : regWatchNum + 1;
	memWatchAddr <= reset ? 0 : memWatchAddr + 4;
end

seg7x16 u_seg7x16(clk, rstn, sw_i[0], displayData, disp_seg_o, disp_an_o);

InstrMem instrMem(PC[`AddrWidth-1:0], instrReg);

Decode ID(clk, reset, flush, PC[`AddrWidth-1:0], instr, hazard, pcWriteEnable, pcWriteData, regWatchNum, memWatchAddr, regWatchData, aluWatchO, memWatchData);

Flush flushing(clk, reset, pcWriteEnable, flush);
endmodule
