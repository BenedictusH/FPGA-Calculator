`timescale 1ns / 1ps
`include "define.v"

module display_tb;

    // Parameters
    parameter M = 24;            // Example `i_val` width
    parameter BCD_WIDTH = 60;    // BCD width (15 digits)

    // Inputs
    reg CLK;
    reg RST;
    reg but0;
    reg [M-1:0] i_val;
    reg error;
    reg [2:0] state;
    reg [3:0] opcode;

    // Outputs
    wire error_led;
    wire [3:0] led_active;
    wire [7:0] led_code;
    wire done;

    // Instantiate the DUT (Device Under Test)
    display uut (
        .CLK(CLK),
        .RST(RST),
        .but0(but0),
        .i_val(i_val),
        .error(error),
        .state(state),
        .opcode(opcode),
        .error_led(error_led),
        .led_active(led_active),
        .led_code(led_code),
        .done(done)
    );

    // Clock Generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK; // 100 MHz clock (10 ns period)
    end

    // Testbench Procedure
    initial begin
        // Initialize inputs
        RST = 1; 
        i_val = 0;
        error = 0;
        but0 = 0;
        state = `IDLE; // Start in IDLE state
        opcode = 4'b0000;

        // Apply reset
        #20;
        RST = 0;

        // Transition to EXECC state with valid inputs
        #10;
        i_val = 24'd123456; // Example input value
        opcode = `SIN;     // Opcode for SUM
        state = `EXECC;    // Transition to EXECC state

        // Wait for the operation to complete
        #5000;

        // Finish simulation
        $finish;
    end

    // Monitor Outputs
    initial begin
        $monitor("Time=%0t | RST=%b | state=%b | opcode=%b | i_val=%h | error=%b | led_active=%b | led_code=%h | done=%b",
                 $time, RST, state, opcode, i_val, error, led_active, led_code, done);
    end

endmodule