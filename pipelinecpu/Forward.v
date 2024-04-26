`include "Defines.v"
module Forward (
	input		 										clk,
	input		[`RegNumWidth-1:0]	regReadNum0, // RegNumWidth = 5
	input		[`RegNumWidth-1:0]	regReadNum1,
	input		[`RegNumWidth-1:0]	regWriteNum,
	output											forwardA1,
	output											forwardA2,
	output											forwardB1,
	output											forwardB2
);
reg [`RegNumWidth-1:0] regsWriteNum[1:0];

always @(*)
begin
	regsWriteNum[1] = regWriteNum;
end

always @(posedge clk)
begin
	regsWriteNum[0] <= regsWriteNum[1];
end

assign	forwardA1 = regReadNum0 == regsWriteNum[1]; // rs1 = rd wait 1 cycle
assign	forwardA2 = regReadNum0 == regsWriteNum[0]; // rs1 = rd wait 2 cycles
assign	forwardB1 = regReadNum1 == regsWriteNum[1]; // rs2 = rd wait 1 cycle
assign	forwardB2 = regReadNum1 == regsWriteNum[0]; // rs2 = rd wait 2 cycles
endmodule
