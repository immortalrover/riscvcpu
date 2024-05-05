`include "Defines.v"
module DataMem(
	input											clk,
  input		[`AddrWidth-1:0]	memAddr, // AddrWidth = 32
  output reg	[`DataWidth-1:0]	memReadData, // DataWidth = 32
	input											memWriteEnable, // 1 => Write
  input		[`DataWidth-1:0]	memWriteData, 
	input		[`AddrWidth-1:0]	PC, // AddrWidth = 32
	input		[2:0]							func3
);

reg  [`DataWidth-1:0] RAM[1023:0];

always @(*)
begin
	if (memWriteEnable) 
	begin
		case (memAddr[1:0])
			0:
			case (func3)
	      0: RAM[memAddr[11:2]][7:0] = memWriteData[7:0]; // sb
	      1: RAM[memAddr[11:2]][15:0]= memWriteData[15:0]; // sh
	      2: RAM[memAddr[11:2]] = memWriteData; // sw
	    endcase
			1:
			case (func3)
	      0: RAM[memAddr[11:2]][15:8] = memWriteData[7:0]; // sb
	      1: RAM[memAddr[11:2]][23:8]= memWriteData[15:0]; // sh
	      /* 2: RAM[memAddr[11:2]] = memWriteData; // sw */
	    endcase
			2:
			case (func3)
	      0: RAM[memAddr[11:2]][23:16] = memWriteData[7:0]; // sb
	      1: RAM[memAddr[11:2]][31:16]= memWriteData[15:0]; // sh
	      /* 2: RAM[memAddr[11:2]] = memWriteData; // sw */
	    endcase
			3:
			case (func3)
	      0: RAM[memAddr[11:2]][31:24] = memWriteData[7:0]; // sb
	      /* 1: RAM[memAddr[11:2]][15:0]= memWriteData[15:0]; // sh */
	      /* 2: RAM[memAddr[11:2]] = memWriteData; // sw */
	    endcase
		endcase
	end
	case (memAddr[1:0])
		0:
		case (func3)
			0: memReadData = { { 24{ RAM[memAddr[11:2]][7] } }, RAM[memAddr[11:2]][7:0] }; // lb
			1: memReadData = { { 16{ RAM[memAddr[11:2]][15] } }, RAM[memAddr[11:2]][15:0] }; // lh lhu
			2: memReadData = RAM[memAddr[11:2]]; // lw
			4: memReadData = { 24'b0 , RAM[memAddr[11:2]][7:0] }; // lbu
			5: memReadData = { 16'b0 , RAM[memAddr[11:2]][15:0] }; // lhu
	  endcase
		1:
		case (func3)
			0: memReadData = { { 24{ RAM[memAddr[11:2]][15] } }, RAM[memAddr[11:2]][15:8] }; // lb lbu
			1: memReadData = { { 16{ RAM[memAddr[11:2]][23] } }, RAM[memAddr[11:2]][23:8] }; // lh lhu
			/* 2: memReadData = RAM[memAddr[11:2]]; // lw */
			4: memReadData = { 24'b0 , RAM[memAddr[11:2]][15:8] }; // lbu
			5: memReadData = { 16'b0 , RAM[memAddr[11:2]][23:8] }; // lhu
	  endcase
		2:
		case (func3)
			0: memReadData = { { 24{ RAM[memAddr[11:2]][23] } }, RAM[memAddr[11:2]][23:16] }; // lb lbu
			1: memReadData = { { 16{ RAM[memAddr[11:2]][31] } }, RAM[memAddr[11:2]][31:16] }; // lh lhu
			/* 2: memReadData = RAM[memAddr[11:2]]; // lw */
			4: memReadData = { 24'b0 , RAM[memAddr[11:2]][23:16] }; // lbu
			5: memReadData = { 16'b0 , RAM[memAddr[11:2]][31:16] }; // lhu
	  endcase
		3:
		case (func3)
			0: memReadData = { { 24{ RAM[memAddr[11:2]][31] } }, RAM[memAddr[11:2]][31:24] }; // lb lbu
			/* 1: memReadData = { { 16{ RAM[memAddr[11:2]][15] } }, RAM[memAddr[11:2]][15:0] }; // lh lhu */
			/* 2: memReadData = RAM[memAddr[11:2]]; // lw */
			4: memReadData = { 24'b0 , RAM[memAddr[11:2]][31:24] }; // lbu
			/* 5: memReadData = { 16'b0 , RAM[memAddr[11:2]][31:16] }; // lhu */
	  endcase
	endcase
end
always @(posedge clk)
begin
	if(memWriteEnable)
	begin
		// DO NOT CHANGE THIS display LINE!!!
		// 不要修改下面这行display语句！！！
		// 对于所有的store指令，都输出位于写入目标地址四字节对齐处的32位数据，不需要修改下面的display语句
		/******************************************************************************************************/
		/* $display("pc = %h: dataaddr = %h, memdata = %h", PC, {memAddr[31:2],2'b00}, RAM[memAddr[11:2]]); */
		/******************************************************************************************************/
	end
end
endmodule
