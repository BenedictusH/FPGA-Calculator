`timescale 1ns / 1ps
`include "define.v"

// bcd width 15 * 4 1 sign 14 data
module res_to_bcd # (parameter M = `OUTPUTWIDTH, parameter I_FRAC = 8, parameter BCD_WIDTH = 60)(
        input CLK, RST,
        input [M-1:0] i_val,
        input i_ce,
        input [3:0] opcode,
        output reg [BCD_WIDTH-1:0] o_bcd,
        output reg is_fixed, is_signed,
        output reg done
    );
    
    // Local parameters for states
    localparam IDLE    = 3'h0,
               INPUT   = 3'h1, 
               CONVERT = 3'h2,
               DISPLAY = 3'h3,
               DONE    = 3'h4;
        
    // Registers for bin_to_bcd
    wire bcd_int_done;
    wire [7*4-1:0] o_bcd_int; // Max value 2^23 = 8388608, which is 7 digits long
    reg start_bcd_int;
    reg [M-1:0] i_int;
    
    bin_to_bcd btb (
        .CLK(CLK),
        .RST(RST),
        .i_bin(i_int),
        .i_ce(start_bcd_int),
        .o_bcd(o_bcd_int),
        .done(bcd_int_done)
    );
    
    // Registers for bin_to_bcd_frac
    wire bcd_frac_done;
    reg [I_FRAC-1:0] i_frac;
    wire [7*4-1:0] o_bcd_frac; // Grab 7 significant figures
    reg start_bcd_frac;
    bin_to_bcd_frac btbf (
        .CLK(CLK),
        .RST(RST),
        .i_bin(i_frac),
        .i_ce(start_bcd_frac),
        .o_bcd(o_bcd_frac),
        .done(bcd_frac_done)
    );

    // Local processing registers
    reg [2:0] local_state; 
    reg [M-1:0] unsigned_i;

    
    // Initialize local state to IDLE
    initial local_state = IDLE;
    
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            // Reset all registers to their initial values
            local_state <= IDLE;
            done <= 0;
            start_bcd_int <= 0;
            start_bcd_frac <= 0;
            is_signed <= 0;
            is_fixed <= 0;
            i_int <= 0;
            i_frac <= 0;
            unsigned_i <= 0;
            o_bcd <= 0;
        end else begin
            case (local_state)
           
           // IDLE state: Truly idle, waiting for the `state` to transition
           IDLE: begin
                 done <= 0; // Ensure done is cleared
                 start_bcd_int <= 0; // Ensure BCD conversion is disabled
                 start_bcd_frac <= 0;
                 if (i_ce) begin
                     local_state <= INPUT; // Move to INPUT state
                 end
           end
           
           // INPUT state: Preprocess the input
           INPUT: begin
                 // Check if the input is negative
                 if (i_val[M-1] == 1) begin
                    unsigned_i = ~i_val + 1; // Convert to unsigned (2's complement)
                    is_signed <= 1;
                 end else begin
                    unsigned_i = i_val; // Use the value directly
                    is_signed <= 0;
                 end
                 
                 // Determine if the input is fixed-point or integer
                 if (opcode == `SIN  || opcode == `COS || opcode == `TAN || 
                     opcode == `LOG  || opcode == `DIV || opcode == `EXP ||
                     opcode == `POW) begin
                    i_int <= unsigned_i[M-1:I_FRAC]; // Extract integer part
                    i_frac <= unsigned_i[I_FRAC-1:0]; // Extract fractional part
                    is_fixed <= 1; // Mark as fixed-point
                 end else begin
                    i_int <= unsigned_i; // Treat as a full integer
                    is_fixed <= 0; // Mark as integer
                 end
                 
                 local_state <= CONVERT; // Move to CONVERT state
                 
           end
           
           // CONVERT state: Perform BCD conversion
           CONVERT: begin
                // Set the 4 MSBs as the sign
                o_bcd[BCD_WIDTH-1 -: 4] <= (is_signed) ? 4'hF : 4'h0;
           
                if (is_fixed) begin
                     start_bcd_int = 1;
                     start_bcd_frac = 1;                    
                
                    if (bcd_int_done && bcd_frac_done) begin
                        o_bcd[BCD_WIDTH-5 -: 7*4] <= o_bcd_int; // Integer BCD
                        o_bcd[BCD_WIDTH-33 -: 7*4] <= o_bcd_frac; // Fractional BCD
                        
                        start_bcd_int = 0; // Stop BCD conversion
                        start_bcd_frac = 0;
                        
                        local_state <= DONE; // Move to DONE state   
                        done <= 1;                          
                    end
                end else begin
                     start_bcd_int = 1;

                    if (bcd_int_done) begin
                        o_bcd[BCD_WIDTH-5 -: 7*4] <= o_bcd_int; // Integer BCD
                        
                        start_bcd_int = 0; // Stop BCD conversion
                        local_state <= DONE; // Move to DONE state   
                        done <= 1; 
                    end    
                end                
           end
           
           // DONE state: just a delay of one clock cycle so other comoponents can read
           DONE: begin // this is state
                done <= 1; // Indicate the operation is complete
                local_state <= IDLE;   
           end
           default: local_state <= IDLE;
           endcase
        end
    end
endmodule