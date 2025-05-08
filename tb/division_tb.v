`timescale 1ns / 1ps

module division_tb;

    // Parameters
    parameter WIDTH = 24;  // Total width for Q16.8 numbers
    parameter FBITS = 8;   // Fractional bits

    // Inputs to the DUT
    reg clk;
    reg rst;
    reg start;
    reg signed [WIDTH-1:0] a;  // Dividend (Q16.8)
    reg signed [WIDTH-1:0] b;  // Divisor (Q16.8)

    // Outputs from the DUT
    wire busy;
    wire done;
    wire valid;
    wire dbz;  // Divide by zero
    wire ovf;  // Overflow
    wire signed [WIDTH-1:0] val;  // Result value (Q16.8)

    // Instantiate the division module
    division #(
        .WIDTH(WIDTH),
        .FBITS(FBITS)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .busy(busy),
        .done(done),
        .valid(valid),
        .dbz(dbz),
        .ovf(ovf),
        .a(a),
        .b(b),
        .val(val)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Generate a clock with 10ns period
    end

    // Helper task to display Q16.8 numbers (convert Q16.8 to decimal)
    task display_q16p8;
        input signed [WIDTH-1:0] qnum;
        real realnum;
        begin
            realnum = qnum / (1 << FBITS);  // Convert fixed-point to real
            $write("%f", realnum);
        end
    endtask

    // Test stimulus
    initial begin
        // Monitor the output
        $monitor("Time = %0t | a = ", $time);
        display_q16p8(a);
        $write(", b = ");
        display_q16p8(b);
        $write(", Result = ");
        display_q16p8(val);
        $write(" | Busy = %b | Done = %b | Valid = %b | DBZ = %b | OVF = %b\n",
               busy, done, valid, dbz, ovf);

        // Initial reset
        rst = 1;
        start = 0;
        a = 0;
        b = 0;
        #15;
        rst = 0;

        // Test Case 1: Basic division (10.0 / 2.0 = 5.0)
        a = 24'sd2560;  // 10.0 in Q16.8 (10.0 * 2^8 = 2560)
        b = 24'sd512;   // 2.0 in Q16.8 (2.0 * 2^8 = 512)
        start = 1;
        #10;
        start = 0;
        wait(done);
        #20;

        // Test Case 2: Division by zero (10.0 / 0.0)
        a = 24'sd2560;  // 10.0 in Q16.8
        b = 24'sd0;     // 0.0 in Q16.8
        start = 1;
        #10;
        start = 0;
        wait(done);
        #20;

        // Test Case 3: Negative dividend (-10.0 / 2.0 = -5.0)
        a = -24'sd2560;  // -10.0 in Q16.8
        b = 24'sd512;    // 2.0 in Q16.8
        start = 1;
        #10;
        start = 0;
        wait(done);
        #20;

        // Test Case 4: Negative divisor (10.0 / -2.0 = -5.0)
        a = 24'sd2560;   // 10.0 in Q16.8
        b = -24'sd512;   // -2.0 in Q16.8
        start = 1;
        #10;
        start = 0;
        wait(done);
        #20;

        // Test Case 5: Both negative (-10.0 / -2.0 = 5.0)
        a = -24'sd2560;  // -10.0 in Q16.8
        b = -24'sd512;   // -2.0 in Q16.8
        start = 1;
        #10;
        start = 0;
        wait(done);
        #20;

        // Test Case 6: Fractional result (10.0 / 3.0 = 3.3333)
        a = 24'sd2560;   // 10.0 in Q16.8
        b = 24'sd768;    // 3.0 in Q16.8
        start = 1;
        #10;
        start = 0;
        wait(done);
        #20;

        // Test Case 7: Small fractional result (1.0 / 256.0 = 0.0039)
        a = 24'sd256;    // 1.0 in Q16.8
        b = 24'sd65536;  // 256.0 in Q16.8
        start = 1;
        #10;
        start = 0;
        wait(done);
        #20;

        // Test Case 8: Zero dividend (0.0 / 5.0 = 0.0)
        a = 24'sd0;      // 0.0 in Q16.8
        b = 24'sd1280;   // 5.0 in Q16.8
        start = 1;
        #10;
        start = 0;
        wait(done);
        #20;

        // Test Case 9: Large positive numbers
        a = 24'sd32767;  // Close to max positive Q16.8
        b = 24'sd128;    // 0.5 in Q16.8
        start = 1;
        #10;
        start = 0;
        wait(done);
        #20;

        // Test Case 10: Overflow case (-32768 / 0.5)
        a = -24'sd32768;  // Smallest negative Q16.8
        b = 24'sd128;     // 0.5 in Q16.8
        start = 1;
        #10;
        start = 0;
        wait(done);
        #20;

        // End of simulation
        $finish;
    end

endmodule