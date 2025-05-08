`timescale 1ns / 1ps
`include "define.v"

module calculator (
    CLK_in, RST_in, run, error, led_active, led_code,
    sw12, sw11, sw10, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1, sw0,
    but0, but1, but2, stage_led, sign_led, state_led
);

   input CLK_in, RST_in, run;
   input sw12, sw11, sw10, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1, sw0;
   input but2, but1, but0;
   output [2:0] state_led;
   output error;
   output sign_led;
   output [3:0] led_active;
   output [7:0] led_code;
   output [3:0] stage_led;
   
   wire [`INPUTWIDTH-1:0] a, b;
   wire [2:0] state;
   wire [3:0] opcode;
   wire calc, display, inputed, input_error, calc_error; 
   wire [3:0] led_active_bus, input_led_active, output_led_active;
   wire [7:0] led_code_bus, input_led_code, output_led_code;
   wire [23:0] result;

   // Debouncer Signals
   wire dbc_but0, dbc_but1, dbc_but2; // Debounced signal from debouncer
   
   // Instantiate the debouncer for `but0`
   debouncer  debouncer0 ( // 5 ms debounce time @ 100MHz
       .clk(CLK_in),
       .pb_1(but0),
       .pb_out(dbc_but0),
       .but_led()
   );
   
      // Instantiate the debouncer for `but0`
   debouncer  debouncer1 ( // 5 ms debounce time @ 100MHz
       .clk(CLK_in),
       .pb_1(but1),
       .pb_out(dbc_but1),
       .but_led()
   );
   
      // Instantiate the debouncer for `but0`
   debouncer  debouncer2 ( // 5 ms debounce time @ 100MHz
       .clk(CLK_in),
       .pb_1(but2),
       .pb_out(dbc_but2),
       .but_led()
);

   // Assign active LEDs based on state
   assign led_active = (state == `EXECA) ? input_led_active : 
                    (state == `DISPLAY) ? output_led_active : 
                    4'b0000; // Default to 0

   assign led_code = (state == `EXECA) ? input_led_code : 
                  (state == `DISPLAY) ? output_led_code : 
                  8'b1111_1111; // Default to 0
   
   assign error = (state == `EXECA) ? input_error :
                  calc_error;
   
   // State Module
   state state0 (
        .CLK(CLK_in), 
        .RST(RST_in), 
        .run(run), 
        .inputed(inputed), 
        .calc(calc), 
        .display(display), 
        .state(state)
   );
   
   assign state_led = state;
   
   // Input Module
   input_module input0 (
        .CLK(CLK_in),
        .RST(RST_in),
        .state(state),
        .but0(but0),
        .but1(but1),
        .but2(but2),
        .sw12(sw12), .sw11(sw11), .sw10(sw10), .sw9(sw9), .sw8(sw8), 
        .sw7(sw7), .sw6(sw6), .sw5(sw5), .sw4(sw4), .sw3(sw3), 
        .sw2(sw2), .sw1(sw1), .sw0(sw0),
        .led_active(input_led_active), .led_code(input_led_code),    
        .sign_led(sign_led),  
        .a(a),
        .b(b),
        .error_led(input_error),
        .opcode(opcode),
        .done(inputed)
   );

   // Arithmetic Module
   arithmetic arithmetic0 (
        .CLK(CLK_in), 
        .RST(RST_in), 
        .a(a), .b(b), 
        .state(state), 
        .opcode(opcode), 
        .result(result), 
        .done(calc),
        .error(calc_error)
    );
    
    // Display Module
    display display0 (
        .CLK(CLK_in),
        .RST(RST_in),
        .i_val(result),
        .but0(dbc_but0),
        .error(error),
        .state(state),
        .opcode(opcode),
        .led_active(output_led_active),
        .led_code(output_led_code),
        .done(display),
        .stage_led(stage_led)
    );

endmodule