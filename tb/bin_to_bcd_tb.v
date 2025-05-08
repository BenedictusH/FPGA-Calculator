`timescale 1ns / 1ps

module bin_to_bcd_tb;

    // Parameters
    parameter INPUT_WIDTH = 24;
    parameter DECIMAL_DIGITS = 7; // Adjusted for the maximum number of decimal digits (e.g., 7 for 24-bit input)

    // Testbench signals
    reg i_Clock;
    reg [INPUT_WIDTH-1:0] i_Binary;
    reg i_Start;
    wire [DECIMAL_DIGITS*4-1:0] o_BCD;
    wire o_DV;

    // Instantiate the Binary_to_BCD module
    bin_to_bcd #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .DECIMAL_DIGITS(DECIMAL_DIGITS)
    ) uut (
        .i_Clock(i_Clock),
        .i_Binary(i_Binary),
        .i_Start(i_Start),
        .o_BCD(o_BCD),
        .o_DV(o_DV)
    );

    // Clock generation: 50 MHz clock (20 ns period)
    always #10 i_Clock = ~i_Clock;

    // Testbench initialization
    initial begin
        // Initialize signals
        i_Clock = 0;
        i_Binary = 0;
        i_Start = 0;

        // Wait for global reset
        #50;

        // Test Case 1: Binary 0
        test_case(24'd0);

        // Test Case 2: Binary 123456
        test_case(24'd123456);

        // Test Case 3: Binary 16777215 (max value for 24-bit input)
        test_case(24'd16777215);

        // Test Case 4: Binary 1000000
        test_case(24'd1000000);

        // Test Case 5: Binary 999999
        test_case(24'd999999);

        // End simulation
        $stop;
    end

    // Task to apply test cases and display results
    task test_case;
        input [INPUT_WIDTH-1:0] binary_value;
        integer i;
        reg [3:0] bcd_digit;
        begin
            // Apply input and start the conversion
            i_Binary = binary_value;
            i_Start = 1;
            #20; // Wait for one clock cycle
            i_Start = 0;

            // Wait for the valid signal (o_DV)
            wait(o_DV);

            // Display the binary input
            $display("Binary Input: %d", binary_value);

            // Display the BCD output in bits
            $write("BCD Output (Bits): ");
            for (i = DECIMAL_DIGITS-1; i >= 0; i = i - 1) begin
                bcd_digit = o_BCD[(i*4) +: 4]; // Extract each BCD digit
                $write("%b ", bcd_digit);
            end
            $display(); // Newline for clarity

            // Display the time at which the conversion was completed
            $display("Conversion completed at Time: %t\n", $time);

            #50; // Wait for a few clock cycles before the next test case
        end
    endtask

endmodule