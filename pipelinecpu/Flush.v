module Flush (
	input			clk, pcWriteEnable,
	output		flush
);

integer i = 0;

assign flush = i > 0;

always @(posedge pcWriteEnable) if (pcWriteEnable) i = 3;

always @(posedge clk) if (flush) i = i - 1;

endmodule
