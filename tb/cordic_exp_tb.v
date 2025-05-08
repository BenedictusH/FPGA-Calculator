`timescale 1ns / 1ps

module cordic_exp_tb;

    // Parameters
    parameter N = 12;  // Input Q4.8 width
    parameter M = 24;  // Output Q16.8 width
    parameter W = 32;  // Internal register Q16.16 width
    parameter ITERATIONS = 20;  // Number of CORDIC iterations

    // DUT Inputs
    reg [N-1:0] i_val;  // Input value in Q4.8
    reg CLK;            // Clock signal
    reg RST;            // Reset signal
    reg i_ce;           // Clock enable signal

    // DUT Outputs
    wire [M-1:0] o_exp;  // Output value in Q16.8
    wire done;          // Done signal

    // Instantiate the DUT
    cordic_exp #(
        .N(N),
        .M(M),
        .W(W),
        .ITERATIONS(ITERATIONS)
    ) uut (
        .i_val(i_val),
        .CLK(CLK),
        .RST(RST),
        .i_ce(i_ce),
        .o_exp(o_exp),
        .done(done)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;  // Generate a clock with a 10ns period
    end

    // Helper task to convert Q16.8 fixed-point to real for better readability
    task display_q16p8;
        input [M-1:0] qnum;  // Q16.8 fixed-point number
        real realnum;
        begin
            realnum = qnum / (1 << 8);  // Convert Q16.8 to real
            $write("%f", realnum);
        end
    endtask

    // Test stimulus
    initial begin
        // Monitor outputs
        $monitor("Time = %0t | i_val = %d | o_exp = ", $time, i_val);
        display_q16p8(o_exp);
        $write(" | done = %b\n", done);

        // Initialize signals
        RST = 1;  // Assert reset
        i_ce = 0;
        i_val = 0;
        #20;  // Hold reset for 20ns
        RST = 0;  // Deassert reset

        // Test Case 1: Calculate ln(1.5)
        i_val = 12'd79;  // 1 in Q8.4 (1.5 * 2^8 = 384)
        i_ce = 1;
        wait(done);  // Wait for the calculation to complete
        i_ce = 0;     
        #20;

        // Assert reset before the next input
        RST = 1;
        #20;
        RST = 0;

        // Test Case 2: Calculate ln(2.0)
        i_val = 12'h200;  // 2.0 in Q4.8 (2.0 * 2^8 = 512)
        i_ce = 1;
        wait(done);
        i_ce = 0;        
        #20;

        // Assert reset before the next input
        RST = 1;
        #20;
        RST = 0;

        // Test Case 3: Calculate ln(0.5)
        i_val = 12'h008;  // 0.5 in Q4.8 (0.5 * 2^8 = 128)
        i_ce = 1;
        wait(done);
        i_ce = 0;
        #20;

        // Assert reset before the next input
        RST = 1;
        #20;
        RST = 0;

        // Test Case 4: Calculate ln(1.0)
        i_val = 12'h090;  // 1.0 in Q4.8 (1.0 * 2^8 = 256)
        i_ce = 1;
        #10;
        i_ce = 0;
        wait(done);
        #20;

        // Assert reset before the next input
        RST = 1;
        #20;
        RST = 0;

        // Test Case 5: Calculate ln(0.0) (edge case)
        i_val = 12'd0;  // 0.0 in Q4.8
        i_ce = 1;
        #10;
        i_ce = 0;
        wait(done);
        #20;

        // Assert reset before the next input
        RST = 1;
        #20;
        RST = 0;

        // Test Case 6: Calculate ln(10.0) (input out of range, error handling)
        i_val = 12'd2560;  // 10.0 in Q4.8 (10.0 * 2^8 = 2560)
        i_ce = 1;
        #10;
        i_ce = 0;
        wait(done);
        #20;

        // Assert reset before the next input
        RST = 1;
        #20;
        RST = 0;

        // End simulation
        $finish;
    end

endmodule