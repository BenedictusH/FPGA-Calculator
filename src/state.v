`timescale 1ns / 1ps

module state(
    input CLK, RST, run,
    input inputed, calc, display,
    output reg [2:0] state
    );

initial begin
    state <= `IDLE;
end
    
always @(posedge CLK)
    begin
        if (RST) state <= `IDLE;
        case (state)
            `IDLE: if (run) state <= `EXECA;
            `EXECA: if (inputed) state <= `EXECB;
            `EXECB: if (calc) state <= `EXECC;
            `EXECC: if (display) state <= `DISPLAY;
            `DISPLAY: ;
            default: state <= `IDLE;
        endcase
    end
endmodule
