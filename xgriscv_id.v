module id (
    input               clk,
    input       [6:0]   opcode,
    input       [6:0]   func7,
    input       [2:0]   func3,
    output              aluSrc,
    output      [1:0]   dataSel,
    output      [1:0]   wdSel,
    output              regWrite, 
    output              memWrite,
    output              pcSrc,
    output              bType,
    output              jal, 
    output      [2:0]   dmType,
    output      [3:0]   aluOp,   
    output      [2:0]   extOp   
);

//  R type
wire rType  = ~opcode[6] & opcode[5] & opcode[4] & ~opcode[3] & ~opcode[2] & opcode[1] & opcode[0];                                         //  0110011
wire add    = rType & ~func3[2] & ~func3[1] & ~func3[0] & ~func7[6] & ~func7[5] & ~func7[4] & ~func7[3] & ~func7[2] & ~func7[1] & ~func7[0];//  add     000 0000000 
wire sub    = rType & ~func3[2] & ~func3[1] & ~func3[0] & ~func7[6] & func7[5] & ~func7[4] & ~func7[3] & ~func7[2] & ~func7[1] & ~func7[0]; //  sub     000 0100000 
wire sll    = rType & ~func3[2] & ~func3[1] & func3[0];                                                                                     //  sll     001 
wire slt    = rType & ~func3[2] & func3[1] & ~func3[0];                                                                                     //  slt     010
wire sltu   = rType & ~func3[2] & func3[1] & func3[0];                                                                                      //  sltu    011
wire xor_   = rType & func3[2] & ~func3[1] & ~func3[0];                                                                                     //  xor     100
wire srl    = rType & func3[2] & ~func3[1] & func3[0] & ~func7[6] & ~func7[5] & ~func7[4] & ~func7[3] & ~func7[2] & ~func7[1] & ~func7[0];  //  srl     101 0000000
wire sra    = rType & func3[2] & ~func3[1] & func3[0] & ~func7[6] & func7[5] & ~func7[4] & ~func7[3] & ~func7[2] & ~func7[1] & ~func7[0];   //  sra     101 0100000
wire or_    = rType & func3[2] & func3[1] & ~func3[0];                                                                                      //  or      110
wire and_   = rType & func3[2] & func3[1] & func3[0];                                                                                       //  and     111

//  S type
wire sType  = ~opcode[6] & opcode[5] & ~opcode[4] & ~opcode[3] & ~opcode[2] & opcode[1] & opcode[0];                                        //  0100011
wire sb     = sType & ~func3[2] & ~func3[1] & ~func3[0];                                                                                    //  sb      000
wire sh     = sType & ~func3[2] & ~func3[1] & func3[0];                                                                                     //  sh      001
wire sw     = sType & ~func3[2] & func3[1] & ~func3[0];                                                                                     //  sw      010

//  B type
assign bType= opcode[6] & opcode[5] & ~opcode[4] & ~opcode[3] & ~opcode[2] & opcode[1] & opcode[0];                                         //  1100011
wire beq    = bType & ~func3[2] & ~func3[1] & ~func3[0];                                                                                    //  beq     000
wire bne    = bType & ~func3[2] & ~func3[1] & func3[0];                                                                                     //  bne     001
wire blt    = bType & func3[2] & ~func3[1] & ~func3[0];                                                                                     //  blt     100
wire bge    = bType & func3[2] & ~func3[1] & func3[0];                                                                                      //  bge     101
wire bltu   = bType & func3[2] & func3[1] & ~func3[0];                                                                                      //  bltu    110
wire bgeu   = bType & func3[2] & func3[1] & func3[0];                                                                                       //  bgeu    111

//  J type 
assign jal  = opcode[6] & opcode[5] & ~opcode[4] & opcode[3] & opcode[2] & opcode[1] & opcode[0];                                           //  1101111 jal
wire jalr   = opcode[6] & opcode[5] & ~opcode[4] & ~opcode[3] & opcode[2] & opcode[1] & opcode[0];                                          //  1100111 jalr

//  I type
wire iType  = ~opcode[6] & ~opcode[5] & ~opcode[3] & ~opcode[2] & opcode[1] & opcode[0];                                                    //  00x0011

wire iType0 = iType & ~opcode[4];                                                                                                           //  0000011
wire lb     = iType0 & ~func3[2] & ~func3[1] & ~func3[0];                                                                                   //  lb      000
wire lh     = iType0 & ~func3[2] & ~func3[1] & func3[0];                                                                                    //  lh      001
wire lw     = iType0 & ~func3[2] & func3[1] & ~func3[0];                                                                                    //  lw      010
wire lbu    = iType0 & func3[2] & ~func3[1] & ~func3[0];                                                                                    //  lbu     100
wire lhu    = iType0 & func3[2] & ~func3[1] & func3[0];                                                                                     //  lhu     101

