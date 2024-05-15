`include "Defines.v"
module Forward (
	input														clk, reset, flush,
	input				[`RegNumWidth-1:0]	regReadNum0, regReadNum1, regWriteNum, // RegNumWidth = 5
	output	reg [1:0]								forwardA, forwardB
);

reg	[1:0]									flushing;
reg [3*`RegNumWidth-1:0]	regsWriteNum;

always @(*)
begin
	flushing[1] = flush;
	regsWriteNum[`RegNumWidth-1:0] = regWriteNum;
	if (~flushing[0])
	begin
		if (regReadNum0 != 0)
		begin
			if (regReadNum0 == regsWriteNum[3*`RegNumWidth-1:2*`RegNumWidth]) forwardA = 2'b01;
			else if (regReadNum0 == regsWriteNum[2*`RegNumWidth-1:`RegNumWidth]) forwardA = 2'b10;
			else forwardA = 2'b00;
		end else forwardA = 2'b00;
		if (regReadNum1 != 0)
		begin
			if (regReadNum1 == regsWriteNum[3*`RegNumWidth-1:2*`RegNumWidth]) forwardB = 2'b01;
			else if (regReadNum1 == regsWriteNum[2*`RegNumWidth-1:`RegNumWidth]) forwardB = 2'b10;
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
	flushing[0] <= reset ? 0 : flushing[1];
	regsWriteNum[2*`RegNumWidth-1:`RegNumWidth] <= reset ? 0 : regsWriteNum[`RegNumWidth-1:0];
	regsWriteNum[3*`RegNumWidth-1:2*`RegNumWidth] <= reset ? 0 : regsWriteNum[2*`RegNumWidth-1:`RegNumWidth];
end
endmodule
