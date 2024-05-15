`include "Defines.v"
module Hazard (
	input														clk, reset, memReadEnable,
	input				[`RegNumWidth-1:0]	regNum0, regNum1, regWriteNum,
	output	reg											hazard
);

integer i = 0;

always @(*)
begin
	i = hazard ? 0 : memReadEnable ? ((regNum0 == regWriteNum) | (regNum1 == regWriteNum)) : 0;
	hazard = i > 0;
end

always @(posedge clk)
begin
	if (reset) i <= 0;
	else i <= i > 0 ? i - 1 : 0;
end

endmodule
