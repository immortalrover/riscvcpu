`timescale 1ns / 1ps

`include "defines.v"
module xgriscv_pipeline (
	input						clk, rstn,
	input		[15:0]	sw_i,
	output	[7:0]		disp_seg_o,
	output	[7:0]		disp_an_o
);
	
reg		[31:0]	clk_div;
wire					disp_clk = (sw_i[15]) ? clk_div[29] : clk_div[24];
/* wire					disp_clk = clk; // for test */
always @(posedge clk, negedge rstn) begin
	if (!rstn) clk_div <= 0;
	else clk_div <= clk_div + 1'b1;
end    

reg		[31:0]	display_data;
reg		[6:0]		rom_addr;
wire	[31:0]	instr;
parameter ROM_NUM = 23;

// IMWRITING
reg		[31:0]	pc;
reg		[31:0]	pc_next;
wire	[31:0]	instr_pc = pc >> 2;
reg						pc_write;
reg		[31:0]	pc_write_data;
reg						hazard;
wire	[31:0]	instr_disp;
wire	[31:0]	instr_influence;
flow #(0,32)	instr_flow (disp_clk, rstn, ~hazard, instr_disp, 32'h00000013, instr_influence);
wire	[1:0]		pc_write_influence;
flow #(1,1)		pc_write_flow (disp_clk, rstn, 1'b1, pc_write, 1'b0, pc_write_influence);
wire					flush = pc_write || pc_write_influence[1] || pc_write_influence[0];
wire					flush_influence;
flow #(0,1)		flush_flow (disp_clk, rstn, 1'b1, flush, 1'b0, flush_influence);

wire	[6:0]		opcode = instr_influence[6:0];
wire	[6:0]		opcode_influence;
flow #(0,7)		opcode_flow (disp_clk, rstn, ~hazard, opcode, 7'b0110011, opcode_influence);

wire	[2:0]		funct3 = instr_influence[14:12];
wire	[5:0]		funct3_influence;
flow #(1,3)		funct3_flow (disp_clk, rstn, ~hazard, funct3, 3'b0, funct3_influence);

wire	[6:0]		funct7 = instr_influence[31:25];
wire	[6:0]		funct7_influence;
flow #(0,7)		funct7_flow (disp_clk, rstn, ~hazard, funct7, 7'b0, funct7_influence);

wire	[4:0]		rs1 = instr_influence[19:15];
wire	[4:0]		rs1_influence;
flow #(0,5)		rs1_flow (disp_clk, rstn, ~hazard, rs1, 5'b0, rs1_influence);

wire	[4:0]		rs2 = instr_influence[24:20];
wire	[4:0]		rs2_influence;
flow #(0,5)		rs2_flow (disp_clk, rstn, ~hazard, rs2, 5'b0, rs2_influence);

wire	[4:0]		rd = instr_influence[11:7];
wire	[14:0]	rd_influence;
flow #(2,5)		rd_flow (disp_clk, rstn, ~hazard, rd, 5'b0, rd_influence);

