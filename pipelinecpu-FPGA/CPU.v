`include "Defines.v"
module CPU (
	input													clk, rstn,
  input		[`SwitchNum-1:0]			switches, // SwitchNum = 16
  output	[`LEDWidth-1:0]				disp_seg_o, disp_an_o	// LEDWidth = 8
);

reg		[`AddrWidth-1:0]	pcData[1:0]; // reg for PC
reg		[`InstrWidth-1:0]	instrData[1:0]; // reg for instr

wire										hazard, flush, pcWriteEnable;
wire	[`AddrWidth-1:0]	pcWriteData;
wire	[`InstrWidth-1:0]	instr; // InstrWidth = 32

wire	reset = ~rstn;
reg		[31:0] clkDiv;
wire	CPU_clk = (switches[15]) ? clkDiv[27] : clkDiv[24];
reg		[`DisplayDataWidth-1:0]	displayData;
reg		[`RegNumWidth-1:0] regWatchNum;
reg		[`AddrWidth-1:0] memWatchAddr;
wire	[`DataWidth-1:0] regWatchData, aluWatchO, memWatchData;
always @(*)
begin
	/* PC = pcData[0] - 16; */
	instrData[1] = instr;
	pcData[1] = pcData[0] + 4;
	if (switches[0] == 0)
	case (switches[14:11])
		4'b1000:displayData = instrData[0];
		4'b0100:displayData = regWatchData;
		4'b0010:displayData = aluWatchO;
		4'b0001:displayData = memWatchData;
		default:displayData = 0;
	endcase
	if (regWatchNum == 32) regWatchNum = 0;
end

always @(posedge clk)
begin
	if(reset)
	begin
		pcData[0] <= 0;
	end else
	if(~hazard)
	begin
		instrData[0] <= instrData[1];
		pcData[0] <= pcWriteEnable ? pcWriteData : pcData[1];
	end
end

always @(posedge clk or posedge reset) clkDiv <= reset ? 0 : clkDiv + 1; 
always @(posedge CPU_clk or posedge reset)
begin
	regWatchNum <= reset ? 0 : regWatchNum + 1;
	memWatchAddr <= reset ? 0 : memWatchAddr + 4;
end

InstrMem instrMem(pcData[0], instr);

seg7x16 u_seg7x16(clk, rstn, switches[0], displayData, disp_seg_o, disp_an_o);

Decode ID(clk, reset, flush, pcData[0], instrData[0], hazard, pcWriteEnable, pcWriteData,
	regWatchNum,
	memWatchAddr,
	regWatchData,
	aluWatchO,
	memWatchData
);

Flush flushing(clk, reset, pcWriteEnable, flush);
endmodule
