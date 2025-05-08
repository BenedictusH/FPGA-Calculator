module bin_to_bcd
  #(parameter INPUT_WIDTH = 24,
    parameter DECIMAL_DIGITS = 7)
  (
   input                            CLK,
   input                            RST,         // Reset signal (active high)
   input signed [INPUT_WIDTH-1:0]   i_bin,
   input                            i_ce,
   output [DECIMAL_DIGITS*4-1:0]    o_bcd,
   output                           done
   );
   
  localparam s_IDLE              = 3'b000,
             s_SHIFT             = 3'b001,
             s_CHECK_SHIFT_INDEX = 3'b010,
             s_ADD               = 3'b011,
             s_CHECK_DIGIT_INDEX = 3'b100,
             s_BCD_DONE          = 3'b101;
   
  reg [2:0] r_SM_Main = s_IDLE;
   
  // The vector that contains the output BCD
  reg [DECIMAL_DIGITS*4-1:0] r_BCD = 0;
    
  // The vector that contains the input binary value being shifted.
  reg [INPUT_WIDTH-1:0]      r_Binary = 0;
      
  // Keeps track of which Decimal Digit we are indexing
  reg [DECIMAL_DIGITS-1:0]   r_Digit_Index = 0;
    
  // Keeps track of which loop iteration we are on.
  // Number of loops performed = INPUT_WIDTH
  reg [7:0]                  r_Loop_Count = 0;
 
  wire [3:0]                 w_BCD_Digit;
  reg                        r_DV = 1'b0;                       
    
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      // Reset all registers to their default values
      r_SM_Main      <= s_IDLE;
      r_BCD          <= 0;
      r_Binary       <= 0;
      r_Digit_Index  <= 0;
      r_Loop_Count   <= 0;
      r_DV           <= 1'b0;
    end else begin
      case (r_SM_Main) 
  
        // Stay in this state until i_ce comes along
        s_IDLE :
          begin
            r_DV <= 1'b0;
            r_Binary = 0;
             
            if (i_ce == 1'b1) begin
              r_Binary  <= i_bin;
              r_SM_Main <= s_SHIFT;
              r_BCD     <= 0;
            end else begin
              r_SM_Main <= s_IDLE;
            end
          end
                 
  
        // Always shift the BCD Vector until we have shifted all bits through
        // Shift the most significant bit of r_Binary into r_BCD lowest bit.
        s_SHIFT :
          begin
            r_BCD     <= r_BCD << 1;
            r_BCD[0]  <= r_Binary[INPUT_WIDTH-1];
            r_Binary  <= r_Binary << 1;
            r_SM_Main <= s_CHECK_SHIFT_INDEX;
          end          
         
  
        // Check if we are done with shifting in r_Binary vector
        s_CHECK_SHIFT_INDEX :
          begin
            if (r_Loop_Count == INPUT_WIDTH-1) begin
              r_Loop_Count <= 0;
              r_SM_Main    <= s_BCD_DONE;
            end else begin
              r_Loop_Count <= r_Loop_Count + 1;
              r_SM_Main    <= s_ADD; 
            end 
          end
          
         // Break down each BCD Digit individually. Check them one-by-one to 
         // see if they are greater than 4. If they are, increment by 3. 
         // Put the result back into r_BCD Vector.            
        s_ADD : begin
            if (w_BCD_Digit > 4) begin                                         
              r_BCD[(r_Digit_Index*4)+:4] <= w_BCD_Digit + 3;  
            end
             
            r_SM_Main <= s_CHECK_DIGIT_INDEX; 
          end       
         
         
        // Check if we are done incrementing all of the BCD Digits
        s_CHECK_DIGIT_INDEX :
          begin
            if (r_Digit_Index == DECIMAL_DIGITS-1) begin
              r_Digit_Index <= 0;
              r_SM_Main     <= s_SHIFT;
            end else begin
              r_Digit_Index <= r_Digit_Index + 1;
              r_SM_Main     <= s_ADD;
            end
          end
  
        s_BCD_DONE :
          begin
            r_DV      <= 1'b1;
            r_SM_Main <= s_IDLE;
          end
         
         
        default :
          r_SM_Main <= s_IDLE;
            
      endcase
    end
  end // always @ (posedge CLK or posedge RST)  
 
   
  assign w_BCD_Digit = r_BCD[r_Digit_Index*4 +: 4];
       
  assign o_bcd = r_BCD;
  assign done  = r_DV;
      
endmodule // Binary_to_bcd