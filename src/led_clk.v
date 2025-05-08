`timescale 1ns / 1ps

// CLK divider for controlling seven segment display
module led_clk(
    input CLK_100MHz,
    input RST,
    input i_ce,
    output reg CLK_LED
    );
    
    localparam SIM = 1;
    localparam CW = SIM ? 2 : 17;
    
    reg [CW-1:0] refresh_counter; // Counter for CLK_LED generation
    
        // Generate CLK_LED signal using the refresh counter
    always @(posedge CLK_100MHz or posedge RST) begin
        if (RST) begin
            refresh_counter <= 0;
            CLK_LED <= 0;
        end else if (i_ce) begin
            if (refresh_counter == 2'hfffff) begin // Simulation: Small counter for testing
                refresh_counter <= 0;
                CLK_LED <= ~CLK_LED; // Toggle CLK_LED
            end else begin
                refresh_counter <= refresh_counter + 1;
            end
        end
    end
endmodule
