`timescale 1ns / 1ps

module cordic_log_tb;

    // Parameters
    parameter N = 12;   // Input angle width (12-bit signed)
    parameter M = 24;   // Output sine/cosine width (Q16.8 fixed-point)
    parameter W = 24;   // Working width Q16.16

    // Inputs
    reg signed [N-1:0] i_val;  // Input angle in degrees (Q12 format)
    reg i_clk;
    reg i_reset;
    reg i_ce;
    reg [2:0] state;
    reg [3:0] opcode;

    // Outputs
    wire signed [M-1:0] o_ln;  // Output sine (Q16.8 fixed-point)
    wire done;


    // Instantiate the CORDIC module
    cordic_log  uut (
        .i_val(i_val),
        .CLK(i_clk),
        .RST(i_reset),
        .i_ce(i_ce),
        .o_ln(o_ln),
        .done(done)
    );

    // Clock generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;  // 10ns clock period
    end

    // Stimulus
    initial begin
        // Initialize inputs
        i_reset = 1;
        i_ce = 0;
        i_val = 12'd384;
        


        // Wait for global reset
        #20;
        i_reset = 0;
        i_ce = 1;

        // Apply test angles in the range [0, 90] degrees
        repeat (10) begin
            #500;
            i_reset = 1;
            state = `IDLE;
            #20;
            i_reset = 0;
            state = `EXECB;
            i_val = i_val + 12'd15;
             // Increment angle by 9 degrees (in Q12 format)
        end

        // Finish simulation
        #100;
        $finish;
    end

    // Monitor outputs
    initial begin
    end

endmodule