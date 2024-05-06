module Flush (
	input			clk, pcWriteEnable,
	output		flush
);

assign flush = i > 0;

integer i = 0;

always @(posedge pcWriteEnable) if (pcWriteEnable) i = 3;

always @(posedge clk) if (flush) i = i - 1;

endmodule
