`timescale 1ns / 1ps
`include "define.v"

module cordic_exp #(
    parameter N =  `INPUTWIDTH,   // Input angle width (q4.8)
    parameter M = `OUTPUTWIDTH, // Output sine/cosine width (Q16.8 fixed-point)
    parameter W = 32,   // register working width Q 16.16
    parameter ITERATIONS = 20,    // Number of CORDIC iterations
    parameter I_FRAC = 8
) (
    input  signed [N-1:0] i_val, // Input value signed Q4.8
    input  wire                          CLK,   // Clock signal
    input  wire                          RST, // Reset signal
    input i_ce,
    output  [M-1:0] o_exp,  // Output (Q16.8 fixed-point)
    output done ,
    output error
);

    // ** Constants **
    localparam [31:0] RAD_TO_DEG =24'd14668; // 180/pi in Q16.8 fixed-point format.

    // ** Precomputed CORDIC angles in deg in Q16.16 fixed-point format **
    wire signed [31:0] atanh_table [0:ITERATIONS-1];
    // atanh 0 is not used as it is infinity
    assign atanh_table[0] = 32'd2062610;  // atanh(2^-0)
    assign atanh_table[1] = 32'd959059;  // atanh(2^-1)
    assign atanh_table[2] = 32'd471835;  // atanh(2^-2)
    assign atanh_table[3] = 32'd234990;  // atanh(2^-3)
    assign atanh_table[4] = 32'd117380;  // atanh(2^-4)
    assign atanh_table[5] = 32'd58676;  // atanh(2^-5)
    assign atanh_table[6] = 32'd29336;  // atanh(2^-6)
    assign atanh_table[7] = 32'd14668;  // atanh(2^-7)
    assign atanh_table[8] = 32'd7334;  // atanh(2^-8)
    assign atanh_table[9] = 32'd3667;  // atanh(2^-9)
    assign atanh_table[10] = 32'd1833;  // atanh(2^-9)
    assign atanh_table[11] = 32'd917;  // atanh(2^-9)
    assign atanh_table[12] = 32'd458;  // atanh(2^-9)
    assign atanh_table[13] = 32'd229;  // atanh(2^-9)
    assign atanh_table[14] = 32'd115;  // atanh(2^-9)
    assign atanh_table[15] = 32'd57;  // atanh(2^-9)
    assign atanh_table[16] = 32'd29;  // atanh(2^-9)
    assign atanh_table[17] = 32'd14;  // atanh(2^-9)
    assign atanh_table[18] = 32'd7;  // atanh(2^-9)   
    assign atanh_table[19] = 32'd4;  // atanh(2^-9)   
    // assign clock enable based on state and opcode
//    wire i_ce;
//    assign i_ce = state == `EXECB &&(opcode == `SIN || opcode == `COS || opcode == `TAN);
    
    // Add a counter to track the number of iterations
    reg [5:0] iteration_count; // Sufficient width to count up to ITERATIONS
    reg done_reg, error_reg;              // Register to store the done signal
    
    always @(posedge CLK) begin
        if (RST) begin
            iteration_count <= 0; // Reset the counter
            done_reg <= 0;        // Reset the done signal
        end else if (i_ce) begin
            if (iteration_count == ITERATIONS + 1) begin // +1 to account for delay and + 1 for final deg to rad conversion
                done_reg <= 1;    // Assert done when the final iteration is complete
            end else begin
                done_reg <= 0;    // Deassert done before the final iteration
            end
    
            // Increment the counter only if we're not done
            if (iteration_count < ITERATIONS + 1) begin
                iteration_count <= iteration_count + 1;
            end
        end
    end

    // ** Registers for pipeline stages **
    reg signed [W-1:0] x [0:ITERATIONS-1]; // X values (cosine)
    reg signed [W-1:0] y [0:ITERATIONS-1]; // Y values (sine)
    reg signed [W-1:0] z [0:ITERATIONS-1]; // Z values 

    // ** Input value preprocessing **
    localparam [W-1:0] K = 32'd79134;
    localparam signed [N-1:0] lower_bound = -12'd1 << I_FRAC;
    localparam signed [N-1:0] upper_bound = 12'd1 << I_FRAC;
    // bounds for degrees
    reg signed [W-1:0] i_deg;
    
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            error_reg <= 0;
            x[0] <= 0;
            y[0] <= 0;
            z[0] <= 0;
            x[ITERATIONS-1] <= 0;
            y[ITERATIONS-1] <= 0;
            z[ITERATIONS-1] <= 0;
        end else if (i_ce) begin
            //  handle out of range errors as outside of that range result is overflow for signed q16.8
            if (i_val >= lower_bound && i_val <= upper_bound) begin
                i_deg = i_val * RAD_TO_DEG;
                    
                z[0] <= i_deg;                
                x[0] <= K;
                y[0] <= K;
            end else begin
                error_reg <= 1;
            end         
        end
    end
    
   genvar i;

    generate
       for (i=0; i < (ITERATIONS - 1); i=i+1)
       begin: XYZ
          wire z_sign;
          wire signed  [W-1:0] x_shr, y_shr; 
       
          assign x_shr = x[i] >>> (i + 1); // signed shift right
          assign y_shr = y[i] >>> (i + 1);
       
          //the sign of the current rotation angle
          assign z_sign = z[i][31];
       
          always @(posedge CLK)
          begin
             // add/subtract shifted data
             x[i+1] <= z_sign ? x[i] - y_shr         : x[i] + y_shr;
             y[i+1] <= z_sign ? y[i] - x_shr         : y[i] + x_shr;
             z[i+1] <= z_sign ? z[i] + atanh_table[i] : z[i] - atanh_table[i];            
          end
       end
   endgenerate
   
   reg signed [W:0] exp; // final z value should never be neg, hence no need sign bit
      
   always @ (posedge CLK) begin
        exp <= x[ITERATIONS-1]; // result is now Q16.16 with 1 sign bit
   end 
   
   assign o_exp = exp >>> 8; // result is signed Q8.16 with 1 sign bit
   assign done = done_reg;
   assign error = error_reg;

endmodule