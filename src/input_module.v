`timescale 1ns / 1ps
`include "define.v"

// sw and but are named left to right
module input_module #(parameter N = `INPUTWIDTH)(
    input CLK,
    input RST,
    input [2:0] state,
    input but2, but1, but0, // middle button in the cross shape
    input sw12, sw11, sw10, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1, sw0, // 11 swich for critical path which is number of operations , sw0 for sign
    output signed [N-1:0] a,b,
    output [3:0] led_active, 
    output [7:0] led_code,
    output reg error_led,
    output reg sign_led,
    output reg [3:0] opcode,
    output reg done
    );
    
    localparam IDLE = 3'd1, INPUT_A = 3'd2, OPERATION = 3'd3, CHECK_OPCODE = 3'd4, INPUT_B = 3'd5, DONE = 3'd6;
    reg [2:0]  local_state;
    
    // reg and wires for decoder
    reg start_btb, is_a, is_b;
    wire is_signed; 
    wire signed [N-1:0] input_a, input_b;
    reg [3:0] hundreds, tens, ones;
    
    assign is_signed = sw0;// sw0 controls the sign
    assign a = input_a, b = input_b;
    
    bcd_to_bin btb (
        .hundreds(hundreds), 
        .tens(tens), 
        .ones(ones),
        .CLK(CLK), 
        .RST(RST),
        .a(is_a),
        .b(is_b),
        .is_signed(is_signed),
        .i_ce(start_btb),
        .o_bin_a(input_a),
        .o_bin_b(input_b)
    );
    
    reg start_led_out;
    wire [11:0] bcd_bus = {hundreds, tens, ones};
    
    input_led_out display_led (
        .CLK(CLK), 
        .RST(RST),
        .i_ce(start_led_out),
        .i_bcd(bcd_bus),
        .led_active(led_active),
        .led_code(led_code)  
    );
    
    initial begin
        local_state = IDLE;
    end
    
    // registers
    reg [3:0] display_bus;
    reg [11:0] op_bus;
    reg op_code_error;
    reg [11:0] bcd_display;
    
    always @(posedge CLK or posedge but0 or posedge RST) begin
        if (RST) begin
            local_state <= IDLE;
            start_btb <= 0;
            is_a <= 0;
            is_b <= 0;
            done <= 0;
            op_code_error <= 0;
            start_led_out <= 0;
            opcode <=  `NULL; // Clear opcode
            hundreds <= 0;
            tens <= 0;
            ones <= 0;
            op_bus <= 0; // Reset operation bus
        end else begin
        error_led <= op_code_error;
        sign_led <= is_signed;    
        
            case (local_state)
                IDLE: begin
                    done <= 0;
                    if (state == `EXECA) begin
                        local_state <= INPUT_A;
                        start_btb <= 1;
                        is_a <= 1;
                        start_led_out <= 1;
                    end    
                end
                INPUT_A: begin   
                    bcd_display <= {sw12, sw11, sw10, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1};                 
                    // assign switches to input bus of bin_to_bcd
                    hundreds <= {sw12, sw11, sw10, sw9}; 
                    tens <= {sw8, sw7, sw6, sw5};
                    ones <= {sw4, sw3, sw2, sw1}; 
                        
                    if (but2) begin
                        local_state <= OPERATION;
                        start_btb <= 0;
                        is_a <= 0;
                        start_led_out <= 0;
                        bcd_display <= 0;
                    end
                end
                    
                OPERATION: begin
                    op_bus <= {sw12, sw11, sw10, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1};
                
                    case (op_bus)
                        12'b1000_0000_0000: begin // sw12
                             op_code_error <= 0;
                             opcode <= `SUM;
                        end
                        12'b0100_0000_0000: begin // sw11
                            op_code_error <= 0;
                            opcode <= `SUB;
                        end
                        12'b0010_0000_0000: begin  // sw10
                            op_code_error <= 0;
                            opcode <= `DIV;
                        end
                        12'b0001_0000_0000: begin // sw9
                            op_code_error <= 0;
                            opcode <= `MUL;
                        end    
                        12'b0000_1000_0000: begin // sw8
                            op_code_error <= 0;
                            opcode <= `SQRT;
                        end
                        12'b0000_0100_0000: begin // sw7
                            op_code_error <= 0;
                            opcode <= `POW;
                        end
                        12'b0000_0010_0000: begin // sw 6
                            op_code_error <= 0;
                            opcode <= `LOG;
                        end
                        12'b0000_0001_0000: begin 
                            opcode <= `EXP;
                            op_code_error <= 0;
                        end
                        12'b0000_0000_1000: begin 
                            op_code_error <= 0;
                            opcode <= `SIN;
                        end
                        12'b0000_0000_0100: begin 
                            op_code_error <= 0;
                            opcode <= `COS;
                        end
                        12'b0000_0000_0010: begin 
                            op_code_error <= 0;
                            opcode <= `TAN;
                        end
                        default: op_code_error <= 1;// handle invalid input 
                     endcase
                     
                     if (but1) begin
                        local_state <= CHECK_OPCODE;
                     end                     
                end
                
                CHECK_OPCODE: begin
                    if (op_code_error) local_state <= OPERATION;
                    else begin
                        op_code_error <= 0;
                        if (opcode == `SQRT || opcode == `EXP || opcode == `SIN || opcode == `COS || opcode == `TAN) begin
                            // no need B
                            local_state <= IDLE;
                            start_btb <= 0;
                            is_b <= 0;
                            done <= 1;
                            start_led_out <= 0;
                        end else begin
                            local_state <= INPUT_B;
                            start_btb <= 1;
                            is_b <= 1;
                            start_led_out <= 1;
                        end 
                    end
                end
                
                INPUT_B: begin   
                    bcd_display <= {sw12, sw11, sw10, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1};                 
                                 
                    hundreds <= {sw12, sw11, sw10, sw9}; 
                    tens <= {sw8, sw7, sw6, sw5};
                    ones <= {sw4, sw3, sw2, sw1}; 
                        
                    if (but0) begin
                        local_state <= DONE;
                        start_btb <= 0;
                        is_b <= 0;
                        bcd_display <= 0;
                        done <= 1;
                        start_led_out <= 0;
                    end
                end
                
                DONE: local_state <= IDLE;
                default: local_state <= IDLE;                      
            endcase
        end 
    end
endmodule