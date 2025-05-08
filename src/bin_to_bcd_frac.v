module bin_to_bcd_frac
  #(parameter FRACTIONAL_BITS = 8,           // Number of fractional bits
    parameter DECIMAL_DIGITS = 7)           // Number of decimal digits to extract
  (
   input                         CLK,   // Clock signal
   input                         RST,     // Reset signal (active high)
   input                         i_ce,   // Start signal
   input [FRACTIONAL_BITS-1:0]   i_bin,  // Fractional part as binary input
   output [DECIMAL_DIGITS*4-1:0] o_bcd,     // BCD output for fractional part
   output                        done       // Data Valid signal
   );

  // State Machine Parameters
  localparam IDLE    = 2'b00,
             CALC    = 2'b01,
             DONE    = 2'b10;

  // Registers
  reg [1:0] r_SM_Main = IDLE;                   // State machine register
  reg [DECIMAL_DIGITS*4-1:0] r_BCD = 0;           // BCD result
  reg [FRACTIONAL_BITS-1:0] r_Fraction = 0;       // Fractional input being processed
  reg [FRACTIONAL_BITS+3:0] r_Work = 0;           // Temporary register for scaled value
  reg [3:0] r_Digit = 0;                          // Current decimal digit
  reg [7:0] r_Loop_Count = 0;                     // Loop counter
  reg r_DV = 1'b0;                                // Data valid signal

  // Output Assignments
  assign o_bcd = r_BCD;
  assign done = r_DV;

  // Main State Machine
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      // Reset all registers
      r_SM_Main <= IDLE;
      r_BCD <= 0;
      r_Fraction <= 0;
      r_Work <= 0;
      r_Digit <= 0;
      r_Loop_Count <= 0;
      r_DV <= 1'b0;
    end else begin
      case (r_SM_Main)

        // Idle State: Wait for Start Signal
        IDLE: begin
          r_DV <= 1'b0;
          r_BCD <= 0;
          r_Loop_Count <= 0;
          if (i_ce) begin
            r_Fraction <= i_bin; // Load fractional input
            r_Work <= 0;
            r_SM_Main <= CALC;
          end
        end

        // Calculation State: Extract Decimal Digits
        CALC: begin
          // Multiply the fractional part by 10
          r_Work = r_Fraction * 10;

          // Extract the Most Significant Digit (MSD)
          r_Digit = r_Work[FRACTIONAL_BITS +: 4];  // Extract upper bits

          // Store the MSD in the BCD output
          r_BCD[((DECIMAL_DIGITS - 1 - r_Loop_Count) * 4) +: 4] <= r_Digit;

          // Remove the MSD from the fractional value (keep the remainder)
          r_Fraction = r_Work[FRACTIONAL_BITS-1:0];

          // Increment the loop counter
          r_Loop_Count <= r_Loop_Count + 1;

          // Check if all decimal digits have been extracted OR if remaining fraction is zero
          if ((r_Loop_Count == DECIMAL_DIGITS - 1) || (r_Fraction == 0)) begin
            r_SM_Main <= DONE;
          end
        end

        // Done State: Signal that Output is Valid
        DONE: begin
          r_DV <= 1'b1;
          r_SM_Main <= IDLE; // Return to idle state
        end

        default: r_SM_Main <= IDLE;

      endcase
    end
  end

endmodule