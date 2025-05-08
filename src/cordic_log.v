`timescale 1ns / 1ps

module cordic_log #(
    parameter N = `INPUTWIDTH,   // Input angle width (12-bit signed)
    parameter M = `OUTPUTWIDTH, // Output logarithm width (Q16.8 fixed-point)
    parameter W = 32,           // Register working width Q16.16
    parameter ITERATIONS = 20   // Number of CORDIC iterations
) (
    input  wire [N-1:0] i_val,  // Input value Q4.8
    input  wire CLK,            // Clock signal
    input  wire RST,            // Reset signal
    input  wire i_ce,           // Clock enable
    output wire [M-1:0] o_ln,   // Output logarithm (Q16.8 fixed-point)
    output wire done            // Done signal
);

    // ** Constants **
    localparam [31:0] DEG_TO_RAD = 32'd1144; // pi/180 in Q16.16 fixed-point format.

    // ** Precomputed CORDIC atanh values in Q16.16 fixed-point format **
    wire signed [31:0] atanh_table [0:ITERATIONS-1];
    assign atanh_table[0] = 32'd2062610;  // atanh(2^-0)
    assign atanh_table[1] = 32'd959059;   // atanh(2^-1)
    assign atanh_table[2] = 32'd471835;   // atanh(2^-2)
    assign atanh_table[3] = 32'd234990;   // atanh(2^-3)
    assign atanh_table[4] = 32'd117380;   // atanh(2^-4)
    assign atanh_table[5] = 32'd58676;    // atanh(2^-5)
    assign atanh_table[6] = 32'd29336;    // atanh(2^-6)
    assign atanh_table[7] = 32'd14668;    // atanh(2^-7)
    assign atanh_table[8] = 32'd7334;     // atanh(2^-8)
    assign atanh_table[9] = 32'd3667;     // atanh(2^-9)
    assign atanh_table[10] = 32'd1833;    // atanh(2^-10)
    assign atanh_table[11] = 32'd917;     // atanh(2^-11)
    assign atanh_table[12] = 32'd458;     // atanh(2^-12)
    assign atanh_table[13] = 32'd229;     // atanh(2^-13)
    assign atanh_table[14] = 32'd115;     // atanh(2^-14)
    assign atanh_table[15] = 32'd57;      // atanh(2^-15)
    assign atanh_table[16] = 32'd29;      // atanh(2^-16)
    assign atanh_table[17] = 32'd14;      // atanh(2^-17)
    assign atanh_table[18] = 32'd7;       // atanh(2^-18)
    assign atanh_table[19] = 32'd4;       // atanh(2^-19)

    // ** Iteration counter and done signal **
    reg [5:0] iteration_count; // Sufficient width to count up to ITERATIONS
    reg done_reg;              // Register to store the done signal
    
    always @(posedge CLK) begin
        if (RST) begin
            iteration_count <= 0; // Reset the counter
            done_reg <= 0;        // Reset the done signal
        end else if (i_ce) begin
            if (iteration_count == ITERATIONS + 2) begin // +1 for latency and +1 for final conversion
                done_reg <= 1;    // Assert done when the final iteration is complete
            end else begin
                done_reg <= 0;    // Deassert done before the final iteration
            end
    
            // Increment the counter only if we're not done
            if (iteration_count < ITERATIONS + 2) begin
                iteration_count <= iteration_count + 1;
            end
        end
    end

    // ** Registers for pipeline stages **
    reg skip; // Skip calculations if input is ln(1)
    reg signed [W-1:0] x [0:ITERATIONS]; // X values
    reg signed [W-1:0] y [0:ITERATIONS]; // Y values
    reg signed [W-1:0] z [0:ITERATIONS]; // Z values 

    // ** Input value preprocessing **
    reg signed [W-1:0] a;
    
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            a <= 0;
            x[0] <= 0;
            y[0] <= 0;
            z[0] <= 0;
            skip <= 0;
        end else if (i_ce) begin
            a <= i_val << 8; // Convert input to Q16.8
            if (a == 0) begin
                x[0] <= 0;
                y[0] <= 0;
                z[0] <= 0;
                skip <= 1; // Skip calculations for ln(1)
            end else if (a == 32'd65536) begin // ln(1) = 0
                x[0] <= 0;
                y[0] <= 0;
                z[0] <= 0;
                skip <= 1;
            end else begin
                x[0] <= a + (32'b1 << 16); // Initial X
                y[0] <= a - (32'b1 << 16); // Initial Y
                z[0] <= 32'b0;            // Initial Z
                skip <= 0;
            end
        end
    end

    // ** CORDIC Iterations **
    genvar i;
    generate
        for (i = 0; i < ITERATIONS; i = i + 1) begin: XYZ
            wire signed [W-1:0] x_shr, y_shr; 
            assign x_shr = x[i] >>> (i + 1); // Signed shift right
            assign y_shr = y[i] >>> (i + 1);
            wire y_sign = y[i][31];          // Sign of Y determines the direction

            always @(posedge CLK) begin
                if (RST) begin
                    x[i+1] <= 0;
                    y[i+1] <= 0;
                    z[i+1] <= 0;
                end else if (i_ce) begin
                    x[i+1] <= y_sign ? x[i] + y_shr : x[i] - y_shr;
                    y[i+1] <= y_sign ? y[i] + x_shr : y[i] - x_shr;
                    z[i+1] <= y_sign ? z[i] - atanh_table[i] : z[i] + atanh_table[i];
                end
            end
        end
    endgenerate

    // ** Final Output Calculation **
    reg signed [W:0] ln; // Final Z value
    always @(posedge CLK) begin
        if (skip) 
            ln <= 0;
        else 
            ln <= z[ITERATIONS] * DEG_TO_RAD; // Convert to Q1.31
    end

    assign o_ln = ln >>> 15; // Convert to Q7.16
    assign done = done_reg;

endmodule