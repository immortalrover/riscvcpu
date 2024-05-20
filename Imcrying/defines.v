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
`define RegWrite											1
`define MemReadRegWrite								2
`define MemWrite											3
`define PCSelectWrite									4
`define	PCWrite												5
`define LuiRegWrite										6

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
