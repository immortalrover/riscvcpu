module Pipe #(parameter NUM = 0, parameter WIDTH = 8) (
	input												clk, rstn,
	input		[WIDTH-1:0]					x,
	output	[(NUM+1)*WIDTH-1:0]	y
);

reg [(NUM+1)*WIDTH-1:0]	data1;
reg [NUM*WIDTH-1:0]			data2;
genvar i;
generate 
	for (i = 0; i < NUM; i = i + 1) begin
		always @(*) begin
			data2[(i+1)*WIDTH-1:i*WIDTH] = data1[(i+2)*WIDTH-1:(i+1)*WIDTH];
		end
	end
endgenerate


always @(posedge clk, negedge rstn) begin
	if (!rstn)	begin
		data1 <= 0;
		data2 <= 0;
	end
	else if (clk) begin
		data1[(NUM+1)*WIDTH-1:NUM*WIDTH] <= x;
		if (NUM != 0) data1[NUM*WIDTH-1:0] <= data2;
	end
end

assign y = data1;
endmodule
