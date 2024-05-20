// WIDTH
`define InstrWIDTH										32
`define AddrWIDTH											32
`define DataWIDTH											32
`define OpcodeWIDTH										7
`define Func3WIDTH										3
`define Func7WIDTH										7
`define RegNumWIDTH										5
`define ALUOPWIDTH										4
`define ALUWIDTH											32
`define StateWIDTH										3

// States
`define IDLE													0
`define REGWRITE											1
`define MEMREAD												2
`define MEMWRITE											3
`define PCSELECTWRITE									4
`define	PCWRITE												5
`define LUIREGWRITE										6

// ALU operation
`define ADD														4'h0
`define SUB														4'h1
`define OR														4'h2
`define XOR														4'h3
`define AND														4'h4
`define LESSERTHANUNSIGNED						4'h5
`define LESSERTHANSIGNED							4'h6
`define SHIFTRIGHTUNSIGNED						4'h7
`define SHIFTRIGHTSIGNED							4'h8
`define SHIFTLEFTUNSIGNED							4'h9
`define SHIFTLEFTSIGNED								4'hA
`define GREATERTHANOREQUALUNSIGNED		4'hB
`define GREATERTHANOREQUALSIGNED			4'hC
`define EQUAL													4'hD
`define NOTEQUAL											4'hE
