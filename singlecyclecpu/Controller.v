`include "Defines.v"
module Controller (
	input				[2:0]		state,
	output	reg					regsWriteEnable,
	output	reg					memReadEnable,
	output	reg					memWriteEnable
);

initial begin
 	regsWriteEnable	=	0;
 	memReadEnable		=	0;
 	memWriteEnable	=	0;
end

always @(*) 
begin
	case (state)
		`IDLE:
		begin
			regsWriteEnable	=	0;
			memReadEnable		=	0;
			memWriteEnable	=	0;
		end
		`RegsWrite:
		begin
			regsWriteEnable =	1;
			memReadEnable		=	0;
			memWriteEnable	=	0;
		end	
		`MemtoRegs:
		begin
			regsWriteEnable =	1;
			memReadEnable		=	1;
			memWriteEnable	=	0;
		end
		`MemWrite:
		begin
			regsWriteEnable =	0;
			memReadEnable		=	0;
			memWriteEnable	=	1;
		end
		`PCWrite:
		begin
			regsWriteEnable =	0;
			memReadEnable		=	0;
			memWriteEnable	=	0;
		end
	endcase
end
endmodule
