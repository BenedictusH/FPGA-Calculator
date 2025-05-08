`include "define.v"
`timescale 1ns / 1ps

module arithmetic_tb;

    // Testbench Signals
    reg CLK, RST;
    reg [`INPUTWIDTH-1:0] a, b;
    reg [2:0] state;
    reg [3:0] opcode;
    wire [`OUTPUTWIDTH-1:0] result;
    wire done;

    // Signals for square root component
    reg [`INPUTWIDTH-1:0] a_sqrt;

    // Instantiate the DUT (Device Under Test)
    arithmetic uut (
        .CLK(CLK),
        .RST(RST),
        .a(a),
        .b(b),
        .state(state),
        .opcode(opcode),
        .result(result),
        .done(done)
    );

    // Clock Generation
    initial CLK = 0;
    always #5 CLK = ~CLK; // Clock period = 10ns

    // Test Procedure
    initial begin
        // Initialize inputs
        RST = 1; // Reset the DUT
        a = 0; b = 0; state = 0; opcode = 1'bz;
        #20 RST = 0; // Deassert reset

        $display("Starting test...");

        // Test SUM operation
        state = `EXECB; opcode = `SUM; a = 32'd15; b = 32'd10;
        #10; // Wait for computation
        $display("SUM: a = %d, b = %d, result = %d, done = %b", a, b, result, done);

        // Test SUB operation
        state = `EXECB; opcode = `SUB; a = 32'd25; b = 32'd10;
        #10; // Wait for computation
        $display("SUB: a = %d, b = %d, result = %d, done = %b", a, b, result, done);

        // Test DIV operation
        state = `EXECB; opcode = `DIV; a = 32'd100; b = 32'd4;
        #10; // Wait for computation
        $display("DIV: a = %d, b = %d, result = %d, done = %b", a, b, result, done);

        // Test DIV operation with divide-by-zero
        state = `EXECB; opcode = `DIV; a = 32'd100; b = 32'd0;
        #10; // Wait for computation
        $display("DIV (Divide-by-zero): a = %d, b = %d, result = %h, done = %b", a, b, result, done);

        // Test MUL operation
        state = `EXECB; opcode = `MUL; a = 32'd6; b = 32'd7;
        #10; // Wait for computation
        $display("MUL: a = %d, b = %d, result = %d, done = %b", a, b, result, done);

        // Test SQRT operation
        state = `EXECB; opcode = `SQRT; a = 32'd16; b = 0; // Square root of 16
        #50; // Wait for square root computation (assuming sqrt_component takes time)
        $display("SQRT: a = %d, result = %d, done = %b", a, result, done);

        // Test POW operation
        state = `EXECB; opcode = `POW; a = 32'd2; b = 32'd3; // 2^3
        #10; // Wait for computation
        $display("POW: a = %d, b = %d, result = %d, done = %b", a, b, result, done);

        // Test default opcode
        state = `EXECB; opcode = 4'b1111; a = 32'd5; b = 32'd5; // Invalid opcode
        #10; // Wait for computation
        $display("Default: a = %d, b = %d, result = %d, done = %b", a, b, result, done);

        // End simulation
        $display("Test complete.");
        $finish;
    end

endmodule