`timescale 1ns / 1ps

module cordic #(
    parameter N =  `INPUTWIDTH,   // Input angle width (12-bit signed)
    parameter M = `OUTPUTWIDTH, // Output sine/cosine width (Q16.8 fixed-point)
    parameter W = 32,   // register working width Q 16.16
    parameter ITERATIONS = 10    // Number of CORDIC iterations
) (
//    input CLK, RST,
    input  wire signed [N-1:0] i_angle, // Input angle in degrees (-360 to 360)
    input  wire                          CLK,   // Clock signal
    input  wire                          RST, // Reset signal
    input   [2:0] state,
    input   [3:0] opcode,  
    output  signed [M-1:0] o_sin,  // Output sine (Q16.8 fixed-point)
    output  signed [M-1:0] o_cos,  // Output cosine (Q16.8 fixed-point)
    output done 
);

    // ** Constants **
    localparam signed [31:0] DEG_TO_RAD = 32'd1144; // pi/180 in Q16.16 fixed-point format.
    localparam signed K = 32'd39797;    // K value in Q16.16

    // ** Precomputed CORDIC angles (atan(2^-i) in radians) in Q16.16 fixed-point format **
    wire signed [31:0] atan_table [0:ITERATIONS-1];
    assign atan_table[0] = 32'd51471;  // atan(2^-0)
    assign atan_table[1] = 32'd30385;  // atan(2^-1)
    assign atan_table[2] = 32'd16054;  // atan(2^-2)
    assign atan_table[3] = 32'd8148;  // atan(2^-3)
    assign atan_table[4] = 32'd4091;  // atan(2^-4)
    assign atan_table[5] = 32'd2047;  // atan(2^-5)
    assign atan_table[6] = 32'd1024;  // atan(2^-6)
    assign atan_table[7] = 32'd512;  // atan(2^-7)
    assign atan_table[8] = 32'd256;  // atan(2^-8)
    assign atan_table[9] = 32'd128;  // atan(2^-9)
    
    // assign clock enable based on state and opcode
    wire i_ce;
    assign i_ce = state == `EXECB &&(opcode == `SIN || opcode == `COS || opcode == `TAN);
    
    // Add a counter to track the number of iterations
    reg [5:0] iteration_count; // Sufficient width to count up to ITERATIONS
    reg done_reg;              // Register to store the done signal
    
    always @(negedge CLK) begin
        if (RST) begin
            iteration_count <= 0; // Reset the counter
            done_reg <= 0;        // Reset the done signal
        end else if (i_ce) begin
            if (iteration_count == ITERATIONS + 1) begin // +1 to account for falling edge trigger
                done_reg <= 1;    // Assert done when the final iteration is complete
            end else begin
                done_reg <= 0;    // Deassert done before the final iteration
            end
    
            // Increment the counter only if we're not done
            if (iteration_count <= ITERATIONS) begin
                iteration_count <= iteration_count + 1;
            end
        end
    end

    // ** Registers for pipeline stages **
    reg signed [W-1:0] x [0:ITERATIONS-1]; // X values (cosine)
    reg signed [W-1:0] y [0:ITERATIONS-1]; // Y values (sine)
    reg signed [W-1:0] z [0:ITERATIONS-1]; // Z values 

    // ** Input angle preprocessing **
    reg signed [W-1:0] normalized_angle; // register to hold normalized angle
    reg signed [W-1:0] angle_rad;        // Angle in Q16.16 fixed-point radians
    reg signed [43:0] temp_result;       // register to holld temp value res of conversion from deg to rad in Q16.16
    
    localparam signed oneoverK = 32'd107914;

    localparam signed x_in = K;
    localparam signed y_in = 0;
    
    always @(posedge CLK) begin
        if (RST) begin
            angle_rad <= 0;
            x[0] <= 0;
            x[0] <= 0;
            z[0] <= 0;
            x[ITERATIONS-1] <= 0;
            y[ITERATIONS-1] <= 0;
            z[ITERATIONS-1] <= 0;
        end else if (i_ce) begin
            // Angle normalization
            normalized_angle = i_angle % 360;
            if (normalized_angle < 0)
                normalized_angle = normalized_angle + 32'd360;
            
           if (normalized_angle < 90 ) begin 
                x[0] <= x_in;
                y[0] <= y_in;
           end else if (normalized_angle < 180) begin
                // Quadrant II
                x[0] <= -y_in;
                y[0] <= x_in;
                normalized_angle = normalized_angle - 32'd90;
            end else if (normalized_angle < 270) begin
                // Quadrant III
                x[0] <= y_in;
                y[0] <= -x_in;
                normalized_angle = normalized_angle - 32'd270;
            end else begin
                // Quadrant IV
                x[0] <= x_in;
                y[0] <= y_in;
                normalized_angle = normalized_angle - 32'd360; 
            end           
            
           temp_result = normalized_angle * DEG_TO_RAD;
           angle_rad <= temp_result[W-1:0];
           z[0] <= angle_rad;
        end
    end
    
   genvar i;

    generate
       for (i=0; i < (ITERATIONS-1); i=i+1)
       begin: XYZ
          wire                   z_sign;
          wire signed  [W-1:0] x_shr, y_shr; 
       
          assign x_shr = x[i] >>> i; // signed shift right
          assign y_shr = y[i] >>> i;
       
          //the sign of the current rotation angle
          assign z_sign = z[i][31]; // Z_sign = 1 if Z[i] < 0
       
          always @(posedge CLK)
          begin
             // add/subtract shifted data
             x[i+1] <= z_sign ? x[i] + y_shr         : x[i] - y_shr;
             y[i+1] <= z_sign ? y[i] - x_shr         : y[i] + x_shr;
             z[i+1] <= z_sign ? z[i] + atan_table[i] : z[i] - atan_table[i];
          end
       end
   endgenerate

   assign o_cos = x[ITERATIONS-1][W-1:W-M];
   assign o_sin = y[ITERATIONS-1][W-1:W-M];
   assign done = done_reg;

endmodule