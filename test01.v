`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/28 15:01:45
// Design Name: 
// Module Name: aaa
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


module test01(
    input clk,
    input rstn,
    input [15:0] sw_i,
    output [7:0] disp_seg_o,
    output [7:0] disp_an_o
);

reg[31:0]clkdiv;

wire CPU_clk;
always @(posedge clk or negedge rstn) begin
if(!rstn) clkdiv <= 0;
else clkdiv <= clkdiv+1'b1;end
assign CPU_clk = (sw_i[15]) ? clkdiv[27] : clkdiv[24];


reg [63:0] display_data;
reg [5:0] led_data_addr;
reg [63:0] led_disp_data;
parameter LED_DATA_NUM = 48;
reg [63:0] LED_DATA [47:0];
initial begin
LED_DATA[0]=64'hFFFFFFFEFEFEFEFE;
LED_DATA[1]=64'hFFFEFEFEFEFEFFFF;
LED_DATA[2]=64'hDEFEFEFEFFFFFFFF;
LED_DATA[3]=64'hCEFEFEFFFFFFFFFF;
LED_DATA[4]=64'hC2FFFFFFFFFFFFFF;
LED_DATA[5]=64'hC1FEFFFFFFFFFFFF;
LED_DATA[6]=64'hF1FCFFFFFFFFFFFF;
LED_DATA[7]=64'hFDF8F7FFFFFFFFFF;
LED_DATA[8]=64'hFFF8F3FFFFFFFFFF;
LED_DATA[9]=64'hFFFBF1FEFFFFFFFF;
LED_DATA[10]=64'hFFFFF9F8FFFFFFFF;
LED_DATA[11]=64'hFFFFFDF8F7FFFFFF;
LED_DATA[12]=64'hFFFFFFF9F1FFFFFF;
LED_DATA[13]=64'hFFFFFFFFF1FCFFFF;
LED_DATA[14]=64'hFFFFFFFFF9F8FFFF;
LED_DATA[15]=64'hFFFFFFFFFFF8F3FF;
LED_DATA[16]=64'hFFFFFFFFFFFBF1FE;
LED_DATA[17]=64'hFFFFFFFFFFFFF9BC;
LED_DATA[18]=64'hFFFFFFFFFFFFBDBC;
LED_DATA[19]=64'hFFFFFFFFBFBFBFBD;
LED_DATA[20]=64'hFFFFBFBFBFBFBFFF;
LED_DATA[21]=64'hFFBFBFBFBFBFFFFF;
LED_DATA[22]=64'hAFBFBFBFFFFFFFFF;
LED_DATA[23]=64'h2737FFFFFFFFFFFF;
LED_DATA[24]=64'h277777FFFFFFFFFF;
LED_DATA[25]=64'h7777777777FFFFFF;
LED_DATA[26]=64'hFFFF7777777777FF;
LED_DATA[27]=64'hFFFFFF7777777777;
LED_DATA[28]=64'hFFFFFFFFFF777771;
LED_DATA[29]=64'hFFFFFFFFFFFF7750;
LED_DATA[30]=64'hFFFFFFFFFFFFFFC8;
LED_DATA[31]=64'hFFFFFFFFFFFFE7CE;
LED_DATA[32]=64'hFFFFFFFFFFFFC7CF;
LED_DATA[33]=64'hFFFFFFFFFFDEC7FF;
LED_DATA[34]=64'hFFFFFFFFF7CEDFFF;
LED_DATA[35]=64'hFFFFFFFFC7CFFFFF;
LED_DATA[36]=64'hFFFFFFFEC7EFFFFF;
LED_DATA[37]=64'hFFFFFFCECFFFFFFF;
LED_DATA[38]=64'hFFFFE7CEFFFFFFFF;
LED_DATA[39]=64'hFFFFC7CFFFFFFFFF;
LED_DATA[40]=64'hFFDEC7FFFFFFFFFF;
LED_DATA[41]=64'hF7CEDFFFFFFFFFFF;
LED_DATA[42]=64'hA7CFFFFFFFFFFFFF;
LED_DATA[43]=64'hA7AFFFFFFFFFFFFF;
LED_DATA[44]=64'hAFBFBFBFFFFFFFFF;
LED_DATA[45]=64'hBFBFBFBFBFFFFFFF;
LED_DATA[46]=64'hFFFFBFBFBFBFBFFF;
LED_DATA[47]=64'hFFFFFFFFBFBFBFBD;
end 

always @ (posedge CPU_clk or negedge rstn) begin
    if (!rstn) begin led_data_addr=6'd0; led_disp_data=64'b1; end
    else if (sw_i[0] == 1'b1) begin
        if (led_data_addr == LED_DATA_NUM) begin led_data_addr = 6'd0; led_disp_data = 64'b1; end
        led_disp_data = LED_DATA[led_data_addr];
        led_data_addr = led_data_addr+1'b1;
    end
    else led_data_addr=led_data_addr;
end


wire[31:0] instr;
reg [31:0] reg_data;
reg [31:0] alu_out_data;
reg [31:0] dmem_data;

parameter INSTR_NUM=9;
reg [7:0] rom_addr;
wire [31:0] immout;
wire is_jump;
always @ (posedge CPU_clk or negedge rstn) begin
    if (!rstn) begin rom_addr = 32'b0; end
    else if (sw_i[14] == 1'b1) begin
        if (!sw_i[1]) begin
            if (is_jump) rom_addr = rom_addr + immout / 4;
            else rom_addr = rom_addr + 1'b1;
        end
        if (rom_addr == INSTR_NUM) begin
            rom_addr = 32'b0;
        end
    end
    else rom_addr = rom_addr;
end

//reg [4:0] rs1;
//reg [4:0] rs2;
//reg [4:0] rd;

reg [31:0] WD;
wire [31:0] rd1;
wire [31:0] rd2;

reg [4:0] reg_addr;
always @ (posedge CPU_clk) begin
    if (sw_i[13] == 1'b1) begin
        reg_addr <= reg_addr + 1;
        if (reg_addr == 5'b11111) reg_data <= 32'hFFFFFFFF;
        else begin
            reg_data <= my_rf.rf[reg_addr];
        end
    end
end

//always@(sw_i) begin
//    if (sw_i[13] == 1'b1) begin
//        rd <= {1'b00, sw_i[10:8]};
//        WD <= sw_i[7:4];
//    end
//end


wire signed [31:0] A,B;
//reg [4:0] ALUOp;
reg [2:0] alu_addr;
wire signed [31:0] C;
wire [31:0] Zero;
//initial begin
//    rd = 5'b00100;
//    WD = 32'h0000FFFF;
//    alu_addr = 3'b000;
//    reg_addr = 5'b00000;
//end

//always@(sw_i) begin
//    if (sw_i[12] == 1) begin
//        A <= {{29{sw_i[10]}}, sw_i[9:7]};
//        B <= {{29{sw_i[6]}}, sw_i[5:3]};
//        if (sw_i[2] == 1) ALUOp <= 5'b00001;
//        else ALUOp <= 5'b00010;
//    end
//end

//always@(sw_i) begin
//    if (sw_i[12] == 1) begin
//        case (sw_i[4:3])
//            2'b00: ALUOp <= 5'b00001;
//            2'b01: ALUOp <= 5'b00010;
//            default: ALUOp <= 5'b00001;
//        endcase
        
//        if (sw_i[2] == 0) begin
//            rs1 <= {2'b00,sw_i[10:8]};
//            rs2 <= {2'b00,sw_i[7:5]};
//        end
//        else begin
//            rd <= {2'b00,sw_i[10:8]};
//            WD <= {{29{sw_i[7]}}, sw_i[7:5]};
//        end
//    end
//end

//always@(posedge clk) begin
//    if (sw_i[12] == 1) begin
//        A <= rd1;
//        B <= rd2;
//    end
//end

always @ (posedge CPU_clk) begin
    if (sw_i[12] == 1) begin
        if (alu_addr == 3'b100) begin
            alu_addr <= 3'b000;
            alu_out_data <= 32'hFFFFFFFF;
        end
        else begin
            case(alu_addr)
            3'b000: alu_out_data <= A;
            3'b001: alu_out_data <= B;
            3'b010: alu_out_data <= C;
            3'b011: alu_out_data <= Zero;
            default: alu_out_data <= 32'hFFFFFFFF;
            endcase
            alu_addr <= alu_addr+ 1'b1;
        end
    end
end

// input [15:0] sw_i,
//    input DMWr,
//    input [5:0] rd,
//    input [31:0] din,
//    input [2:0] DMtype,
//    output reg [31:0] dout;
// wire DMWr;  
wire [6:0] dmrd;  
wire [31:0] dmin;  
wire [2:0] DMtype;  
wire [31:0] dmout;

//assign dmin = {29'b0, sw_i[7:5]};
//assign dmrd = {4'b0, sw_i[10:8]};
//assign DMWr = sw_i[2];

//always@(sw_i) begin
//    if (sw_i[11] == 1) begin
//        case (sw_i[4:3])
//        2'b00: begin DMtype <= 3'b001; end
//        2'b01: begin DMtype <= 3'b010; end
//        2'b11: begin DMtype <= 3'b100; end
//        default: begin DMtype <= 3'b000; end
//        endcase
//    end
//end

reg [6:0] dm_addr;
always @ (posedge CPU_clk) begin
    if (sw_i[11] == 1) begin
        if (dm_addr == 16) begin
            dm_addr = 0;
            dmem_data <= 32'hFFFFFFFF;
        end
        else begin
            dm_addr <= dm_addr+1;
            dmem_data <= {{dm_addr[3:0]}, 20'b0,{my_dm.memory[dm_addr][7:0]}};
        end
    end
end

always @ (sw_i)begin
if (sw_i[0]==0) begin
    case (sw_i[14:11])
        4'b1000:display_data = instr;//ROM
        4'b0100:display_data = reg_data;//RF
        4'b0010:display_data = alu_out_data;// ALU
        4'b0001:display_data = dmem_data; // dm
        default: display_data = instr;
    endcase 
end
else begin display_data = led_disp_data; end
end

wire [6:0] Op = instr[6:0];  
wire [6:0] Funct7 = instr[31:25]; 
wire [2:0] Funct3 = instr[14:12]; 
wire [4:0] rs1 = instr[19:15];  
wire [4:0] rs2 = instr[24:20];  
wire [5:0] rd = instr[11:7]; 
wire [11:0] iimm = instr[31:20];
wire [11:0] simm = {instr[31:25],instr[11:7]};

wire [4:0] iimm_shamt = instr[24:20];
wire [11:0] bimm = {instr[31],instr[7],instr[30:25],instr[11:8]};
wire [11:0] uimm;
wire [19:0] jimm = {instr[31],instr[19:12],instr[20],instr[30:21]};

wire RegWrite; 
wire MemWrite; 
wire [5:0] EXTOp;    
wire [4:0] ALUOp;    
wire ALUSrc;   
wire [1:0] WDSel;  

assign A = rd1;
assign B = (ALUSrc) ? immout : rd2;

assign dmrd = C;
assign dmin = rd2;
always @(posedge clk)
begin
	case(WDSel)
		2'b00: WD<=C;
		2'b01: WD<=dmout;
		2'b10: WD<=rom_addr*4+4;
	endcase
end

seg7x16 u_seg7x16(
    .clk(clk),
    .rstn(rstn),
    .i_data(display_data),
    .disp_mode(sw_i[0]),
    .o_seg(disp_seg_o),
    .o_sel(disp_an_o)
);
dist_mem_im dist(
    .a(rom_addr),
    .spo(instr)
);
RF my_rf(
    .clk(CPU_clk),
    .rst(rstn), 
    .RFWr(RegWrite), 
    .sw_i(sw_i), 
    .A1(rs1), 
    .A2(rs2), 
    .A3(rd), 
    .WD(WD), 
    .RD1(rd1), 
    .RD2(rd2)
);
alu my_alu(
    .A(A), 
    .B(B), 
    .ALUOp(ALUOp), 
    .C(C), 
    .Zero(Zero)
);
DM my_dm(
    .clk(CPU_clk), 
    .rst(rstn), 
    .sw_i(sw_i), 
    .DMWr(MemWrite), 
    .rd(dmrd), 
    .din(dmin), 
    .DMtype(DMtype), 
    .dout(dmout)
);
Ctrl my_ctrl(
    .Op(Op), 
    .Funct7(Funct7), 
    .Funct3(Funct3), 
    .Zero(Zero), 
    .RegWrite(RegWrite), 
    .MemWrite(MemWrite), 
    .EXTOp(EXTOp), 
    .ALUOp(ALUOp), 
    .ALUSrc(ALUSrc), 
    .DMType(DMtype), 
    .WDSel(WDSel),
    .is_jump(is_jump)
);
EXT ext(
    .clk(clk), 
    .iimm_shamt(iimm_shamt), 
    .iimm(iimm), 
    .simm(simm), 
    .bimm(bimm), 
    .uimm(uimm), 
    .jimm(jimm), 
    .EXTOp(EXTOp), 
    .immout(immout)
);
endmodule
