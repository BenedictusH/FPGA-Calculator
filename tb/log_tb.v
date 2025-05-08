`timescale 1ns / 1ps
`include "define.v"

// Testbench for the `log` module
module log_tb;

    // Parameters
    localparam N = `INPUTWIDTH;
    localparam M = `OUTPUTWIDTH;
    localparam W = 24;

    // Testbench signals
    reg CLK;
    reg RST;
    reg signed [N-1:0] a, b;
    reg [2:0] state;
    reg [3:0] opcode;
    wire signed [M-1:0] o_log;
    wire done;
    wire error;

    // Instantiate the log module
    log #(N, M, W) uut (
        .CLK(CLK),
        .RST(RST),
        .a(a),
        .b(b),
        .state(state),
        .opcode(opcode),
        .o_log(o_log),
        .done(done),
        .error(error)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK; // 10ns clock period
    end

    // Task to reset the system
    task reset_system();
        begin
            state = `IDLE;
            RST = 1; // Assert reset
            #20;     // Hold reset for 20ns
            RST = 0; // Deassert reset
            #10;     // Wait for system to stabilize
        end
    endtask

    // Task to display Q16.8 formatted value
    task display_q16_8(input signed [M-1:0] value, input signed [N-1:0] a_val, input signed [N-1:0] b_val);
        real real_value;
        begin
            // Convert Q16.8 to real value
            real_value = value / 256.0;
            $display("Operation: %d log %d | o_log (Q16.8) = %f", a_val, b_val, real_value);
        end
    endtask

    // Testbench procedure
    initial begin
        // Initialize inputs
        a = 0;
        b = 0;
        state = `IDLE;
        opcode = 0;

        // Test case 1: Valid input for a and b
        reset_system(); // Reset before the test
        state = `EXECB;
        opcode = `LOG;
        a = 12; // Example positive value
        b = 3;  // Example positive value
        #1000; // Wait for computation
        if (done && !error) begin
            $display("Test case 1 passed:");
            display_q16_8(o_log, a, b);
        end else
            $display("Test case 1 failed: error = %b, done = %b", error, done);

        // Test case 2: Valid input for a and b
        reset_system(); // Reset before the test
        state = `EXECB;
        opcode = `LOG;
        a = 4; // Example positive value
        b = 16;  // Example positive value
        #1000; // Wait for computation
        if (done && !error) begin
            $display("Test case 2 passed:");
            display_q16_8(o_log, a, b);
        end else
            $display("Test case 2 failed: error = %b, done = %b", error, done);

        // Test case 3: Valid input for a and b
        reset_system(); // Reset before the test
        state = `EXECB;
        opcode = `LOG;
        a = 3; // Example positive value
        b = 27;  // Example positive value
        #1000; // Wait for computation
        if (done && !error) begin
            $display("Test case 3 passed:");
            display_q16_8(o_log, a, b);
        end else
            $display("Test case 3 failed: error = %b, done = %b", error, done);

        // Test case 4: Valid input for a and b
        reset_system(); // Reset before the test
        state = `EXECB;
        opcode = `LOG;
        a = 3; // Example positive value
        b = 36;  // Example positive value
        #1000; // Wait for computation
        if (done && !error) begin
            $display("Test case 4 passed:");
            display_q16_8(o_log, a, b);
        end else
            $display("Test case 4 failed: error = %b, done = %b", error, done);

        // Test case 5: Valid input for a and b
        reset_system(); // Reset before the test
        state = `EXECB;
        opcode = `LOG;
        a = 1; // Edge value
        b = 1; // Edge value
        #1000; // Wait for computation
        if (done && error) begin
            $display("Test case 5 passed:");
            display_q16_8(o_log, a, b);
        end else
            $display("Test case 5 failed: error = %b, done = %b", error, done);

        // End simulation
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time = %0t | RST = %b | a = %d | b = %d | state = %b | opcode = %b | o_log = %d | done = %b | error = %b",
                 $time, RST, a, b, state, opcode, o_log, done, error);
    end

endmodule