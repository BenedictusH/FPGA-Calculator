`define INPUTWIDTH      12
`define OUTPUTWIDTH     24

`define IDLE    3'b000
`define EXECA   3'b001
`define EXECB   3'b010
`define EXECC   3'b011
`define DISPLAY 3'b100

`define SUM     4'h1
`define SUB     4'h2
`define DIV     4'h3
`define MUL     4'h4
`define SQRT    4'h5
`define POW     4'h6
`define LOG     4'h7
`define EXP     4'h8
`define SIN     4'h9
`define COS     4'ha
`define TAN     4'hb
`define NULL    4'hc // extra state for undefined