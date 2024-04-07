module DTypeFlipFlop #(parameter DATAWIDTH = 32) (
	input												clk,
	input												reset,
	input				[DATAWIDTH-1:0]	dataIn,
	output	reg	[DATAWIDTH-1:0]	dataOut
);

always @(posedge clk, posedge reset)
begin
	if (reset)	dataOut	<=	0;
	else				dataOut	<=	dataIn;
end
endmodule
