module flow #(parameter NUM = 0, parameter WIDTH = 8) (
	input												clk, rstn, en,
	input		[WIDTH-1:0]					x, init_x,
	output	[(NUM+1)*WIDTH-1:0]	y
);

reg [(NUM+1)*WIDTH-1:0]	data1;
wire [NUM*WIDTH-1:0]		data2 = data1[NUM*WIDTH-1:0];

/* always @(*) begin */
/* 	data2 <= data1[NUM*WIDTH-1:0]; */
/* end */

always @(posedge clk, negedge rstn) begin
	if (!rstn)	begin
		data1 <= 0;
		data2 <= 0;
	end
	else if (clk) begin
		if (en) data1[WIDTH-1:0] <= x;
		else data1[(WIDTH-1:0] <= init_x;
		if (NUM != 0) data1[(NUM+1)*WIDTH-1:WIDTH] <= data2;
	end
end

assign y = data1;
endmodule
