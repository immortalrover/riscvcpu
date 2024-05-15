module Flush (
	input				clk, reset, pcWriteEnable,
	output	reg	flush
);

reg [2:0] number;
always @(*) flush = number[2];

always @(posedge pcWriteEnable) number = 3'b101;

always @(posedge clk)
begin
	number <= reset ? 0 : flush ? number + 1 : 0;
end
endmodule
