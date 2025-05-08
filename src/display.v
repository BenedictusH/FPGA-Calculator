`timescale 1ns / 1ps
`include "define.v"

// bcd width 15 * 4 1 sign 14 data
module display # (parameter M = `OUTPUTWIDTH, parameter I_FRAC = 8, parameter BCD_WIDTH = 60)(
        input CLK, RST,
        input [M-1:0] i_val,
        input error,
        input but0,
        input [2:0] state,
        input [3:0] opcode,
        output [3:0] led_active,
        output [7:0] led_code,
        output [3:0] stage_led,
        output reg done
    );
            
    // Registers for bin_to_bcd conv
    wire bcd_conv_done;
    reg start_rtb;
    reg [I_FRAC-1:0] i_frac;
    wire [BCD_WIDTH-1:0] final_bcd; // Grab 7 significant figures
    wire is_signed, is_fixed;
    
    res_to_bcd rtb (
        .CLK(CLK),
        .RST(RST),
        .i_val(i_val),
        .i_ce(start_rtb),
        .opcode(opcode),
        .o_bcd(final_bcd),
        .is_fixed(is_fixed),
        .is_signed(is_signed),
        .done(bcd_conv_done)
    );
    
    // register for led_out 
    reg start_led_out;
    wire [3:0] digit_stages;
    wire [4:0] write_bram_addr;
    wire [7:0] bram_data;
    wire led_out_done, bram_we; 
    
    led_out bcd_to_led (
        .CLK(CLK), 
        .RST(RST),
        .i_ce(start_led_out),
        .is_signed(is_signed), 
        .is_fixed(is_fixed),
        .final_bcd(final_bcd),
        .stages(digit_stages),
        .bram_addr(write_bram_addr),     // BRAM address for writing
        .bram_data(bram_data),     // BRAM data for writing (LED code)
        .bram_we(bram_we),         // BRAM write enable
        .done(led_out_done)        // Done signal when conversion is complete
    );
    
    // BRAM module instantiation
    wire en_read, CLK_LED;
    wire [4:0] read_bram_addr;
    wire [7:0] o_bram_data;
    
    blk_mem_gen_0 bram0 (
        .clka(CLK),             // Clock for BRAM
        .wea(bram_we),          // Write enable signal from led_out
        .addra(write_bram_addr),      // Address signal from led_out
        .dina(bram_data),       // Data input signal from led_out (LED codes
        .clkb(CLK_LED),
        .addrb(read_bram_addr),
        .doutb(led_code),   // Data output from BRAM (if needed elsewhere)
        .enb(en_read)    
    );
    
    // instantiate led_clk counter
    reg start_led_clk;
    
    
    display_led ctrl_led (
        .CLK(CLK), 
        .RST(RST),
        // TODO: might need to change refersh logic counter based on clk_in, also might need to abstract this module to a highter module
        // TODO: add input logic which controls digit segment being shown
        .but0(but0),
        .bram_data(o_bram_data),
        .digit_stages(digit_stages),
        .i_ce(start_led_clk),
        .CLK_LED(CLK_LED),
        .en_read(en_read),
        .read_addr(read_bram_addr),
        .led_active(led_active),
        .led_code(led_code),
        .stage_led(stage_led)
    );
    
    
    // Local parameters for states
    localparam IDLE    = 3'h0,
               BCD   = 3'h1, // New state for input preprocessing
               LED = 3'h2,
               DISPLAY = 3'h3;
    
    // Local processing registers
    reg [2:0] local_state; 

    
    // Initialize local state to IDLE
    initial local_state = IDLE;
    
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            // Reset all registers to their initial values
            local_state <= IDLE;
            done <= 0;
        end else begin
            case (local_state)
           
           // IDLE state: Truly idle, waiting for the `state` to transition
           IDLE: begin
                 done <= 0; // Ensure done is cleared
                 if (state == `EXECC) begin
                     local_state <= BCD; // Move to INPUT state
                     start_rtb <= 1;
                 end
           end
           
           BCD: begin
                if (bcd_conv_done) begin
                    start_rtb <= 0;
                    start_led_out <= 1;
                    local_state <= LED;
                end
           end
           
           LED: begin
                if (led_out_done) begin
                    local_state <= DISPLAY;
                    start_led_out <= 0;
                end
           end
           
           DISPLAY: begin
                start_led_clk <= 1;
                done <= 1;
           end
           
           default: local_state <= IDLE;
           endcase
        end
    end
endmodule