`include "Defines.v"
module Hazard (
	input														clk, reset, memReadEnable,
	input				[`RegNumWidth-1:0]	regNum0, regNum1, regWriteNum,
	output	reg											hazard
);

assign hazard = memReadEnable && (regNum0 == regWriteNum || regNum1 == regWriteNum);

/* reg [2:0] number; */

/* always @(*) */
/* begin */
/* 	if (memReadEnable && (regNum0 == regWriteNum || regNum1 == regWriteNum)) number = 3; */
/* 	hazard = number > 0; */
/* end */

/* always @(posedge clk) */
/* begin */
/* 	number <= reset ? 0 : (number > 0) ? number - 1 : 0; */
/* end */
endmodule
