`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/18 14:47:04
// Design Name: 
// Module Name: sccomp
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SCPU_TOP(
    input clk,
    input rstn,
    input [15:0] sw_i,
    output [7:0] disp_seg_o,
    output [7:0] disp_an_o
    );

    reg[31:0] clkdiv;
    wire Clk_CPU;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) clkdiv <= 0;
        else clkdiv <= clkdiv +1'b1;
    end
    
    assign Clk_CPU=(sw_i[15]) ? clkdiv[27] : clkdiv[25];
    reg[63:0] display_data;
    reg[5:0] led_data_addr;
    reg[63:0] led_disp_data;
    parameter LED_DATA_NUM=19;
    reg[63:0] LED_DATA[47:0];
    initial begin
        LED_DATA[0] = 64'hFFFFFFFEFEFEFEFE;
        LED_DATA[1] = 64'hFFFEFEFEFEFEFFFF;
        LED_DATA[2] = 64'hDEFEFEFEFFFFFFFF;
        LED_DATA[3] = 64'hCEFEFEFFFFFFFFFF;
        LED_DATA[4] = 64'hC2FFFFFFFFFFFFFF;
        LED_DATA[5] = 64'hC1FEFFFFFFFFFFFF;
        LED_DATA[6] = 64'hF1FDFFFFFFFFFFFF;
        LED_DATA[7] = 64'hFDF8F7FFFFFFFFFF;
        LED_DATA[8] = 64'hFFF8F3FFFFFFFFFF;
        LED_DATA[9] = 64'hFFFBF1FEFFFFFFFF;
        LED_DATA[10] =64'hFFFFF9F8FFFFFFFF;
        LED_DATA[11] =64'hFFFFFCF8F7FFFFFF;
        LED_DATA[12] =64'hFFFFFFF9F1FFFFFF;
        LED_DATA[13] =64'hFFFFFFFFF1FCFFFF;
        LED_DATA[14] =64'hFFFFFFFFF9F8FFFF;
        LED_DATA[15] =64'hFFFFFFFFFFF8F3FF;
        LED_DATA[16] =64'hFFFFFFFFFFFBF1FE;
        LED_DATA[17] =64'hFFFFFFFFFFFFF9BC;
        LED_DATA[18] =64'hFFFFFFFFFFFFBDBC;
        LED_DATA[19] =64'hFFFFFFFFBFBFBFBD;
        LED_DATA[20] =64'hFFFFBFBFBFBFBFFF;
        LED_DATA[21] =64'hFFBFBFBFBFBFFFFF;
        LED_DATA[22] =64'hAFBFBFBFFFFFFFFF;
        LED_DATA[23] =64'h2737FFFFFFFFFFFF;
        LED_DATA[24] =64'h27E7E7FFFFFFFFFF;
        LED_DATA[25] =64'hE7E7E7E7E7FFFFFF;
        LED_DATA[26] =64'hFFFFE7E7E7E7E7FF;
        LED_DATA[27] =64'hFFFFFFE7E7E7E7E7;
        LED_DATA[28] =64'hFFFFFFFFFFE7E7E1;
        LED_DATA[29] =64'hFFFFFFFFFFFFE7E0;
        LED_DATA[30] =64'hFFFFFFFFFFFFFF38;
        LED_DATA[31] =64'hFFFFFFFFFFFF773E;
        LED_DATA[32] =64'hFFFFFFFFFFFF373F;
        LED_DATA[33] =64'hFFFFFFFFFFBE37FF;
        LED_DATA[34] =64'hFFFFFFFFF73EBFFF;
        LED_DATA[35] =64'hFFFFFFFF373FFFFF;
        LED_DATA[36] =64'hFFFFFFFE377FFFFF;
        LED_DATA[37] =64'hFFFFFF3E3FFFFFFF;
        LED_DATA[38] =64'hFFFF773EFFFFFFFF;
        LED_DATA[39] =64'hFFFF373FFFFFFFFF;
        LED_DATA[40] =64'hFFBE37FFFFFFFFFF;
        LED_DATA[41] =64'hFF3EBFFFFFFFFFFF;
        LED_DATA[42] =64'h573FFFFFFFFFFFFF;
        LED_DATA[43] =64'h575FFFFFFFFFFFFF;
        LED_DATA[44] =64'h5DFDFDFFFFFFFFFF;
        LED_DATA[45] =64'hDFDFDFDFDFFFFFFF;
        LED_DATA[46] =64'hFFFFDFDFDFDFDFFF;
        LED_DATA[47] =64'hFFFFFFFFDFDFDFDD;
    end
    
    always@(posedge Clk_CPU or negedge rstn) begin
        if(!rstn) begin 
            led_data_addr=6'd0;
            led_disp_data=64'b1;
        end
        else if(sw_i[0]==1'b1) begin
            if(led_data_addr==LED_DATA_NUM)begin led_data_addr=6'd0;led_disp_data=64'b1;end
            led_disp_data=LED_DATA[led_data_addr];
            led_data_addr=led_data_addr+1'b1;
        end
        else led_data_addr=led_data_addr;
    end
    
    reg[5:0] rom_addr;
    parameter ROM_NUM=12;
    always@(posedge Clk_CPU or negedge rstn) begin
        if(!rstn) begin 
            rom_addr = 6'b0;
        end
        else if(sw_i[1]==1'b1) begin
            if(rom_addr==ROM_NUM)begin rom_addr=6'd0;end
            rom_addr = rom_addr + 1;
        end
        else rom_addr=rom_addr;
    end

    wire [31:0] instr;
    reg [31:0]reg_data;
    reg [31:0]alu_disp_data;
    reg [31:0]dmem_data;
    
    dist_mem_im U_IM(
        .a(rom_addr),
        .spo(instr)
    );
    
    always@(sw_i) begin
        if(sw_i[0] == 0) begin
            case(sw_i[14:11])
                4'b1000:display_data=instr;
                4'b0100:display_data=reg_data;
                4'b0010:display_data=alu_disp_data;
                4'b0001:display_data=dmem_data;
                default:display_data=instr;
            endcase 
        end
        else display_data=led_disp_data;
    end
    
    seg7x16 u_seg7x16(
    .clk(clk),
    .rstn(rstn),
    .i_data(display_data),
    .disp_mode(sw_i[0]),
    .o_seg(disp_seg_o),
    .o_sel(disp_an_o)
    );
    
endmodule