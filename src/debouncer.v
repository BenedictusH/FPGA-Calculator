module debouncer (input pb_1,clk,output pb_out, but_led);
    wire slow_clk_en;
    wire Q1,Q2,Q2_bar,Q0;
    clock_enable u1(clk,slow_clk_en);
    my_dff_en d0(clk,slow_clk_en,pb_1,Q0);
    
    my_dff_en d1(clk,slow_clk_en,Q0,Q1);
    my_dff_en d2(clk,slow_clk_en,Q1,Q2);
    assign Q2_bar = ~Q2;
    assign pb_out = Q1 & Q2_bar;
    assign button_led = slow_clk_en ? 1 : 0;
endmodule

// Slow clock enable for debouncing button 
module clock_enable(input Clk_100M,output slow_clk_en);
    reg [17:0]counter=0;
    always @(posedge Clk_100M)
    begin
       counter <= (counter>=17'hffff)?0:counter+1;
    end
    assign slow_clk_en = (counter == 17'hffff)?1'b1:1'b0;
endmodule

// D-flip-flop with clock enable signal for debouncing module 
module my_dff_en(input DFF_CLOCK, clock_enable,D, output reg Q=0);
    always @ (posedge DFF_CLOCK) begin
  if(clock_enable==1) 
           Q <= D;
    end
endmodule 