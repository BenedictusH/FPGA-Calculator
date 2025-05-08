`timescale 1ns / 1ps
`include "define.v"

module arithmetic #(parameter N = `INPUTWIDTH, parameter M = `OUTPUTWIDTH) (    
    input CLK, RST,  
    input signed [N-1:0] a, b,
    input [2:0] state,           
    input [3:0] opcode,
    output reg error,             
    output reg [M-1:0] result,    // Final output result
    output reg done               // Done signal
); 

// Internal register for intermediate result computation
reg [M-1:0] result_reg;

// Wires for square root component
wire [N/2-1:0] sq_root; // Output from sqrt_component
wire sqrt_done;         // Done signal from sqrt_component

// Square Root Component Instance
square_root sqrt_component (
    .Clock(CLK), 
    .reset(RST), 
    .num_in(a),
    .state(state),
    .opcode(opcode), 
    .done(sqrt_done),
    .sq_root(sq_root)
);

// Wires for cordic operations
wire [M-1:0] sin, cos;
wire cordic_done;

cordic cordic_component(
    .CLK(CLK),
    .RST(RST),
    .state(state),
    .opcode(opcode),
    .i_angle(a),
    .o_cos(cos),
    .o_sin(sin),
    .done(cordic_done)
);

// Wires for log operations
wire [M-1:0] o_log;
wire log_done, log_error;

log log_component (
    .CLK(CLK),
    .RST(RST),
    .a(a),
    .b(b),
    .state(state),
    .opcode(opcode),
    .o_log(o_log),
    .done(log_done),
    .error(log_error)
);

// Wires for division operations
wire div_done, div_valid, dbz;
wire [M-1:0] o_div;
reg [M-1:0] a_shifted, b_shifted;
reg div_start;

// Division Component Instance
division div_component (
    .CLK(CLK),
    .RST(RST),
    .start(div_start),
    .done(div_done),
    .valid(div_valid),
    .dbz(dbz),
    .a(a_shifted),
    .b(b_shifted),
    .o_val(o_div)
);

// Wires for exp module
wire [M-1:0] o_exp;
wire exp_done;
wire exp_error;

// Exp Component Instance
exp exp_component (
    .i_val(a),        // Input value in Q12.0 format
    .CLK(CLK),
    .RST(RST),
    .i_ce(state == `EXECB && opcode == `EXP), // Enable only during EXP operation
    .o_exp(o_exp),    // Output result in Q16.8 format
    .done(exp_done),
    .error(exp_error)
);

// Wires for power module
wire [M-1:0] o_power;
wire power_done;
wire power_error;

// Power Component Instance
power power_component (
    .CLK(CLK),
    .RST(RST),
    .a(a),
    .b(b),
    .state(state),
    .opcode(opcode),
    .o_power(o_power), // Result in Q16.8 format
    .error(power_error),
    .done(power_done)
);

// Fixed-point division wires for TAN
reg [2*M-1:0] sin_scaled; // Scaled numerator (sin << 16)
reg [M-1:0] tan_result;   // Result of division (Q8.16)

// Main computation process
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        // Reset all control signals
        result <= 0;
        result_reg <= 0;
        done <= 0;
        div_start <= 0;
        error <= 0;
    end else begin
        done <= 0;          
        div_start <= 0;     
        error <= 0;         

        a_shifted <= 0;     
        b_shifted <= 0;

        if (state == `EXECB) begin
            // Perform the operation based on the opcode
            case (opcode)
                `SUM: begin                    
                    result_reg = a + b;
                    done = 1;
                end          
                `SUB: begin
                    result_reg = a - b;
                    done = 1;
                end          
                `DIV: begin
                    a_shifted <= a << 8;
                    b_shifted <= b << 8;
                    div_start <= 1;
                   
                    if (div_done) begin
                        if (div_valid) result_reg <= o_div;
                        else begin
                            result_reg <= 32'hDEADBEEF;
                            error <= 1;
                        end
                        done = 1;
                    end
                end                 
                `MUL: begin
                    result_reg = a * b;
                    done = 1;
                end          
                `SQRT: begin
                    if (sqrt_done) begin
                        result_reg = {{(N-M/2){sq_root[N/2-1]}}, sq_root}; // Assign result from sqrt_component while doing sign extension
                        done = 1;            // Indicate computation is complete
                    end
                end
                `POW: begin
                    if (power_done) begin
                        if (!power_error) result_reg <= o_power;
                        else begin
                            result_reg <= 32'hDEADBEEF; // Error value
                            error <= 1;
                        end
                        done = 1;
                    end
                end          
                `LOG: begin
                    if (log_done) begin
                        if (!log_error) begin
                            result_reg <= o_log;    
                        end else begin
                            result_reg <= 32'hDEADBEEF; 
                            error <= 1;                 
                        end
                        done <= 1; 
                    end else begin
                        done <= 0;
                    end
                end
                `EXP: begin
                    if (exp_done) begin
                        if (!exp_error) result_reg <= o_exp;
                        else begin
                            result_reg <= 32'hDEADBEEF; // Error value
                            error <= 1;
                        end
                        done = 1;
                    end
                end
                `COS: begin
                    if (cordic_done) begin
                        result_reg <= cos;
                        done = 1;
                    end
                end 
                `SIN: begin
                    if (cordic_done) begin
                        result_reg <= sin;
                        done = 1;
                    end
                end           
                `TAN: begin
                    if (cordic_done) begin
                        a_shifted <= sin;
                        b_shifted <= cos;
                        div_start <= 1;

                        if (div_done) begin
                            if (div_valid) result_reg <= o_div;
                            else begin
                                result_reg <= 32'hDEADBEEF;
                                error <= 1;
                            end
                            done = 1;
                        end
                    end
                end     
                default: begin
                    result_reg <= 0;          
                end
            endcase
        end
    end
end

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        result <= 0; 
    end else if (done) begin
        result <= result_reg;
    end
end

endmodule