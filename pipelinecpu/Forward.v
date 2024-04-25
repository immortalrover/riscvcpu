`include "Defines.v"
module Forward (
	input		 										clk,
	input		[`RegNumWidth-1:0]	regReadNum0,
	input		[`RegNumWidth-1:0]	regReadNum1,
	input		[`RegNumWidth-1:0]	regWriteNum,
	output											forwardA1,
	output											forwardA2,
	output											forwardB1,
	output											forwardB2
);
reg [`RegNumWidth-1:0] regsWriteNum[3:0];

always @(*)
begin
	regsWriteNum[3] = regWriteNum;
end

always @(posedge clk)
begin
	regsWriteNum[2] <= regsWriteNum[3];
	regsWriteNum[1] <= regsWriteNum[2];
	regsWriteNum[0] <= regsWriteNum[1];
end

assign	forwardA2 = regReadNum0 == regsWriteNum[1];
assign	forwardA1 = regReadNum0 == regsWriteNum[0];
assign	forwardB2 = regReadNum1 == regsWriteNum[1];
assign	forwardB1 = regReadNum1 == regsWriteNum[0];
endmodule
