`timescale 1ns / 1ps

module bin_to_bcd_frac_tb;

  // Parameters
  parameter FRACTIONAL_BITS = 8;          // Number of fractional bits
  parameter DECIMAL_DIGITS = 7;           // Number of decimal digits to extract

  // Testbench Signals
  reg                     r_Clock = 0;   // Clock signal
  reg                     r_Start = 0;   // Start signal
  reg [FRACTIONAL_BITS-1:0] r_Binary = 0;  // Fractional binary input
  wire [DECIMAL_DIGITS*4-1:0] w_BCD;      // BCD output
  wire                    w_DV;          // Data valid signal

  // Clock Generation
  always #5 r_Clock = ~r_Clock; // 10ns clock period

  // Instantiate the bin_to_bcd_fractional module
  bin_to_bcd_frac
    #(.FRACTIONAL_BITS(FRACTIONAL_BITS),
      .DECIMAL_DIGITS(DECIMAL_DIGITS))
    uut (
      .i_Clock(r_Clock),
      .i_Start(r_Start),
      .i_Binary(r_Binary),
      .o_BCD(w_BCD),
      .o_DV(w_DV)
    );

  // Test Procedure
  initial begin
    // Test Case 1: Fractional value 0.625 (160 in Q8 format)
    r_Binary = 8'b10100000; // 0.625 in Q16.8 format
    r_Start = 1;
//    @(posedge r_Clock); // Wait for a clock edge
//    r_Start = 0;

    // Wait for the module to finish processing
    wait(w_DV == 1);
    r_Start = 0;
    #20;
    $display("Test Case 1: Input = 0.625 (Binary: %b), BCD Output = %b", r_Binary, w_BCD);

    // Test Case 2: Fractional value 0.5 (128 in Q8 format)
    r_Binary = 8'b10000000; // 0.5 in Q16.8 format
    r_Start = 1;

    wait(w_DV == 1);
    r_Start = 0;
    #20;
    $display("Test Case 2: Input = 0.5 (Binary: %b), BCD Output = %b", r_Binary, w_BCD);

    // Test Case 3: Fractional value 0.375 (96 in Q8 format)
    r_Binary = 8'b01100000; // 0.375 in Q16.8 format
    r_Start = 1;

    wait(w_DV == 1);
    r_Start = 0;
    #20;
    $display("Test Case 3: Input = 0.375 (Binary: %b), BCD Output = %b", r_Binary, w_BCD);

    // Test Case 4: Fractional value 0.1 (26 in Q8 format)
    r_Binary = 8'b00011010; // 0.1 in Q16.8 format
    r_Start = 1;

    wait(w_DV == 1);
    r_Start = 0;
    #20;
    $display("Test Case 4: Input = 0.1 (Binary: %b), BCD Output = %b", r_Binary, w_BCD);

    // Finish Simulation
    $finish;
  end

endmodule