reg		[31:0]	imm;
wire	[63:0]	imm_influence;
flow #(1,32)	imm_flow (disp_clk, rstn, 1'b1, imm, 32'b0, imm_influence);
always @(*) begin
	case(opcode) // opcode
		7'b0010011, 7'b1100111, 7'b0000011:	// FMT I
			case(funct3) // funct3
				3'b001, 3'b101: 
					imm = { 20'b0, instr_influence[31:20] };
				default:
					imm = { { 20{ instr_influence[31] } }, instr_influence[31:20] };
			endcase
		7'b0100011:	// FMT S
			imm	= { { 20{ instr_influence[31] } }, instr_influence[31:25], instr_influence[11:7] };
		7'b1100011: // FMT B
			imm = { { 20{ instr_influence[31] } }, instr_influence[7], instr_influence[30:25], instr_influence[11:8], 1'b0 };
		7'b0010111, 7'b0110111: // FMT U
			imm = { instr_influence[31:12], 12'b0 };
		7'b1101111: // FMT J
			imm = { { 13{ instr_influence[31] } }, instr_influence[19:12], instr_influence[20], instr_influence[30:21], 1'b0 };
		default: imm = { 20'b0, instr_influence[31:20] };
	endcase
end

reg					reg_write;
wire				reg_write_influence;
flow #(0,1) reg_write_flow (disp_clk, rstn, 1'b1, reg_write, 1'b0, reg_write_influence);
reg	[31:0]	reg_write_data;
wire [31:0]	reg_write_data_influence;
flow #(0,32) reg_write_data_flow (disp_clk, rstn, 1'b1, reg_write_data, 0, reg_write_data_influence);
reg		[31:0]	R[31:0];
always @(negedge disp_clk) begin
	if (reg_write_influence && rd_influence[14:10] != 0) begin
		R[rd_influence[14:10]] <= reg_write_data_influence;
	end
end

reg		[31:0]	alu_x;
reg		[31:0]	alu_y;
reg		[3:0]		alu_op;
wire	[31:0]	alu_o;
alu U_alu (alu_op, alu_x, alu_y, alu_o);
wire	[31:0]	alu_o_influence;
flow #(0,32)	alu_o_flow (disp_clk, rstn, 1'b1, alu_o, 32'b0, alu_o_influence);
wire	[63:0]	pc_influence;
flow #(1,32)	pc_flow (disp_clk, rstn, 1'b1, pc, 32'b0, pc_influence);

reg	[1:0]		forward_a;
reg	[1:0]		forward_b;

reg [2:0]		state;
wire [2:0] state_influence;
flow #(0,3) state_flow (disp_clk, rstn, 1'b1, state, 3'b0, state_influence);

reg				mem_write;
reg [31:0] mem_addr;
reg [31:0] mem_write_data;
reg [31:0] mem_read_data;

reg [31:0] RAM[0:1000];

always @(*) begin
	if (pc_write) pc_next = pc_write_data;
	else pc_next = pc + 4;

	if (~flush_influence) begin
		if (rs1_influence != 5'b0) begin
			if (rs1_influence == rd_influence[9:5]) forward_a = 2'b10;
			else if (rs1_influence == rd_influence[14:10]) forward_a = 2'b01;
			else forward_a = 2'b00;
		end else forward_a = 2'b00;

		if (rs2_influence != 5'b0) begin
			if (rs2_influence == rd_influence[9:5]) forward_b = 2'b10;
			else if (rs2_influence == rd_influence[14:10]) forward_b = 2'b01;
			else forward_b = 2'b00;
		end else forward_b = 2'b00;
	end

	if (~flush) begin
		case (opcode_influence)
			7'b0110011: // FMT R
			begin
				case (funct3_influence[2:0])
					0: alu_op = funct7_influence[5] ? `SUB : `ADD;	// add sub
					1: alu_op = `SHIFTLEFTUNSIGNED;	// sll
					2: alu_op = `LESSERTHANSIGNED;	// slt
					3: alu_op = `LESSERTHANUNSIGNED; // sltu
					4: alu_op = `XOR; // xor
					5: alu_op = funct7_influence[5] ?	`SHIFTRIGHTSIGNED : `SHIFTRIGHTUNSIGNED; // srl sra
					6: alu_op = `OR; // or
					7: alu_op = `AND; // and
					default: alu_op = funct7_influence[5] ? `SUB : `ADD;
				endcase
				case (forward_a)
					2'b00: alu_x = R[rs1_influence];
					2'b01: alu_x = reg_write_data_influence;
					2'b11,2'b10: alu_x = alu_o_influence;
					default: alu_x = R[rs1_influence];
				endcase
				case (forward_b)
					2'b00: alu_y = R[rs2_influence];
					2'b01: alu_y = reg_write_data_influence;
					2'b11,2'b10: alu_y = alu_o_influence;
					default: alu_y = R[rs2_influence];
				endcase
				state = `REGWRITE;
			end
			7'b0010011: // FMT I
			begin
				case (funct3_influence)
					0: alu_op = `ADD;	// addi
					1: alu_op = `SHIFTLEFTUNSIGNED;	// slli
					2: alu_op = `LESSERTHANSIGNED;	// slti
					3: alu_op = `LESSERTHANUNSIGNED; // sltiu
					4: alu_op = `XOR; // xori
					5: alu_op = imm_influence[10] ?	`SHIFTRIGHTSIGNED : `SHIFTRIGHTUNSIGNED; // srli srai
					6: alu_op = `OR; // ori
					7: alu_op = `AND; // andi
					default: alu_op = `ADD;	
				endcase
				case (forward_a)
					2'b00: alu_x = R[rs1_influence];
					2'b01: alu_x = reg_write_data_influence;
					2'b11,2'b10: alu_x = alu_o_influence;
					default: alu_x = R[rs1_influence];
				endcase
				alu_y = imm_influence[31:0];
				state = `REGWRITE;
			end
			7'b0000011: // FMT I lb lh lw lbu lhu
			begin
				case (forward_a)
					2'b00: alu_x = R[rs1_influence];
					2'b01: alu_x = reg_write_data_influence;
					2'b11,2'b10: alu_x = alu_o_influence;
					default: alu_x = R[rs1_influence];
				endcase
				alu_y = imm_influence[31:0];
				alu_op = `ADD;
				state = `MEMREAD; // Read memory and write register
			end
			7'b0100011: // FMT S sb sh sw
			begin
				case (forward_a)
					2'b00: alu_x = R[rs1_influence];
					2'b01: alu_x = reg_write_data_influence;
					2'b11,2'b10: alu_x = alu_o_influence;
					default: alu_x = R[rs1_influence];
				endcase
				alu_y = imm_influence[31:0];
				alu_op = `ADD;
				state	= `MEMWRITE;
			end
			7'b1100011: // FMT B
			begin
				case (funct3_influence)
					0: alu_op = `EQUAL; // beq
					1: alu_op = `NOTEQUAL; // bne
					4: alu_op = `LESSERTHANSIGNED; // blt
					5: alu_op = `GREATERTHANOREQUALSIGNED; // bge
					6: alu_op = `LESSERTHANUNSIGNED; // bltu
					7: alu_op = `GREATERTHANOREQUALUNSIGNED; // bgeu
					default: alu_op = `EQUAL;
				endcase
				case (forward_a)
					2'b00: alu_x = R[rs1_influence];
					2'b01: alu_x = reg_write_data_influence;
					2'b11,2'b10: alu_x = alu_o_influence;
					default: alu_x = R[rs1_influence];
				endcase
				case (forward_b)
					2'b00: alu_y = R[rs2_influence];
					2'b01: alu_y = reg_write_data_influence;
					2'b11,2'b10: alu_y = alu_o_influence;
					default: alu_y = R[rs2_influence];
				endcase
				state = `PCSELECTWRITE;
			end
			7'b1101111: // FMT J jal
			begin
				alu_x = pc_influence[63:32];
				alu_y = imm_influence[31:0];
				alu_op = `ADD;
				state	= `PCWRITE;
			end
			7'b1100111: // FMT I jalr
			begin
				case (forward_a)
					2'b00: alu_x = R[rs1_influence];
					2'b01: alu_x = reg_write_data_influence;
					2'b11,2'b10: alu_x = alu_o_influence;
					default: alu_x = R[rs1_influence];
				endcase
				alu_y = imm_influence[31:0];
				alu_op = `ADD;
				state	=	`PCWRITE;
			end
			7'b0110111: // FMT U lui
			begin
				alu_x = 32'b0;
				alu_y = 32'b0;
				alu_op = `ADD;
				state	=	`LUIREGWRITE;
			end
			7'b0010111: // FMT U auipc
			begin
				alu_x = pc_influence[63:32];
				alu_y = imm_influence[31:0];
				alu_op	=	`ADD;
				state	=	`REGWRITE;
			end
			default: state = `IDLE;
		endcase
	end
	else begin
		alu_x = 32'b0;
		alu_y = 32'b0;
		alu_op = `ADD;
		state = `IDLE;
	end

	case (state_influence)
		`IDLE:
		begin
			reg_write_data = 0;
			reg_write =	0;
			mem_write =	0;
			mem_write_data =	0;
			pc_write = 0;
		end
		`REGWRITE:
		begin
			reg_write_data = alu_o_influence;
			reg_write	=	1;
			mem_write	=	0;
			mem_write_data =	0;
			pc_write = 0;
		end	
		`MEMREAD:
		begin
			mem_addr	= alu_o_influence;
			reg_write_data = mem_read_data;
			reg_write	=	1;
			mem_write	=	0;
			mem_write_data = 0;
			pc_write = 0;
		end
		`MEMWRITE:
		begin
			mem_addr	=	alu_o_influence;
			mem_write_data = R[rs2_influence]; // forwordB ? data : 
			mem_write	=	1;
			reg_write_data = 0;
			reg_write	=	0;
			pc_write = 0;
		end
		`PCSELECTWRITE:
		begin
			if (alu_o_influence)
			begin
				pc_write = 1;
				pc_write_data	=	pc_influence[63:32] + imm_influence[63:32] - 4;
			end
			reg_write_data = 0;
			reg_write	=	0;
			mem_write	=	0;
			mem_write_data = 0;
		end
		`PCWRITE:
		begin
			pc_write = 1;
			pc_write_data	=	alu_o_influence;
			reg_write_data = pc_influence[63:32];
			reg_write	=	1;
			mem_write	=	0;
			mem_write_data = 0;
		end
		`LUIREGWRITE:
		begin
			reg_write_data = imm_influence[63:32];
			reg_write	= 1;
			mem_write	=	0;
			mem_write_data = 0;
			pc_write = 0;
		end
		default:
		begin
			reg_write_data = 0;
			reg_write =	0;
			mem_write =	0;
			mem_write_data =	0;
			pc_write = 0;
		end
	endcase

	if (mem_write) 
	case (mem_addr[1:0])
		0:
		case (funct3_influence[5:3])
	    0: RAM[mem_addr[11:2]][7:0]	= mem_write_data[7:0]; // sb
	    1: RAM[mem_addr[11:2]][15:0]	= mem_write_data[15:0]; // sh
	    2: RAM[mem_addr[11:2]]				= mem_write_data; // sw
			default: RAM[mem_addr[11:2]][7:0]	= mem_write_data[7:0];
	  endcase
		1:
		case (funct3_influence[5:3])
	    0: RAM[mem_addr[11:2]][15:8] = mem_write_data[7:0]; // sb
	    1: RAM[mem_addr[11:2]][23:8]	= mem_write_data[15:0]; // sh
			default: RAM[mem_addr[11:2]][15:8] = mem_write_data[7:0]; 
	  endcase
		2:
		case (funct3_influence[5:3])
	    0: RAM[mem_addr[11:2]][23:16]= mem_write_data[7:0]; // sb
	    1: RAM[mem_addr[11:2]][31:16]= mem_write_data[15:0]; // sh
			default: RAM[mem_addr[11:2]][23:16]= mem_write_data[7:0];
	  endcase
		3:
		case (funct3_influence[5:3])
	    0: RAM[mem_addr[11:2]][31:24]= mem_write_data[7:0]; // sb
			default: RAM[mem_addr[11:2]][31:24]= mem_write_data[7:0]; 
	  endcase
		default: RAM[mem_addr[11:2]][7:0]	= mem_write_data[7:0];
	endcase

	case (mem_addr[1:0])
		0:
		case (funct3_influence[5:3])
			0: mem_read_data = { { 24{ RAM[mem_addr[11:2]][7] } }, RAM[mem_addr[11:2]][7:0] }; // lb
			1: mem_read_data = { { 16{ RAM[mem_addr[11:2]][15] } }, RAM[mem_addr[11:2]][15:0] }; // lh lhu
			2: mem_read_data = RAM[mem_addr[11:2]]; // lw
			4: mem_read_data = { 24'b0 , RAM[mem_addr[11:2]][7:0] }; // lbu
			5: mem_read_data = { 16'b0 , RAM[mem_addr[11:2]][15:0] }; // lhu
			default: mem_read_data = { { 24{ RAM[mem_addr[11:2]][7] } }, RAM[mem_addr[11:2]][7:0] };
	  endcase
		1:
		case (funct3_influence[5:3])
			0: mem_read_data = { { 24{ RAM[mem_addr[11:2]][15] } }, RAM[mem_addr[11:2]][15:8] }; // lb lbu
			1: mem_read_data = { { 16{ RAM[mem_addr[11:2]][23] } }, RAM[mem_addr[11:2]][23:8] }; // lh lhu
			4: mem_read_data = { 24'b0 , RAM[mem_addr[11:2]][15:8] }; // lbu
			5: mem_read_data = { 16'b0 , RAM[mem_addr[11:2]][23:8] }; // lhu
			default: mem_read_data = { { 24{ RAM[mem_addr[11:2]][15] } }, RAM[mem_addr[11:2]][15:8] };
	  endcase
		2:
		case (funct3_influence[5:3])
			0: mem_read_data = { { 24{ RAM[mem_addr[11:2]][23] } }, RAM[mem_addr[11:2]][23:16] }; // lb lbu
			1: mem_read_data = { { 16{ RAM[mem_addr[11:2]][31] } }, RAM[mem_addr[11:2]][31:16] }; // lh lhu
			4: mem_read_data = { 24'b0 , RAM[mem_addr[11:2]][23:16] }; // lbu
			5: mem_read_data = { 16'b0 , RAM[mem_addr[11:2]][31:16] }; // lhu
			default:  mem_read_data = { { 24{ RAM[mem_addr[11:2]][23] } }, RAM[mem_addr[11:2]][23:16] };
	  endcase
		3:
		case (funct3_influence[5:3])
			0: mem_read_data = { { 24{ RAM[mem_addr[11:2]][31] } }, RAM[mem_addr[11:2]][31:24] }; // lb lbu
			4: mem_read_data = { 24'b0 , RAM[mem_addr[11:2]][31:24] }; // lbu
			default: mem_read_data = { { 24{ RAM[mem_addr[11:2]][31] } }, RAM[mem_addr[11:2]][31:24] };
		endcase
	endcase
end

wire mem_read = state == `MEMREAD;
wire hazard_influence;
flow #(0,1) hazard_flow (disp_clk, rstn, 1'b1, hazard, 1'b0, hazard_influence);
always @(posedge mem_read, negedge rstn, posedge hazard_influence) begin
	if (!rstn) hazard <= 1'b0;
	else if (hazard_influence) hazard <= 1'b0;
	else if (mem_read && (rs1 == rd_influence[4:0]) || (rs2 == rd_influence[4:0])) hazard <= 1'b1;
	else hazard <= 1'b0;
end

always @(posedge disp_clk, negedge rstn) begin
	if (!rstn) begin
		rom_addr <= 7'b0;
		pc <= 32'b0;
	end
	else begin
		if ( rom_addr == ROM_NUM ) rom_addr <= 7'd0;
		else rom_addr <= rom_addr + 1;
		/* if (pc_write) pc_next <= pc_write_data; */
		/* else pc_next <= pc + 4; */
		if (~hazard) pc <= pc_next;
		else pc <= pc;
	end
end


always @(sw_i) begin
  case (sw_i[3:0])
    4'b0000: display_data <= instr; // WAITING
    4'b0001: display_data <= rom_addr; // WAITING
    4'b0010: display_data <= instr_pc;
    4'b0011: display_data <= pc;
    4'b0100: display_data <= instr_disp;
		4'b0101: display_data <= rs1;
		4'b0110: display_data <= R[rs1];
		4'b0111: display_data <= rs2;
		4'b1000: display_data <= R[rs2];
		4'b1001: display_data <= alu_o;
		4'b1010: display_data <= rd;
		4'b1011: display_data <= reg_write_data;
		4'b1100: display_data <= pc_write_data;
		4'b1101: display_data <= mem_write_data;
		4'b1110: display_data <= mem_read_data;
		4'b1111: display_data <= mem_addr;
    default: display_data <= sw_i;
  endcase 
end

dist_mem_gen_0 U_IM0(
  .a(rom_addr),
  .spo(instr)
);

dist_mem_gen_1 U_IM1(
  .a(instr_pc[6:0]),
  .spo(instr_disp)
);

seg7x16 u_seg7x16(
	.clk(clk),
	.rstn(rstn),
	.i_data(display_data),
	.o_seg(disp_seg_o),
	.o_sel(disp_an_o)
);
endmodule
