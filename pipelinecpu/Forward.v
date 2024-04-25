module Forward (
	input							regReadNum0,
	input							regReadNum1,
	input							regWriteNum,
	output						forwardA,
	output						forwardB
);
reg [`RegNumWidth-1:0] regsWriteNum[3:0];

always @(*)
begin
	regsWriteNum[3] = regWriteNum;
end

endmodule
