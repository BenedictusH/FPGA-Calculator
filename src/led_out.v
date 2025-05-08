`timescale 1ns / 1ps
`include "define.v"

// this component should only write to mem the led out signals in order 
module led_out # (parameter M = `OUTPUTWIDTH, parameter I_FRAC = 8, parameter BCD_WIDTH = 60)(
        input CLK, RST,
        input i_ce,
        input is_signed, is_fixed,
        input [BCD_WIDTH-1:0] final_bcd,
        output reg [4:0] bram_addr,     // BRAM address for writing
        output reg [7:0] bram_data,     // BRAM data for writing (LED code)
        output reg bram_we,             // BRAM write enable
        output reg [3:0] stages,            // led stages to display values
        output reg done                 // Done signal when conversion is complete
    );
       
    reg [59:0] bcd_reg;             // Register to hold the BCD input
    reg [3:0] digit;                // Current digit being processed
    reg signed [4:0] msd_index =  5'd14;   // Index of the most significant digit
    reg [7:0] led_code_reg;         // intermediary reg led code if needed, mostly for adding decimal point
    integer i;                      // Loop variable
    reg [1:0] stage_counter; 

    // LED code lookup table (example: 7-segment codes for digits 0-9)
    function [7:0] digit_to_led;
        input [3:0] digit;
        case (digit)
            // high meanns segement off
            4'h0: digit_to_led = 8'b0000_0011; // LED code for '0' (hex: 0x03)
            4'h1: digit_to_led = 8'b1001_1111; // LED code for '1' (hex: 0x9F)
            4'h2: digit_to_led = 8'b0010_0101; // LED code for '2' (hex: 0x25)
            4'h3: digit_to_led = 8'b0000_1101; // LED code for '3' (hex: 0x0D)
            4'h4: digit_to_led = 8'b1001_1001; // LED code for '4' (hex: 0x99)
            4'h5: digit_to_led = 8'b0100_1001; // LED code for '5' (hex: 0x49)
            4'h6: digit_to_led = 8'b0100_0001; // LED code for '6' (hex: 0x41)
            4'h7: digit_to_led = 8'b0001_1111; // LED code for '7' (hex: 0x1F)
            4'h8: digit_to_led = 8'b0000_0001; // LED code for '8' (hex: 0x01)
            4'h9: digit_to_led = 8'b0000_1001; // LED code for '9' (hex: 0x09)
            4'hF: digit_to_led = 8'b1111_1101; // LED code for negative sign '-' (hex: 0xFD)
            default: digit_to_led = 8'b1111_1111; // LED code for blank (hex: 0xFF)
        endcase
    endfunction

    localparam IDLE = 3'h0,
               DETECT_SIGN = 3'h1,
               FIND_MSD = 3'h2,
               DP_CHECK = 3'h3,
               CONV = 3'h4,
               DONE = 3'h5;
    
    reg [2:0] local_state;
    reg [3:0] digit_checked;
    
    initial local_state = IDLE; 
    
    // FSM logic
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            // Reset all signals and state
            local_state <= IDLE;
            stage_counter <= 0;
            stages <= 0;
            bram_addr <= 0;
            bram_data <= 0;
            bram_we <= 0;
            done <= 0;
            bcd_reg <= 0;
            msd_index <= 14;
        end else begin
            case (local_state)
                // IDLE: Wait for the i_ce signal
                IDLE: begin
                    bram_we <= 0;
                    done <= 0;
                    if (i_ce) begin
                        bcd_reg <= final_bcd;       // Load the BCD input
                        bram_addr <= 0;            // Start writing from address 0
                        local_state <= DETECT_SIGN; // Move to DETECT_SIGN state
                    end
                end
    
                // DETECT_SIGN: Check for a sign and write its LED code to BRAM if present
                DETECT_SIGN: begin
                    bram_we <= 0;                  // Disable BRAM write by default
                    digit <= bcd_reg[BCD_WIDTH-1 -: 4]; // Extract the most significant nibble
                    if (is_signed) begin           // If the number is signed
                        bram_data <= digit_to_led(4'hF); // LED code for '-'
                        bram_we <= 1;              // Enable BRAM write
                        bram_addr <= bram_addr + 1; // Increment BRAM address
                    end
                    local_state <= FIND_MSD;       // Move to FIND_MSD state
                end
    
                // FIND_MSD: Find the first most significant digit
                FIND_MSD: begin
                    bram_we <= 0; // Disable BRAM write
                
                    if (msd_index >= 0) begin
                        // Check if the current digit is non-zero
                        if (bcd_reg[msd_index * 4 +: 4] != 4'h0) begin
                            local_state <= DP_CHECK; // Move to DP_CHECK state
                        end else begin
                            msd_index <= msd_index - 1; // Decrement msd_index to check the next most significant digit
                        end
                    end else begin
                        msd_index <= 0; // Set msd_index to 0
                        local_state <= DP_CHECK; // Proceed to DP_CHECK state
                    end
                end
    
                // DP_CHECK: Handle fixed-point decimal point logic
                DP_CHECK: begin
                    bram_we <= 0;                  // Disable BRAM write
                    if (is_fixed && msd_index < 7) begin // MSD is behind the fixed-point marker
                        led_code_reg = digit_to_led(4'h0); // LED code for '0'
                        led_code_reg[0] <= 0;      // Add a decimal point (dp)
                        bram_data <= led_code_reg;
                        bram_we <= 1;              // Enable BRAM write
                        bram_addr <= bram_addr + 1; // Increment BRAM address
                    end
                    local_state <= CONV;           // Move to CONV state
                end
    
                // Conversion State
                CONV: begin
                    bram_we <= 0; // Default: Disable BRAM write
                
                    // Process digits from msd_index down to 0
                    if ((is_fixed && msd_index >= 0) || (!is_fixed && msd_index >= 7)) begin
                        // Extract the current BCD digit
                        digit = bcd_reg[msd_index * 4 +: 4];
                    
                        // Convert the BCD digit to LED code
                        led_code_reg = digit_to_led(digit);
                    
                        // If the format is fixed-point, add a decimal point for `msd_index == 7`
                        if (is_fixed && msd_index == 7) begin
                            led_code_reg[0] = 0; // Add a decimal point (dp)
                        end
                    
                        // Write the LED code to BRAM
                        bram_data <= led_code_reg;  
                        bram_we <= 1;               // Enable BRAM write
                        bram_addr <= bram_addr + 1; // Increment BRAM address
                    
                        // Move to the next digit
                        msd_index <= msd_index - 1;
                    
                        // Increment stage counter every 4 digits written to BRAM
                        if (stage_counter == 2'b00) begin
                            stages <= stages + 1; // Increment stages
                        end
                        stage_counter <= stage_counter + 1;
                    
                    end else begin
                        // All digits have been processed, move to DONE state
                        bram_we <= 1;              // Disable BRAM write
                        bram_data <= 8'hEE;        // Arbitrary code to signify end of digits
                        bram_addr <= bram_addr + 1;
                    
                        done <= 1;                 // Signal that the operation is complete
                        local_state <= DONE;
                    end
                end
                
                // DONE: Indicate that the conversion is complete
                DONE: begin
                    bram_addr <= 0;
                    bram_data <= 0;
                    done <= 1;
                    bram_we <= 0;                  // Disable BRAM write
                    local_state <= IDLE;           // Return to IDLE state
                end
            endcase
        end
    end

endmodule
