module xgriscv_sc(
  input               clk, 
  input               reset,
  output      [31:0]  pc
  // output      [31:0]  instr,
  // output              memWrite,
  // output      [31:0]  writeData,
  // output      [31:0]  aluX,
  // output      [31:0]  aluY,
  // output      [31:0]  aluO
);
    
wire  [31:0] instr;
imem U_imem(.a(pc), .rd(instr));
wire  [6:0]   opcode           = instr[6:0];
wire  [2:0]   func3            = instr[14:12];
wire  [6:0]   func7            = instr[31:25];
wire  [4:0]   rd               = instr[11:7];
wire  [4:0]   rs1              = instr[19:15];
wire  [4:0]   rs2              = instr[24:20];
wire  [11:0]  immTypeI         = instr[31:20];
wire  [11:0]  immTypeS         = {instr[31:25], instr[11:7]};
wire  [12:0]  immTypeB         = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
wire  [19:0]  immTypeU         = instr[31:12];
wire  [19:0]  immTypeJ         = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
//wire  [11:0] csrIns           = instr[31:20];
//wire  [4:0]  immCsr           = instr[19:15]; 

wire          aluSrc;
wire  [1:0]   dataSel;
wire  [1:0]   wdSel;
wire          regWrite;
wire          memWrite;
wire          pcSrc;
wire          bType;
wire          jal;
wire  [3:0]   aluOp;
wire  [2:0]   extOp;
id U_id (
  .clk(clk), 
  .opcode(opcode), 
  .func7(func7), 
  .func3(func3), 
  .aluSrc(aluSrc),
  .dataSel(dataSel), 
  .wdSel(wdSel),
  .regWrite(regWrite), 
  .memWrite(memWrite),
  .pcSrc(pcSrc), 
  .bType(bType),
  .jal(jal),
  .dmType(dmType), 
  .aluOp(aluOp), 
  .extOp(extOp)
);


wire  [31:0]  immO;
ext U_ext(
  .clk(clk), 
  .immTypeI(immTypeI), 
  .immTypeS(immTypeS), 
  .immTypeB(immTypeB), 
  .immTypeU(immTypeU), 
  .immTypeJ(immTypeJ), 
  .extOp(extOp), 
  .immO(immO)
);

wire  [31:0]  rd1;
wire  [31:0]  rd2;
reg   [31:0]  aluX;
reg   [31:0]  aluY;
wire  [31:0]  aluO; 
always @(*) begin
  case (dataSel)
  0:  aluX <= rd1;
  1:  aluX <= 0;
  2:  aluX <= pc;
  default: aluX <= 0;
  endcase
  case (aluSrc)
  0:  aluY <= rd2;
  1:  aluY <= immO;
  default: aluY <= rd2;
  endcase
end
alu U_alu (.clk(clk),.aluOp(aluOp), .aluX(aluX), .aluY(aluY), .aluO(aluO));

wire  [31:0] readData; 
reg   [31:0] writeData;
always @(*) begin
  case (wdSel)
    0:  writeData <= aluO;
    1:  writeData <= readData;
    2:  writeData <= pc + 4;
    3:  writeData <= rd2;
  endcase
end
dmem U_dmem (
  .clk(clk), 
  .we(memWrite), 
  .a(aluO), 
  .wd(writeData), 
  .pc(pc), 
  .rd(readData)
);

wire  [1:0] pcSel;
assign  pcSel[0] = bType ? aluO[0] : pcSrc;
assign  pcSel[1] = jal | pcSrc;
reg [31:0] PC;
always @(posedge clk) begin
  if (reset) begin
    PC <= 0;
  end
  else
  case(pcSel)
  0:  PC <= pc + 4;
  1:  PC <= pc + immO;
  2:  PC <= aluO;
  3:  PC <= aluO;
  endcase
end
assign pc = PC;

regfile U_regfile(
  .clk(clk),
  .ra1(rs1),
  .ra2(rs2),
  .rd1(rd1),
  .rd2(rd2),

  .we3(regWrite),
  .wa3(rd),
  .wd3(writeData)
);
endmodule