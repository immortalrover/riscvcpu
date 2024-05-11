`include "Defines.v"
module DataMem(
	input													memWriteEnable,
	input				[`AddrWidth-1:0]	PC, // AddrWidth = 32
	input				[`Func3Width-1:0]	func3, // Func3Width = 3
  input				[`AddrWidth-1:0]	memAddr, // AddrWidth = 32
  input				[`DataWidth-1:0]	memWriteData, 
  output reg	[`DataWidth-1:0]	memReadData // DataWidth = 32
);

reg  [`DataWidth-1:0] RAM[1023:0];

always @(*)
begin
	if (memWriteEnable) 
	case (memAddr[1:0])
		0:
		case (func3)
	    0: RAM[memAddr[11:2]][7:0]	= memWriteData[7:0]; // sb
	    1: RAM[memAddr[11:2]][15:0]	= memWriteData[15:0]; // sh
	    2: RAM[memAddr[11:2]]				= memWriteData; // sw
	  endcase
		1:
		case (func3)
	    0: RAM[memAddr[11:2]][15:8] = memWriteData[7:0]; // sb
	    1: RAM[memAddr[11:2]][23:8]	= memWriteData[15:0]; // sh
	  endcase
		2:
		case (func3)
	    0: RAM[memAddr[11:2]][23:16]= memWriteData[7:0]; // sb
	    1: RAM[memAddr[11:2]][31:16]= memWriteData[15:0]; // sh
	  endcase
		3:
		case (func3)
	    0: RAM[memAddr[11:2]][31:24]= memWriteData[7:0]; // sb
	  endcase
	endcase

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
			4: memReadData = { 24'b0 , RAM[memAddr[11:2]][15:8] }; // lbu
			5: memReadData = { 16'b0 , RAM[memAddr[11:2]][23:8] }; // lhu
	  endcase
		2:
		case (func3)
			0: memReadData = { { 24{ RAM[memAddr[11:2]][23] } }, RAM[memAddr[11:2]][23:16] }; // lb lbu
			1: memReadData = { { 16{ RAM[memAddr[11:2]][31] } }, RAM[memAddr[11:2]][31:16] }; // lh lhu
			4: memReadData = { 24'b0 , RAM[memAddr[11:2]][23:16] }; // lbu
			5: memReadData = { 16'b0 , RAM[memAddr[11:2]][31:16] }; // lhu
	  endcase
		3:
		case (func3)
			0: memReadData = { { 24{ RAM[memAddr[11:2]][31] } }, RAM[memAddr[11:2]][31:24] }; // lb lbu
			4: memReadData = { 24'b0 , RAM[memAddr[11:2]][31:24] }; // lbu
	  endcase
	endcase
end

endmodule
