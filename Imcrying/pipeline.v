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

reg		[63:0]	display_data;
reg		[5:0]		rom_addr;
wire	[31:0]	instr;
reg		[31:0]	reg_data;
reg		[31:0]	alu_disp_data;
reg		[31:0]	dmem_data;
parameter ROM_NUM = 23;
always @(posedge disp_clk or negedge rstn) begin
  if (!rstn) begin 
    rom_addr <= 6'b0;
  end
  else if ( rom_addr == ROM_NUM ) begin 
		rom_addr <= 6'd0;
	end 
	else rom_addr <= rom_addr + 1;
end

always@(sw_i) begin
  case(sw_i[2:0])
    3'b000: display_data <= sw_i; // WAITING
    3'b001: display_data <= rom_addr;
    /* 3'b010: display_data <= pc; */
    3'b011: display_data <= instr;
		/* 3'b100: display_data <= reg_num; */
		/* 3'b101: display_data <= reg_write_data; */
		/* 3'b110: display_data <= ram_read_data; */
		/* 3'b111: display_data <= ram_addr; */
    default: display_data <= sw_i;
  endcase 
end

dist_mem_gen_0 U_IM(
  .a(rom_addr),
  .spo(instr)
);

seg7x16 u_seg7x16(
	.clk(clk),
	.rstn(rstn),
	.i_data(display_data),
	.disp_mode(sw_i[0]),
	.o_seg(disp_seg_o),
	.o_sel(disp_an_o)
);
endmodule
