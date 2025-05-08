`timescale 1ns / 1ps
`include "define.v"

module log # (parameter N = `INPUTWIDTH, parameter M = `OUTPUTWIDTH, parameter W = 24, parameter D = 4)(
    input CLK, RST,
    input signed [N-1:0] a, b,
    input [2:0] state,
    input [3:0] opcode,
    output [M-1:0] o_log,
    output done,
    output error
    );

reg done_reg, error_reg; 
reg [M-1:0] res_reg;   

// wires for cordic ln component
wire i_ce, ln_a_done, ln_b_done;    
wire signed [M-1:0] o_ln_m_a, o_ln_m_b; // signed q7.16

// reg to connect to cordic module (signed for consistency sake)
reg signed [N-1:0] in_a, in_b; 
reg i_ce_log;

cordic_log ln_a_component (
    .CLK(CLK),
    .RST(RST),
    .i_val(in_a), // value should be in q4.8
    .i_ce(i_ce_log),
    .o_ln(o_ln_m_a),
    .done(ln_a_done)
);

cordic_log ln_b_component (
    .CLK(CLK),
    .RST(RST),
    .i_val(in_b), // value should be in q4.8
    .i_ce(i_ce_log),
    .o_ln(o_ln_m_b),
    .done(ln_b_done)
);

// wires for division operations
reg signed [W-1:0] ln_a_trunc, ln_b_trunc;       // truncated inputs to signed q16.8
wire div_done, div_valid, dbz;
wire [M-1:0] o_div;
reg div_start;

division div_component (
    .CLK(CLK),
    .RST(RST),
    .start(div_start),
    .done(div_done),
    .valid(div_valid),
    .dbz(dbz),
    .a(ln_b_trunc),
    .b(ln_a_trunc),
    .o_val(o_div)
);

// registers for a and b M and E
reg [W-1:0] m_a, m_b;
reg [W-1:0] e_a, e_b;


// Intermediate signal for calculations
reg [4:0] msb_pos_a, msb_pos_b; // Can hold values from 0 to 31 (log?(32) = 5)
reg [W-1:0] e_ln2_a, e_ln2_b;
reg [W-1:0] ln_a, ln_b;
reg signed [W-1:0] div_result;  // Division result in Q8.32

// constants
reg [M-1:0] ln2 = 24'd177; // q 16.8

assign i_ce = state == `EXECB && opcode == `LOG;

// pre processing stuff thats should be done every clk cycle
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        msb_pos_a = 0;
        msb_pos_b = 0;
    end else begin
        if (a[11]) msb_pos_a = 11;
        else if (a[10]) msb_pos_a = 10;
        else if (a[9]) msb_pos_a = 9;
        else if (a[8]) msb_pos_a = 8;
        else if (a[7]) msb_pos_a = 7;
        else if (a[6]) msb_pos_a = 6;
        else if (a[5]) msb_pos_a = 5;
        else if (a[4]) msb_pos_a = 4;
        else if (a[3]) msb_pos_a = 3;
        else if (a[2]) msb_pos_a = 2;
        else if (a[1]) msb_pos_a = 1;
        else if (a[0]) msb_pos_a = 0;
        
        if (b[11]) msb_pos_b = 11;
        else if (b[10]) msb_pos_b = 10;
        else if (b[9]) msb_pos_b = 9;
        else if (b[8]) msb_pos_b = 8;
        else if (b[7]) msb_pos_b = 7;
        else if (b[6]) msb_pos_b = 6;
        else if (b[5]) msb_pos_b = 5;
        else if (b[4]) msb_pos_b = 4;
        else if (b[3]) msb_pos_b = 3;
        else if (b[2]) msb_pos_b = 2;
        else if (b[1]) msb_pos_b = 1;
        else if (b[0]) msb_pos_b = 0;        
    end
end

// State machine states
localparam IDLE = 3'b000,
           INIT = 3'b001,
           CALC_LN = 3'b010,
           DIV = 3'b011,
           DELAY= 3'b100;
           
reg [2:0] local_state; // Current local_state

// input handling, get e and m for b 
always @(posedge CLK or posedge RST) begin
    if (RST) begin
         local_state <= `IDLE;
         error_reg <= 0;
         done_reg <= 0;
         res_reg <= 0;
         i_ce_log <= 0;
         div_start <= 0;
    end else begin
        done_reg <= 0; // default value
        error_reg <= 0;
        
        case (local_state)
            IDLE: begin
                if (i_ce) begin
                    if (a <= 0 || b <= 0) begin
                         error_reg <= 1;
                         done_reg <= 1;
                         res_reg <= 0;
                    end else local_state <= INIT;      
                end
            end
            INIT: begin
                // Normalize the mantissa
                m_a = a << (12 - msb_pos_a);
                in_a = m_a >> 4;
                
                m_b = b << (12 - msb_pos_b);
                in_b = m_b >> 4;
                
                i_ce_log <= 1;
                
                local_state <= CALC_LN;
            end
            CALC_LN: begin
                // Compute the exponent (MSB position)
                e_a <= msb_pos_a << 8; // Q16.8
                e_ln2_a <= e_a * ln2; // q16.8 * q16.8 => signed Q8.16 
                
                e_b <= msb_pos_b << 8; // Q16.8
                e_ln2_b <= e_b * ln2; // q16.8 * q16.8 => signed Q8.16 
                
                // cordic ln component logic
                if (ln_a_done && ln_b_done) begin
                    ln_a = e_ln2_a + o_ln_m_a; // o_ln_m_a signed q8.16
                    ln_b = e_ln2_b + o_ln_m_b; // o_ln_m_b signed q8.16
                    
                    ln_a_trunc = ln_a >>> 8;
                    ln_b_trunc = ln_b >>> 8;
                    
                    div_start <= 1;
                    local_state <= DIV;
                end
            end
            DIV: begin
                if (div_done) begin
                    if (div_valid) res_reg <= o_div; // div output in signed q16.8
                    else begin
                        res_reg <= 32'hDEADBEEF;
                        error_reg <= 1;
                    end
                    
                    done_reg <= 1;
                    local_state <= DELAY;
                end                
            end
            DELAY: begin // add 1 clock cycle delay so other components can catch value
                done_reg <= 1;
                error_reg <= div_valid ? 0 : 1;
                
                local_state <= IDLE;
            end  
        endcase        
    end
end

assign done = done_reg;
assign error  = error_reg;
assign o_log = res_reg;
    
endmodule
