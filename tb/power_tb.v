`timescale 1ns / 1ps
`include "define.v"

module power_tb;

    // Parameters
    parameter N = 16; // Input width
    parameter M = 24; // Output width

    // Testbench signals
    reg CLK, RST;
    reg signed [N-1:0] a, b; // Base and exponent inputs
    reg [2:0] state;
    reg [3:0] opcode;
    wire signed [M-1:0] o_power; // Output power
    wire error;
    wire done;

    // Instantiate the power module
    power #(.N(N), .M(M)) uut (
        .CLK(CLK),
        .RST(RST),
        .a(a),
        .b(b),
        .state(state),
        .opcode(opcode),
        .o_power(o_power),
        .error(error),
        .done(done)
    );

    // Clock generation
    always #5 CLK = ~CLK; // 10 ns clock period

    // Test stimulus
    initial begin
        // Initialize signals
        CLK = 0;
        RST = 1;
        a = 0;
        b = 0;
        state = 0;
        opcode = 0;

        // Reset the DUT
        #10;
        RST = 0;

        // Test Case 1: a = 2, b = 3 (2 ** 3 = 8)
        #10;
        a = 2;
        b = 3;
        state = `EXECB;
        opcode = `POW;
        #500; // Wait for computation
        $display("Test Case 1: a = %d, b = %d, o_power = %d, error = %b, done = %b", a, b, o_power, error, done);
        RST = 1;
        #10; 
        RST = 0;
        // Test Case 2: a = 2, b = -3 (2 ** -3 = 1/8 = 0.125 -> expected 0 for integer math)
        #10;
        a = 2;
        b = -3;
        state = `EXECB;
        opcode = `POW;
        #1000; // Wait for computation
        $display("Test Case 2: a = %d, b = %d, o_power = %d, error = %b, done = %b", a, b, o_power, error, done);
        RST = 1;
        #10; 
        RST = 0;
        // Test Case 3: a = 5, b = 0 (5 ** 0 = 1)
        #10;
        a = 5;
        b = 0;
        state = `EXECB;
        opcode = `POW;
        #100; // Wait for computation
        $display("Test Case 3: a = %d, b = %d, o_power = %d, error = %b, done = %b", a, b, o_power, error, done);
        RST = 1;
        #10; 
        RST = 0;
        // Test Case 4: a = 0, b = 3 (0 ** 3 = 0)
        #10;
        a = 0;
        b = 3;
        state = `EXECB;
        opcode = `POW;
        #100; // Wait for computation
        $display("Test Case 4: a = %d, b = %d, o_power = %d, error = %b, done = %b", a, b, o_power, error, done);
        RST = 1;
        #10; 
        RST = 0;
        // Test Case 5: a = 2, b = 24 (Overflow case, expected error)
        #10;
        a = 2;
        b = 24;
        state = `EXECB;
        opcode = `POW;
        #100; // Wait for computation
        $display("Test Case 5: a = %d, b = %d, o_power = %h, error = %b, done = %b", a, b, o_power, error, done);
        RST = 1;
        #10; 
        RST = 0;
        // Test Case 6: a = 2, b = -9 (Negative exponent too small, expected error)
        #10;
        a = 2;
        b = -9;
        state = `EXECB;
        opcode = `POW;
        #100; // Wait for computation
        $display("Test Case 6: a = %d, b = %d, o_power = %h, error = %b, done = %b", a, b, o_power, error, done);
        RST = 1;
        #10; 
        RST = 0;
        // Test Case 7: a = -3, b = 3 (-3 ** 3 = -27)
        #10;
        a = -3;
        b = 3;
        state = `EXECB;
        opcode = `POW;
        #100; // Wait for computation
        $display("Test Case 7: a = %d, b = %d, o_power = %d, error = %b, done = %b", a, b, o_power, error, done);
        RST = 1;
        #10; 
        RST = 0;
        // Test Case 8: a = 0, b = 0 (0 ** 0 = 1 by convention)
        #10;
        a = 0;
        b = 0;
        state = `EXECB;
        opcode = `POW;
        #100; // Wait for computation
        $display("Test Case 8: a = %d, b = %d, o_power = %d, error = %b, done = %b", a, b, o_power, error, done);

        // End the simulation
        #10;
        $finish;
    end
endmodule