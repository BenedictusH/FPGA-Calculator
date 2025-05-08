`timescale 1ns / 1ps

module exp #(
    parameter N = 12,          // Input width (Q12.0 format)
    parameter M = 24,          // Output width (Q16.8 fixed-point)
    parameter W = 24,          // Working width (Q16.8 for division)
    parameter ITERATIONS = 20, // Number of iterations for CORDIC
    parameter I_FRAC = 8       // Fractional bits for the output
) (
    input signed [N-1:0] i_val, // Input value (Q12.0 format)
    input CLK,                  // Clock signal
    input RST,                  // Reset signal
    input i_ce,                 // Clock enable signal
    output reg [M-1:0] o_exp,        // Output value (Q16.8 fixed-point)
    output reg done,                 // Done signal
    output error                 // Error signal
);

    // ** Constants **
    localparam [W-1:0] LN_2 = 12'sd177; // ln(2) in Q16.8 (ln(2) ? 0.693147 × 2^8)
    localparam signed [W-1:0] MIN_VAL = -12'sd5 << I_FRAC; // -5 in Q16.8
    localparam signed [W-1:0] MAX_VAL = 12'sd10 << I_FRAC;  // 10 in Q16.8

    // ** Internal Signals **
    reg signed [W-1:0] x_scaled;        // i_val converted to Q16.8
    reg signed [W-1:0] r;               // Remainder in Q16.8
    reg signed [15:0] q;                // Integer q
    reg signed [W-1:0] exp_r;           // exp(r) result in Q16.8
    wire [M-1:0] cordic_exp_out;        // Output of cordic_exp module
    wire cordic_done;                   // Done signal from cordic_exp module
    reg start_cordic;                   // Start signal for cordic_exp module
    reg error_reg;
        
    // Division module signals
    reg start_div;                      // Start signal for division
    wire div_busy;                      // Busy signal from division
    wire div_done;                      // Done signal from division
    wire div_valid;                     // Valid division signal
    wire signed [W-1:0] div_result;     // Output result of division

    // FSM states
    reg [3:0] local_state;

    // FSM local_states
    localparam IDLE  = 4'd0;
    localparam CHECK_BOUNDS = 4'd1;
    localparam DECOMPOSE = 4'd2;
    localparam DIVISION = 4'd3;
    localparam COMPUTE_EXP_R = 4'd4;
    localparam CALCULATE_RESULT = 4'd5;
    localparam FINISH = 4'd6;

    // ** Cordic_exp Module Instantiation **
    cordic_exp cordic_exp_inst (
        .i_val(r[N-1:0]),     // Pass `r` in Q12.0 (top N bits of r)
        .CLK(CLK),
        .RST(RST),
        .i_ce(start_cordic),
        .o_exp(cordic_exp_out), // exp(r) result
        .done(cordic_done),
        .error()                // Unused error output
    );

    // ** Division Module Instantiation **
    division div_inst (
        .CLK(CLK),
        .RST(RST),
        .start(start_div),
        .busy(div_busy),
        .done(div_done),
        .valid(div_valid),
        .dbz(div_dbz),
        .a(x_scaled),         // Dividend
        .b(LN_2),             // Divisor (ln(2))
        .o_val(div_result)    // Quotient (q)
    );

    // ** FSM Logic **
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            local_state <= IDLE;
            done <= 0;
            error_reg <= 0;
            o_exp <= 0;
            start_cordic <= 0;
            start_div <= 0;
        end else if (i_ce) begin
            case (local_state)
                IDLE: begin
                    done <= 0;
                    error_reg <= 0;
                    start_cordic <= 0;
                    start_div <= 0;

                    // Convert i_val (Q12.0) to Q16.8
                    x_scaled <= i_val <<< I_FRAC; // Shift left by 8 to convert Q12.0 to Q16.8
                    local_state <= CHECK_BOUNDS;
                end

                CHECK_BOUNDS: begin
                    // Check if the input is within the valid range [-5, 10] in Q12.0
                    if (i_val == 0) begin
                        o_exp <= 1 << I_FRAC;
                        local_state <= FINISH;
                    end else if (x_scaled > MIN_VAL && x_scaled < MAX_VAL) begin
                        local_state <= DECOMPOSE;
                    end else begin
                        error_reg <= 1; // Out of bounds: raise error signal
                        local_state <= FINISH;
                    end
                end

                DECOMPOSE: begin
                    // Start division to calculate q
                    start_div <= 1;
                    local_state <= DIVISION;
                end

                DIVISION: begin
                    if (div_done) begin
                        start_div <= 0;

                        if (!div_valid) begin
                            error_reg <= 1; // Divide by zero error
                            local_state <= FINISH;
                        end else begin
                            q = div_result[W-1:I_FRAC];    // Integer part of division
                            r = x_scaled - (q * LN_2);     // Remainder: r = x - q * ln(2)
                            local_state <= COMPUTE_EXP_R;
                        end
                    end
                end

                COMPUTE_EXP_R: begin
                    // Start cordic_exp computation for exp(r)
                    start_cordic = 1;  
                    if (cordic_done) begin
                        exp_r <= cordic_exp_out; // Result in Q16.8
                        start_cordic = 0;
                        local_state <= CALCULATE_RESULT;
                    end
                end

                CALCULATE_RESULT: begin
                    // Compute the final result: 2^q × exp(r)
                    if (q >= 0) begin
                        o_exp <= (exp_r <<< q) & ((1 << M) - 1); // Saturate to M bits
                    end else begin
                        o_exp <= exp_r >>> -q; // Divide by 2^-q
                    end
                    done <= 1;
                    local_state <= FINISH;
                end

                FINISH: begin
                    done <= 1; // Signal that computation is complete
                    local_state <= IDLE;
                end
            endcase
        end
    end

assign error = error_reg;
endmodule