`timescale 1ns / 1ps
`include "define.v"

module division #(
    parameter WIDTH = `OUTPUTWIDTH,  // width of numbers in bits (integer and fractional)
    parameter FBITS = 8  // fractional bits within WIDTH
)(
    input wire CLK,    // clock
    input wire RST,    // reset
    input wire start,  // start calculation
    output reg busy,   // calculation in progress
    output reg done,   // calculation is complete (high for one tick)
    output reg valid,  // result is valid
    output reg dbz,    // divide by zero
    input wire signed [WIDTH-1:0] a,  // dividend (numerator)
    input wire signed [WIDTH-1:0] b,  // divisor (denominator)
    output reg signed [WIDTH-1:0] o_val // result value: quotient
);

    // Local parameters
    localparam WIDTHU = WIDTH - 1;                 // Unsigned width (1 bit narrower)
    localparam FBITSW = (FBITS == 0) ? 1 : FBITS;  // Avoid negative vector width when FBITS=0
    localparam SMALLEST = {1'b1, {WIDTHU{1'b0}}};  // Smallest negative number
    localparam ITER = WIDTHU + FBITS;              // Iteration count: unsigned input width + fractional bits

    // Internal registers and wires
    reg [WIDTHU-1:0] au, bu;           // Absolute versions of inputs (unsigned)
    reg [WIDTHU-1:0] quo, quo_next;    // Intermediate quotients (unsigned)
    reg [WIDTHU:0] acc, acc_next;      // Accumulator (unsigned but 1 bit wider)
    reg [4:0] i;            // Iteration counter (allow ITER+1 iterations for rounding)
    reg a_sig, b_sig, sig_diff;        // Signs of inputs and whether they differ

    // State machine states
    localparam IDLE = 3'b000,
               INIT = 3'b001,
               CALC = 3'b010,
               ROUND = 3'b011,
               SIGN = 3'b100,
               DELAY= 3'b101;

    reg [2:0] state; // Current state

    // Input signs
    always @(*) begin
        a_sig = a[WIDTH-1];
        b_sig = b[WIDTH-1];
    end

    // Division algorithm iteration
    always @(*) begin
        if (acc >= {1'b0, bu}) begin
            acc_next = acc - bu;
            {acc_next, quo_next} = {acc_next[WIDTHU-1:0], quo, 1'b1};
        end else begin
            {acc_next, quo_next} = {acc, quo} << 1;
        end
    end

    // Calculation state machine
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            // Reset state
            state <= IDLE;
            busy <= 0;
            done <= 0;
            valid <= 0;
            dbz <= 0;
            o_val <= 0;
        end else begin
            // Default values
            done <= 0;

            case (state)
                IDLE: begin
                    if (start) begin
                        valid <= 0;
                        if (b == 0) begin
                            // Divide by zero
                            state <= IDLE;
                            busy <= 0;
                            done <= 1;
                            dbz <= 1;
                        end else if (a == SMALLEST || b == SMALLEST) begin
                            // Overflow
                            state <= IDLE;
                            busy <= 0;
                            done <= 1;
                            dbz <= 0;
                        end else if (a == 0) begin
                            state <= DELAY;
                            done <= 1;
                            dbz <= 0;
                            busy <= 0;
                            valid <= 1;
                            o_val <= 24'b0;
                        end else begin
                            // Initialize
                            state <= INIT;
                            au <= (a_sig) ? -a[WIDTHU-1:0] : a[WIDTHU-1:0];  // Register abs(a)
                            bu <= (b_sig) ? -b[WIDTHU-1:0] : b[WIDTHU-1:0];  // Register abs(b)
                            sig_diff <= a_sig ^ b_sig;  // Register input sign difference
                            busy <= 1;
                            dbz <= 0;
                        end
                    end
                end

                INIT: begin
                    state <= CALC;
                    i <= 0;
                    {acc, quo} <= {{WIDTHU{1'b0}}, au, 1'b0};  // Initialize calculation
                end

                CALC: begin
                    if (i == WIDTHU-1 && quo_next[WIDTHU-1:WIDTHU-FBITSW] != 0) begin
                        // Overflow
                        state <= IDLE;
                        busy <= 0;
                        done <= 1;
                    end else begin
                        if (i == ITER-1) state <= SIGN;  // Calculation complete after next iteration
                        i <= i + 1;
                        acc <= acc_next;
                        quo <= quo_next;
                    end
                end

                SIGN: begin
                    // Adjust quotient sign if non-zero and input signs differ
                    state <= DELAY;
                    if (quo != 0) o_val <= (sig_diff) ? {1'b1, -quo} : {1'b0, quo};
                    busy <= 0;
                    done <= 1;
                    valid <= 1;
                end
                
                DELAY: begin
                    state <= IDLE; // add a 1 clock cycle delay so can other components can read
                    done <= 1;
                    valid <= 1;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule