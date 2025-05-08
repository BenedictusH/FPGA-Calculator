`timescale 1ns / 1ps
`include "define.v"

module input_module_tb;

    // Parameter for input width
    parameter N = 12; // Adjust this parameter to match your design

    // Inputs
    reg CLK;
    reg RST;
    reg [2:0] state;
    reg but0;
    reg sw12, sw11, sw10, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1, sw0;

    // Outputs
    wire [7:0] led_code; 
    wire [3:0] led_active;
    wire signed [N-1:0] a, b;
    wire [2:0] opcode;
    wire inputed;

    // Instantiate the module under test (MUT)
    input_module #(N) uut (
        .CLK(CLK),
        .RST(RST),
        .state(state),
        .but0(but0),
        .sw12(sw12), .sw11(sw11), .sw10(sw10), .sw9(sw9), .sw8(sw8), 
        .sw7(sw7), .sw6(sw6), .sw5(sw5), .sw4(sw4), .sw3(sw3), 
        .sw2(sw2), .sw1(sw1), .sw0(sw0),
        .led_active(led_active), .led_code(led_code),      
        .a(a),
        .b(b),
        .opcode(opcode),
        .done(inputed)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK; // 10ns clock period (100 MHz)
    end

    // Testbench logic
    initial begin
        // Initialize inputs
        RST = 1; state = 3'd0; but0 = 0;
        {sw12, sw11, sw10, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1, sw0} = 13'b0;

        // Apply reset
        #10 RST = 0;

        // Test case 1: Input A
        state = `EXECA;
        #10;
        {sw12, sw11, sw10, sw9} = 4'd1; // Hundreds = 1
        {sw8, sw7, sw6, sw5} = 4'd2;    // Tens = 2
        {sw4, sw3, sw2, sw1} = 4'd9;    // Ones = 3
        sw0 = 1;                        // Signed = negative
        #2000
        but0 = 1; #10; but0 = 0;        // Press button to move to OPERATION

        // Test case 2: Select SUM operation
        {sw12, sw11, sw10, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1} = 11'b100_0000_0000; // SUM
        #10 but0 = 1; #10 but0 = 0; // Press button to move to CHECK_OPCODE

        // Test case 3: Enter Input B
        {sw12, sw11, sw10, sw9} = 4'd4; // Hundreds = 4
        {sw8, sw7, sw6, sw5} = 4'd5;    // Tens = 5
        {sw4, sw3, sw2, sw1} = 4'd6;    // Ones = 6
        sw0 = 0;                        // Signed = positive
        #50 but0 = 1; #10 but0 = 0;    // Press button to confirm input
        
        RST = 1; #10 RST =0;

        // Test case 4: Invalid opcode
        state = `EXECA;
        {sw12, sw11, sw10, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1} = 11'b111_1111_1111; // Invalid opcode
        #10 but0 = 1; #10 but0 = 0; // Press button to move to CHECK_OPCODE

        // Test case 5: Single input operation (e.g., SQRT)
        state = `EXECA;
        {sw12, sw11, sw10, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1} = 11'b000_0100_0000; // SQRT
        sw0 = 0; // Signed = positive
        #10 but0 = 1; #10 but0 = 0; // Confirm SQRT opcode

        // End simulation
        #50 $finish;
    end

    // Monitor outputs for debugging
    initial begin
        $monitor("Time = %0t | RST = %b | State = %b | A = %d | B = %d | Opcode = %b | Inputed = %b",
                 $time, RST, state, a, b, opcode, inputed);
    end
endmodule