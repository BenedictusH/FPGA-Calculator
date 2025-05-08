`timescale 1ns / 1ps
`include "define.v"

module power #(parameter N = `INPUTWIDTH, parameter M = `OUTPUTWIDTH)(
    input CLK, RST,
    input signed [N-1:0] a, b,
    input [2:0] state,
    input [3:0] opcode,
    output signed [M-1:0] o_power, // result will be in q16.8 format to accomodate the ability of simple negative power
    output reg error,
    output reg done
);
    
    localparam IDLE = 3'd0, NEG = 3'd1, POS = 3'd2, CHECK = 3'd3, DIV = 3'd4, DONE = 3'd5;
    
    wire i_ce;
    reg [2:0] local_state; // Updated to 3 bits to accommodate additional states
    reg signed [N-1:0] counter; // Counter for the exponent
    reg [M-1:0] result_reg;
    reg [M-1:0] numerator; // For division: numerator = 1
    wire signed [N-1:0] abs_b; // Absolute value of the exponent (for negative powers)

    assign i_ce = state == `EXECB && opcode == `POW;
    assign o_power = result_reg;
    assign abs_b = (b[N-1] == 1'b1) ? -b : b;

    // Wires for division operations
    reg div_start;
    wire div_done, div_valid, dbz;
    wire [M-1:0] o_div;
    reg [M-1:0] denominator;

    division div_component (
        .CLK(CLK),
        .RST(RST),
        .start(div_start),
        .done(div_done),
        .valid(div_valid),
        .dbz(dbz),
        .a(numerator),       // Numerator is 1 for `1/(a**b)`
        .b(denominator),      // Denominator is the positive power result
        .o_val(o_div)
    );    
    
    always @(posedge CLK) begin
        if (RST) begin
            local_state <= IDLE;
            result_reg <= 0;
            done <= 0;
            error <= 0;
            counter <= 0;
            numerator <= 1;
            div_start <= 0;
        end else begin
            case (local_state)
                IDLE: begin
                    done <= 0;
                    error <= 0;
                    if (i_ce) begin
                        local_state <= CHECK;
                        result_reg <= 1; // Reset result
                        done <= 0;
                        error <= 0;
                    end
                end
                CHECK: begin
                    // Preliminary checks
                    if (a == 0) begin
                        result_reg <= 0;
                        done <= 1;
                        local_state <= DONE;
                    end else if (a < 0) begin
                        result_reg <= 32'hDEADBEEF; // negative base is not supported
                        error <= 1;
                        local_state <= DONE;
                    end else if (b == 0) begin
                        result_reg <= 1;
                        done <= 1;
                        local_state <= DONE;
                    end else if (b > 16) begin
                        result_reg <= 32'hDEADBEEF; // Overflow for large exponents because of result in the q16.8 format
                        error <= 1;
                        done <= 1;
                        local_state <= DONE;
                    end else if (b > 0) begin
                        counter <= abs_b; // Initialize counter
                        result_reg <= a; // Start with base
                        local_state <= POS;
                    end else if (b < -8) begin
                        result_reg <= 32'hDEADBEEF; // Fractional results unsupported for large negative exponents
                        error <= 1;
                        done <= 1;
                        local_state <= DONE;
                    end else if (b < 0) begin
                        counter <= abs_b; // Initialize counter for positive power
                        result_reg <= a; // Start with base
                        local_state <= NEG;
                    end
                end
                POS: begin
                    if (counter > 1) begin
                        if (result_reg[M-1] == 1) begin
                            // Overflow occurs during multiplication
                            result_reg <= 32'hDEADBEEF;
                            error <= 1;
                            done <= 1;
                            local_state <= DONE;
                        end else begin
                            result_reg <= result_reg * a; // Multiply repeatedly
                            counter <= counter - 1;      // Decrement counter
                        end
                    end else begin
                        result_reg <= result_reg << 8; // chage to q16.8 format
                        done <= 1;
                        local_state <= DONE;         // Move to DONE state when finished
                    end
                end
                NEG: begin
                    if (counter > 1) begin
                        if (result_reg[M-1] == 1) begin
                            // Overflow occurs during multiplication
                            result_reg <= 32'hDEADBEEF;
                            error <= 1;
                            done <= 1;
                            local_state <= DONE;
                        end else begin
                            result_reg <= result_reg * a; // Multiply repeatedly
                            counter <= counter - 1;      // Decrement counter
                        end
                    end else begin
                        // Finished computing a ** abs(b), move to division
                        denominator <= result_reg << 8;
                        numerator <=  256; // Set numerator to 1 in Q16.8
                        div_start <= 1; // Start division
                        local_state <= DIV;
                    end
                end
                DIV: begin
                    if (div_done) begin
                        if (dbz) begin
                            // Handle divide-by-zero error
                            result_reg <= 32'hDEADBEEF;
                            error <= 1;
                        end else begin
                            if (div_valid)
                                result_reg <= o_div; // Get division result
                            else begin
                                result_reg <= 32'hDEADBEEF;
                                error <= 1;
                            end
                            div_start <= 0; // Clear start signal
                            done <= 1;
                            local_state <= DONE;
                        end
                    end
                end
                DONE: begin
                    local_state <= IDLE;                   
                end
            endcase
        end
    end
endmodule