// Width
`define InstrWidth										32
`define AddrWidth											32
`define DataWidth											32
`define OpcodeWidth										7
`define Func3Width										3
`define Func7Width										7
`define RegNumWidth										5
`define ALUOpWidth										4
`define DataSelectWidth								3
`define StateWidth										3

// PC
`define PCClear												3'h0
`define PCAdd4												3'h1
`define PCAddImm											3'h2
`define PCSetImm											3'h3

// States
`define IDLE													3'h0
`define RegsWrite											3'h1
`define MemtoRegs											3'h2
`define MemWrite											3'h3
`define PCWrite												3'h4

// ALU operation
`define ADD														4'h0
`define SUB														4'h1
`define OR														4'h2
`define XOR														4'h3
`define AND														4'h4
`define LesserThanUnsigned						4'h5
`define LesserThanSigned							4'h6
`define ShiftRightUnsigned						4'h7
`define ShiftRightSigned							4'h8
`define ShiftLeftUnsigned							4'h9
`define ShiftLeftSigned								4'hA
`define GreaterThanOrEqualUnsigned		4'hB
`define GreaterThanOrEqualSigned			4'hC
`define Equal													4'hD
`define NotEqual											4'hE
