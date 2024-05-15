module Flush (
	input			clk, reset, pcWriteEnable,
	output		flush
);

reg [2:0] number;
assign flush = number > 0;

always @(posedge pcWriteEnable) number = 3;

always @(posedge clk)
begin
	number <= reset ? 0 : flush ? number - 1 : 0;
end
endmodule
