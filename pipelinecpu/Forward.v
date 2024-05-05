`include "Defines.v"
module Forward (
	input														clk,
	input				[`RegNumWidth-1:0]	regReadNum0, regReadNum1, regWriteNum, // RegNumWidth = 5

	input														flush,
	output	reg [1:0]								forwardA, forwardB
);

reg [`RegNumWidth-1:0]	regsWriteNum[2:0];
reg											flushing[1:0];

always @(*)
begin
	regsWriteNum[0] = regWriteNum;
	flushing[1] = flush;
	if (~flushing[0])
	begin
		if (regReadNum0 != 0)
		begin
			if (regReadNum0 == regsWriteNum[2]) forwardA = 2'b01;
			else if (regReadNum0 == regsWriteNum[1]) forwardA = 2'b10;
			else forwardA = 2'b00;
		end else forwardA = 2'b00;
		if (regReadNum1 != 0)
		begin
			if (regReadNum1 == regsWriteNum[2]) forwardB = 2'b01;
			else if (regReadNum1 == regsWriteNum[1]) forwardB = 2'b10;
			else forwardB = 2'b00;
		end else forwardB = 2'b00;
	end
	else 
	begin
		forwardA = 2'b00;
		forwardB = 2'b00;
	end
end

always @(posedge clk)
begin
	regsWriteNum[2] <= regsWriteNum[1];
	regsWriteNum[1] <= regsWriteNum[0];
	flushing[0] <= flushing[1];
end
endmodule
