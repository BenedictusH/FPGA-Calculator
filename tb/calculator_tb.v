`timescale 1ns / 1ps
`include "define.v"

module calculator_tb;

    // Inputs
    reg CLK_in;
    reg RST_in;
    reg run;
    reg sw12, sw11, sw10, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1, sw0;
    reg but0, but1, but2;

    // Outputs
    wire error;
    wire [3:0] led_active;
    wire [7:0] led_code;

    // Instantiate the calculator module
    calculator uut (
        .CLK_in(CLK_in),
        .RST_in(RST_in),
        .run(run),
        .error(error),
        .led_active(led_active),
        .led_code(led_code),
        .sw12(sw12), .sw11(sw11), .sw10(sw10), .sw9(sw9), .sw8(sw8), 
        .sw7(sw7), .sw6(sw6), .sw5(sw5), .sw4(sw4), .sw3(sw3), 
        .sw2(sw2), .sw1(sw1), .sw0(sw0),
        .but0(but0),
        .but1(but1),
        .but2(but2)
    );

    // Clock generation
    initial begin
        CLK_in = 0;
        forever #10 CLK_in = ~CLK_in; // 10ns clock period (100 MHz clock)
    end

    // Testbench logic
    initial begin
        // Initialize inputs
        RST_in = 1; // Assert reset
        run = 0;
        but0 = 0;
        sw12 = 0; sw11 = 0; sw10 = 0; sw9 = 0;
        sw8 = 0; sw7 = 0; sw6 = 0; sw5 = 0;
        sw4 = 0; sw3 = 0; sw2 = 0; sw1 = 0; sw0 = 0;

        // Apply reset
        #20 
        RST_in = 0; // Deassert reset
        run = 1;
        #20;
        run = 0;

        // Test case: SUM operation for 10 + 20
        $display("Starting SUM operation test for 10 + 20...");

        // Set inputs for `a = 10` and `b = 20`
        
        sw2 = 1; // input 10
        #100
        but2 = 1;
        #30;
        but2 = 0;
        sw2 = 0; sw10 = 10; // input LOG
        #100;
        but1 = 1;
        #30;
        but1 = 0;
        sw6 = 0; sw7 = 1; sw5 = 1; // input 50
        #110;
        but0 = 1; #30 but0 = 0;
        #4000;
    end

endmodule