wire iType1 = iType & opcode[4];                                                                                                            //  0010011
wire addi   = iType1 & ~func3[2] & ~func3[1] & ~func3[0];                                                                                   //  addi    000 
wire slti   = iType1 & ~func3[2] & func3[1] & ~func3[0];                                                                                    //  slti    010
wire sltiu  = iType1 & ~func3[2] & func3[1] & func3[0];                                                                                     //  sltiu   011
wire xori   = iType1 & func3[2] & ~func3[1] & ~func3[0];                                                                                    //  xori    100
wire slli   = iType1 & ~func3[2] & ~func3[1] & func3[0];                                                                                    //  slli    001
wire srli   = iType1 & func3[2] & ~func3[1] & func3[0];                                                                                     //  srli    101
wire srai   = iType1 & func3[2] & ~func3[1] & func3[0];                                                                                     //  srai    101
wire andi   = iType1 & func3[2] & func3[1] & func3[0];                                                                                      //  andi    111

//  U type
wire lui    = ~opcode[6] & opcode[5] & opcode[4] & ~opcode[3] & opcode[2] & opcode[1] & opcode[0];                                          //  0110111 lui
wire auipc  = ~opcode[6] & ~opcode[5] & opcode[4] & ~opcode[3] & opcode[2] & opcode[1] & opcode[0];                                         //  0010111 auipc

assign aluSrc       = iType | sType | lui | auipc | jal | jalr;
assign dataSel[0]   = lui;
assign dataSel[1]   = auipc | jal;
assign wdSel[0]     = iType0 | sType;
assign wdSel[1]     = jal | jalr | sType;
assign regWrite     = rType | iType | jal | jalr | lui | auipc;
assign memWrite     = sType;

assign pcSrc        = jalr;

//assign dmType[2]    = lb | sb;
//assign dmType[1]    = lh | sh;
//assign dmType[0]    = lw | sw;

wire ADD                        = add | addi | auipc | lui | jal | jalr | iType0 | sType;
wire SUB                        = sub;
wire OR                         = or_;
wire XOR                        = xor_ | xori;
wire AND                        = and_ | andi;
wire LesserThanUnsigned         = sltu | sltiu | bltu;
wire LesserThanSigned           = slt | slti | blt;
wire ShiftRightUnsigned         = srl;
wire ShiftRightSigned           = sra;
wire ShiftLeftUnsigned          = sll | slli;
wire GreaterThanOrEqualUnsigned = bgeu;
wire GreaterThanOrEqualSigned   = bge;
wire Equal                      = beq;
wire NotEqual                   = bne;
reg [3:0] ALUOP;
reg [2:0] EXTOP;
always @(*) begin
    if (ADD) begin
        ALUOP <= 4'h0;
    end
    else if (SUB) begin
        ALUOP <= 4'h1;
    end
    else if (OR) begin
        ALUOP <= 4'h2;
    end
    else if (XOR) begin
        ALUOP <= 4'h3;
    end    
    else if (AND) begin
        ALUOP <= 4'h4;
    end    
    else if (LesserThanUnsigned) begin
        ALUOP <= 4'h5;
    end    
    else if (LesserThanSigned) begin
        ALUOP <= 4'h6;
    end    
    else if (ShiftRightUnsigned) begin
        ALUOP <= 4'h7;
    end    
    else if (ShiftRightSigned) begin
        ALUOP <= 4'h8;
    end    
    else if (ShiftLeftUnsigned) begin
        ALUOP <= 4'h9;
    end    
    else if (GreaterThanOrEqualUnsigned) begin
        ALUOP <= 4'hB;
    end    
    else if (GreaterThanOrEqualSigned) begin
        ALUOP <= 4'hC;
    end    
    else if (Equal) begin
        ALUOP <= 4'hD;
    end    
    else if (NotEqual) begin
        ALUOP <= 4'hE;
    end

    if (iType) begin
        if (lh | lhu | slli | srli | srai) begin
            EXTOP   <= 3'b000;
        end
        else begin
            EXTOP   <= 3'b001;
        end
    end
    else if (sType) begin
        EXTOP       <= 3'b010;
    end
    else if (bType) begin
        EXTOP       <= 3'b011;
    end
    else if (lui | auipc) begin
        EXTOP       <= 3'b100;
    end
    else if (jal) begin
        EXTOP       <= 3'b101;
    end
end
assign aluOp        = ALUOP;
assign extOp        = EXTOP;
endmodule
