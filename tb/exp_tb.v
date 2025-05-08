`timescale 1ns / 1ps

module exp_tb;

    // Parameters for the exp_decomposition module
    parameter N = 12;          // Input width (Q12.0 format)
    parameter M = 24;          // Output width (Q16.8 fixed-point)
    parameter W = 24;          // Working width (Q16.8 for division)
    parameter ITERATIONS = 20; // Number of iterations for CORDIC
    parameter I_FRAC = 8;      // Fractional bits for the output

    // Testbench signals
    reg signed [N-1:0] i_val;  // Input value in Q12.0 format
    reg CLK, RST, i_ce;        // Clock, reset, and clock enable signals
    wire [M-1:0] o_exp;        // Output value in Q16.8 format
    wire done;                 // Done signal
    wire error;                // Error signal

    // Instantiate the exp_decomposition module
    exp #(
        .N(N),
        .M(M),
        .W(W),
        .ITERATIONS(ITERATIONS),
        .I_FRAC(I_FRAC)
    ) uut (
        .i_val(i_val),
        .CLK(CLK),
        .RST(RST),
        .i_ce(i_ce),
        .o_exp(o_exp),
        .done(done),
        .error(error)
    );

    // Clock generation: 50 MHz clock (20 ns period)
    always #10 CLK = ~CLK;

    // Testbench initialization
    initial begin
        // Initialize signals
        CLK = 0;
        RST = 1;
        i_ce = 0;
        i_val = 0;

        // Apply reset and wait for a few clock cycles
        #40;
        RST = 0;

        // Start applying test cases with reset between each input
        test_case(12'sd0);      // Test Case 1: exp(0) = 1
        test_case(12'sd1);   // Test Case 2: exp(1) ? 2.718
        test_case(12'sd12);  // Test Case 3: exp(-1) ? 0.3678
        test_case(12'sd2);   // Test Case 4: exp(0.5) ? 1.6487
        test_case(-12'sd2);  // Test Case 5: exp(-0.5) ? 0.6065
        test_case(12'sd3);   // Test Case 6: exp(2) ? 7.3891
        test_case(-12'sd3);  // Test Case 7: exp(-2) ? 0.1353
        test_case(12'sd4);  // Test Case 8: exp(3) ? 20.0855
        test_case(-12'sd4); // Test Case 9: exp(-3) ? 0.0498
        test_case(12'sd2560);   // Test Case 10: exp(10) (boundary case)
        test_case(-12'sd1280);  // Test Case 11: exp(-5) (boundary case)

        // Out-of-bound test cases
        test_case(12'sd3000);   // Test Case 12: Out-of-bounds input (> 10)
        test_case(-12'sd1500);  // Test Case 13: Out-of-bounds input (< -5)

        // End simulation
        $stop;
    end

    // Task to apply test cases
    task test_case;
        input signed [N-1:0] value; // Input value in Q12.0 format
        begin
            // Apply reset
            RST = 1;
            #40;
            RST = 0;

            // Apply the input value
            i_val = value;
            i_ce = 1;

            // Wait for the `done` signal
            wait(done);

            // Disable clock enable
            i_ce = 0;

            // Wait a few clock cycles to observe the output
            #40;

            // Display results
            if (error) begin
                $display("Error: Input %d (Q12.0) is out of bounds at time %t", value, $time);
            end else begin
                $display("Input: %d (Q12.0) | Output: %f (Q16.8) | Time: %t", 
                         value, o_exp / (1 << I_FRAC), $time);
            end
        end
    endtask

    // Monitor outputs for debugging
    initial begin
        $monitor("Time = %0t | i_val = %d (Q12.0) | o_exp = %0f (Q16.8) | done = %b | error = %b",
                 $time, i_val, o_exp / (1 << I_FRAC), done, error);
    end

endmodule