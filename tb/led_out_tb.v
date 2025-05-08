`timescale 1ns / 1ps
`include "define.v"

module led_out_tb;

    // Parameters
    parameter M = `OUTPUTWIDTH;
    parameter I_FRAC = 8;
    parameter BCD_WIDTH = 60;

    // Testbench signals
    reg CLK;
    reg RST;
    reg i_ce;
    reg is_signed;
    reg is_fixed;
    reg [BCD_WIDTH-1:0] final_bcd;
    wire [3:0] bram_addr;
    wire [7:0] bram_data;
    wire bram_we;
    wire done;

    // Instantiate the DUT (Device Under Test)
    led_out #(.M(M), .I_FRAC(I_FRAC), .BCD_WIDTH(BCD_WIDTH)) dut (
        .CLK(CLK),
        .RST(RST),
        .i_ce(i_ce),
        .is_signed(is_signed),
        .is_fixed(is_fixed),
        .final_bcd(final_bcd),
        .bram_addr(bram_addr),
        .bram_data(bram_data),
        .bram_we(bram_we),
        .done(done)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK; // 10 ns clock period
    end

    // Testbench logic
    initial begin
        // Initialize signals
        RST = 1;
        i_ce = 0;
        is_signed = 0;
        is_fixed = 0;
        final_bcd = 0;

        // Wait for reset
        #20;
        RST = 0;

        // Test Case 1: Unsigned, non-fixed-point number (123456789)
        #10;
        i_ce = 1;
        final_bcd = 60'h000000123456789; // BCD input for 123456789
        is_signed = 0;
        is_fixed = 0;
        wait(done); // Wait for the done signal
        i_ce = 0;   // Clear i_ce

        // Reset before the next test case
        #10;
        RST = 1;
        #20;
        RST = 0;

        // Test Case 2: Signed, non-fixed-point number (-98765)
        #10;
        i_ce = 1;
        final_bcd = 60'h000000000098765; // BCD input for 98765
        is_signed = 1;
        is_fixed = 0;
        wait(done); // Wait for the done signal
        i_ce = 0;   // Clear i_ce

        // Reset before the next test case
        #10;
        RST = 1;
        #20;
        RST = 0;

        // Test Case 3: Unsigned, fixed-point number (123.45)
        #10;
        i_ce = 1;
        final_bcd = 60'h000000041234500; // BCD input for 123.45
        is_signed = 0;
        is_fixed = 1;
        wait(done); // Wait for the done signal
        i_ce = 0;   // Clear i_ce

        // Reset before the next test case
        #10;
        RST = 1;
        #20;
        RST = 0;

        // Test Case 4: Signed, fixed-point number (-0.456)
        #10;
        i_ce = 1;
        final_bcd = 60'h000000000004560; // BCD input for 0.456
        is_signed = 1;
        is_fixed = 1;
        wait(done); // Wait for the done signal
        i_ce = 0;   // Clear i_ce

        // End of simulation
        #10;
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0dns, RST: %b, i_ce: %b, is_signed: %b, is_fixed: %b, final_bcd: %h, bram_addr: %d, bram_data: %h, bram_we: %b, done: %b",
                 $time, RST, i_ce, is_signed, is_fixed, final_bcd, bram_addr, bram_data, bram_we, done);
    end

endmodule