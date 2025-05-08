`timescale 1ns / 1ps

module input_led_out(
        input CLK, RST,
        input i_ce,
        input [11:0] i_bcd, // 12-bit BCD input (3 digits)
        output reg [3:0] led_active, // Active LED signal (active low)
        output reg [7:0] led_code    // 8-bit LED code for 7-segment display
    );
    
    localparam IDLE = 1'b0, DISPLAY = 1'b1;
    reg local_state;
    
    wire CLK_LED; // Clock signal for driving LEDs
    
    // LED clock generator instantiation
    led_clk led_clk1 (
        .CLK_100MHz(CLK),
        .RST(RST),
        .i_ce(i_ce),
        .CLK_LED(CLK_LED)
    );
    
    reg [1:0] led_active_counter; // Counter to track active LED (2 bits for 4 LEDs)
    
    // LED code lookup table (function to map BCD digits to 7-segment LED codes)
    function [7:0] digit_to_led;
        input [3:0] digit;
        case (digit)
            4'h0: digit_to_led = 8'b0000_0011; // LED code for '0'
            4'h1: digit_to_led = 8'b1001_1111; // LED code for '1'
            4'h2: digit_to_led = 8'b0010_0101; // LED code for '2'
            4'h3: digit_to_led = 8'b0000_1101; // LED code for '3'
            4'h4: digit_to_led = 8'b1001_1001; // LED code for '4'
            4'h5: digit_to_led = 8'b0100_1001; // LED code for '5'
            4'h6: digit_to_led = 8'b0100_0001; // LED code for '6'
            4'h7: digit_to_led = 8'b0001_1111; // LED code for '7'
            4'h8: digit_to_led = 8'b0000_0001; // LED code for '8'
            4'h9: digit_to_led = 8'b0000_1001; // LED code for '9'
            4'hF: digit_to_led = 8'b1111_1101; // LED code for '-'
            default: digit_to_led = 8'b1111_1111; // Default LED code (blank)
        endcase
    endfunction
    
    always @(posedge CLK_LED or posedge RST) begin
        if (RST) begin
            // Reset all states and signals
            local_state <= IDLE;
            led_active_counter <= 0;
            led_active <= 4'b1111; // All LEDs off (active low)
            led_code <= 8'b1111_1111; // Blank LED code
        end else begin
            case (local_state)
                IDLE: begin
                    if (i_ce) 
                        local_state <= DISPLAY;
                end
                
                DISPLAY: begin
                    // Logic for driving the corresponding LED based on led_active_counter
                    case (led_active_counter)
                        2'b00: begin
                            led_active <= 4'b0111; // Activate LED 0 (active low)
                            led_code <= digit_to_led(i_bcd[11:8]); // Encode the first BCD digit
                        end
                        2'b01: begin
                            led_active <= 4'b1011; // Activate LED 1 (active low)
                            led_code <= digit_to_led(i_bcd[7:4]); // Encode the second BCD digit
                        end
                        2'b10: begin
                            led_active <= 4'b1101; // Activate LED 2 (active low)
                            led_code <= digit_to_led(i_bcd[3:0]); // Encode the third BCD digit
                        end
                        2'b11: begin
                            led_active <= 4'b1110; // Activate LED 3 (active low)
                            led_code <= 8'b1111_1111; // Blank (if unused)
                        end
                        default: begin
                            led_active <= 4'b1111; // All LEDs off (should not occur)
                            led_code <= 8'b1111_1111; // Blank LED code
                        end
                    endcase
                    
                    // Increment the counter for the next LED
                    led_active_counter <= led_active_counter + 1;
                end
            endcase
        end
    end    
endmodule