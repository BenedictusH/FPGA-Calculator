`timescale 1ns / 1ps
`include "define.v"

module res_to_bcd_tb;

    // Parameters
    parameter M = 24;         // Width of the input value
    parameter I_FRAC = 8;     // Fractional bits for fixed-point inputs
    parameter BCD_WIDTH = 60;

    // Inputs
    reg CLK;
    reg RST;
    reg [M-1:0] i_val;
    reg [2:0] state;
    reg [3:0] opcode;
    

    // Outputs
    wire error_led;
    wire done;
    wire [BCD_WIDTH-1:0] o_bcd;

    // Instantiate the Unit Under Test (UUT)
    res_to_bcd uut (
        .CLK(CLK),
        .RST(RST),
        .i_val(i_val),
        .i_ce(),
        .is_fixed(),
        .is_signed(),
        .done(done),
        .o_bcd(o_bcd)
    );

    // Clock generation
    initial CLK = 0;
    always #5 CLK = ~CLK; // 10ns clock period (100 MHz)

    // Variables
    reg [59:0] final_result; // 15 digits of BCD result: 60 bits for the output
    integer i;               // Loop variable for debugging

    // Task to display the BCD result in hex format
    task display_result;
        begin
            $display("Final BCD Result (Hex): %h", final_result);
        end
    endtask

    // Task to apply a single test case
    task apply_test_case(
        input [M-1:0] test_val,
        input [3:0] test_opcode
    );
        begin
            // Apply inputs
            i_val = test_val;
            opcode = test_opcode;
            state = `EXECC;

            // Wait for the `done` signal
            wait (done == 1);

            // Capture the final BCD result
            final_result = uut.o_bcd;

            // Display the result
            display_result();

            // Reset the module
            #10;
            RST = 1;
            #10;
            RST = 0;

            // Wait a short time before the next test case
            #10;
        end
    endtask

    // Main testbench process
    initial begin
        // Initialize inputs
        RST = 1;
        i_val = 0;
        opcode = 0;
        state = 0;

        // Wait for reset to finish
        #20;
        RST = 0;

        // Test case 1: Unsigned integer input (255)
        apply_test_case(24'd123456, `SUM);

        // Test case 2: Signed integer input (-128)
        apply_test_case(-24'sd128, `SUM);

        // Test case 3: Fixed-point input (2.5 in Q8)
        apply_test_case(24'b00000010_10000000, `SIN);

//        // Test case 4: Fixed-point input (-1.5 in Q8)
//        apply_test_case(-24'sb00000001_10000000, `COS);

//        // Test case 5: Large fixed-point input (8388608 in Q8)
//        apply_test_case(24'b11111111_00000000, `EXP);

        // Test case 6: Error condition
        state = `EXECC;
        opcode = `SUM;
        i_val = 24'h0000FF;
        #50;
        $display("Error condition triggered.");

        // Finish simulation
        #100;
        $stop;
    end

endmodule