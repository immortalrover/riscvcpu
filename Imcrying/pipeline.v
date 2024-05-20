`timescale 1ns / 1ps

module xgriscv_pipeline (
	input						clk, rstn,
	input		[15:0]	sw_i,
	output	[7:0]		disp_seg_o,
	output	[7:0]		disp_an_o
);
	
reg		[31:0]	clk_div;
wire					disp_clk = (sw_i[15]) ? clk_div[25] : clk_div[24];
always @(posedge clk, negedge rstn) begin
	if (!rstn) clk_div <= 0;
	else clk_div <= clk_div + 1'b1;
end    

reg		[31:0]	display_data;
reg		[5:0]		rom_addr;
wire	[31:0]	instr;
reg		[31:0]	reg_data;
reg		[31:0]	alu_disp_data;
reg		[31:0]	dmem_data;
parameter ROM_NUM = 23;

// IMWRITING
reg		[31:0]	pc;
reg		[31:0]	pc_next;
wire	[31:0]	instr_pc = pc >> 2;
reg	pc_write, pc_write_data, hazard;
wire	[31:0]	instr_disp;
wire	[31:0]	instr_influence;
flow #(0,32)	instr_flow (disp_clk, rstn, ~hazard, instr_disp, 32'h00000013, instr_influence);
wire	[1:0]		pc_write_influence;
flow #(1,1)		pc_write_flow (disp_clk, rstn, pc_write, pc_write_influence);
wire					flush = pc_write || pc_write_influence[1] || pc_write_influence[0];

wire	[6:0]		opcode = instr_influence[6:0];
wire	[6:0]		opcode_influence;
flow #(0,7)		opcode_flow (disp_clk, rstn, ~hazard, opcode, 7'b0110011, opcode_influence);

wire	[2:0]		funct3 = instr_influence[14:12];
wire	[2:0]		funct3_influence;
flow #(0,3)		funct3_flow (disp_clk, rstn, ~hazard, funct3, 3'b0, funct3_influence);

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
wire	[4:0]		rd_influence;
flow #(0,5)		rd_flow (disp_clk, rstn, ~hazard, rd, 5'b0, rd_influence);

reg		[31:0]	imm;
wire	[31:0]	imm_influence;
flow #(0,32)	imm_flow (disp_clk, rstn, 0, imm, 32'b0, imm_influence);
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
	endcase
end


always @(posedge disp_clk, negedge rstn) begin
	if (!rstn) begin
		rom_addr <= 6'b0;
		pc_next <= 32'b0;
	end
	else begin
		if ( rom_addr == ROM_NUM ) rom_addr <= 6'd0;
		else rom_addr <= rom_addr + 1;
		if (pc_write) pc_next <= pc_write_data;
		else pc_next <= pc + 4;
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
		/* 4'b0110: display_data <= R[rs1]; */
		4'b0111: display_data <= rs2;
		/* 4'b1000: display_data <= R[rs2]; */
    default: display_data <= sw_i;
  endcase 
end

dist_mem_gen_0 U_IM0(
  .a(rom_addr),
  .spo(instr)
);

dist_mem_gen_1 U_IM1(
  .a(instr_pc),
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
