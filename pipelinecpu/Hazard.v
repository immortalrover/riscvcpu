module Hazard (
	input											clk,
	input											forward1,
	input	[`OpcodeWidth-1:0]	opcode,
	output										hazard
);
integer i = 0;
assign hazard = i > 0;

always @(posedge forward1)
begin
	if (forward1 && opcode == 7'b0000011) i = 3;
end

always @(posedge clk)
begin
	if (hazard) i = i - 1;
end
endmodule
