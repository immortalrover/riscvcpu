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
always @(posedge disp_clk, negedge rstn) begin
  if (!rstn) rom_addr <= 6'b0;
  else if ( rom_addr == ROM_NUM )	rom_addr <= 6'd0;
	else rom_addr <= rom_addr + 1;
end

reg		[31:0]	pc;
reg		[31:0]	pc_next;
wire	[31:0]	instr_pc = pc >> 2;
reg	pc_write, pc_write_data;
wire	[31:0]	instr_run;
always @(posedge clk, negedge rstn) begin
	if (!rstn) pc_next <= 31'b0;
	else if (pc_write) pc_next <= pc_write_data;
	else pc_next <= pc + 4;
	pc <= pc_next;
end

always@(sw_i) begin
  case(sw_i[2:0])
    3'b000: display_data <= instr; // WAITING
    3'b001: display_data <= instr_pc;
    3'b010: display_data <= pc;
    3'b011: display_data <= instr_run;
		/* 3'b100: display_data <= reg_num; */
		/* 3'b101: display_data <= reg_write_data; */
		/* 3'b110: display_data <= ram_read_data; */
		/* 3'b111: display_data <= ram_addr; */
    default: display_data <= sw_i;
  endcase 
end

dist_mem_gen_0 U_IM0(
  .a(rom_addr),
  .spo(instr)
);

dist_mem_gen_1 U_IM1(
  .a(instr_pc),
  .spo(instr_run)
);

seg7x16 u_seg7x16(
	.clk(clk),
	.rstn(rstn),
	.i_data(display_data),
	.o_seg(disp_seg_o),
	.o_sel(disp_an_o)
);
endmodule
