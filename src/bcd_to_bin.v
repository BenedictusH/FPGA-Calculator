`timescale 1ns / 1ps
`include "define.v"

// BCD to binary converter, 12-bit output, 3 digits
module bcd_to_bin #(parameter N = `INPUTWIDTH)(
    input [3:0] hundreds, tens, ones, // BCD inputs
    input CLK, RST,                   // Clock and Reset
    input is_signed,                  // Signed mode enable
    input a, b,
    input i_ce,                       // Clock enable
    output reg [N-1:0] o_bin_a, o_bin_b   // Binary output
);

    reg signed [N-1:0] result_reg;           // Final converted result register
    reg signed [N-1:0] temp_result;          // Temporary result before applying sign
    reg [3:0] temp_hundreds, temp_tens, temp_ones;

    always @(posedge CLK) begin
        if (RST) begin
            result_reg <= 0;
            temp_result <= 0;
            temp_hundreds <= 0;
            temp_tens <= 0;
            temp_ones <= 0;
        end else if (i_ce) begin
            // Convert hundreds, tens, and ones BCD digits to binary
            case (hundreds)
                4'h0: temp_hundreds <= 4'd0;
                4'h1: temp_hundreds <= 4'd1;
                4'h2: temp_hundreds <= 4'd2;
                4'h3: temp_hundreds <= 4'd3;
                4'h4: temp_hundreds <= 4'd4;
                4'h5: temp_hundreds <= 4'd5;
                4'h6: temp_hundreds <= 4'd6;
                4'h7: temp_hundreds <= 4'd7;
                4'h8: temp_hundreds <= 4'd8;
                4'h9: temp_hundreds <= 4'd9;
            endcase      

            case (tens)
                4'h0: temp_tens <= 4'd0;
                4'h1: temp_tens <= 4'd1;
                4'h2: temp_tens <= 4'd2;
                4'h3: temp_tens <= 4'd3;
                4'h4: temp_tens <= 4'd4;
                4'h5: temp_tens <= 4'd5;
                4'h6: temp_tens <= 4'd6;
                4'h7: temp_tens <= 4'd7;
                4'h8: temp_tens <= 4'd8;
                4'h9: temp_tens <= 4'd9;
            endcase   

            case (ones)
                4'h0: temp_ones <= 4'd0;
                4'h1: temp_ones <= 4'd1;
                4'h2: temp_ones <= 4'd2;
                4'h3: temp_ones <= 4'd3;
                4'h4: temp_ones <= 4'd4;
                4'h5: temp_ones <= 4'd5;
                4'h6: temp_ones <= 4'd6;
                4'h7: temp_ones <= 4'd7;
                4'h8: temp_ones <= 4'd8;
                4'h9: temp_ones <= 4'd9;
            endcase

            // Calculate the binary equivalent of the BCD value
            temp_result = (temp_hundreds * 8'd100) + (temp_tens * 8'd10) + temp_ones;
            
            // Apply signed logic
            if (is_signed) begin
                result_reg = ~temp_result + 1; // Two's complement
            end else begin
                result_reg = temp_result;
            end
        end
    end

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            o_bin_a <= 0; // Reset `o_bin_a` to 0
            o_bin_b <= 0; // Reset `o_bin_b` to 0
        end else if (i_ce) begin
            if (a) begin
                o_bin_a <= result_reg; // Drive `o_bin_a` when `a` is high
            end
    
            if (b) begin
                o_bin_b <= result_reg; // Drive `o_bin_b` when `b` is high
            end
        end
    end
    
endmodule
