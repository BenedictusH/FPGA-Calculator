`timescale 1ns / 1ps

module display_led(
    input CLK, RST,
    input i_ce,
    input but0,                        // Button to toggle stage
    input [3:0] digit_stages,          // Total number of stages
    input [7:0] bram_data,           // Data from BRAM
    output [7:0] led_code,             // Output LED code
    output CLK_LED,                    // Clock signal for LEDs
    output reg en_read,                // Read enable signal
    output reg [4:0] read_addr,        // Address to read from BRAM
    output reg [3:0] led_active,        // Active low signal for 4 LEDs
    output [3:0] stage_led
);

//    // Instantiate clock divider for LED refresh rate
//    led_clk led_clk1 (
//        .CLK_100MHz(CLK),
//        .RST(RST),
//        .i_ce(i_ce),
//        .CLK_LED(CLK_LED)
//    );

//    reg [1:0] led_active_counter;      // Counter to track active LED
//    reg [3:0] internal_stage;          // Tracks current stage (1 to digit_stages)

//    // State machine states
//    localparam IDLE = 2'b00, READ = 2'b01;
//    reg [1:0] state;                   // Current state of the state machine

//    // Registers to track the address range based on internal_stage
//    reg [4:0] start_address;
//    reg [4:0] end_address;

//    // Button press handling
//    reg but0_prev;                     // Previous state of but0
//    wire but0_edge;                    // Detect rising edge of but0

//    assign but0_edge = but0 && !but0_prev;
//    assign stage_led = digit_stages - internal_stage + 1;

//    // Output the LED code from BRAM data
//    assign led_code = bram_data;

//    // Initialization
//    initial begin
//        en_read <= 0;
//        read_addr <= 0;
//        led_active <= 4'b1111;         // All LEDs off initially (active low)
//        led_active_counter <= 0;
//        state <= IDLE;                 // Start in IDLE state
//        internal_stage <= 1;           // Default to stage 1
//        start_address <= 5'b00000;     // Default start address for stage 1
//        end_address <= 5'b00011;       // Default end address for stage 1
//        but0_prev <= 0;
//    end

//    // State machine to control en_read, led_active, and read_addr
//    always @(posedge CLK_LED or posedge RST) begin
//        if (RST) begin
//            // Reset all signals and return to IDLE state
//            state <= IDLE;
//            en_read <= 0;
//            read_addr <= 0;
//            led_active <= 4'b1111;      // All LEDs off (active low)
//            led_active_counter <= 0;   // Start with the first LED
//            internal_stage <= 1;       // Reset to stage 1
//            start_address <= 5'b00000; // Reset start address for stage 1
//            end_address <= 5'b00011;   // Reset end address for stage 1
//            but0_prev <= 0;
//        end else begin
//            // State machine logic
//            case (state)
//                // IDLE: Wait for enable signal (i_ce) to begin reading
//                IDLE: begin
//                    if (i_ce) begin
//                        en_read <= 1'b1;          // Assert en_read for the first read
//                        read_addr <= start_address + 1; // Set read_addr to the start of the range
//                        state <= READ;           // Move to READ state
//                    end
//                end
                
//                // READ: Activate LEDs and continue cycling through reads
//                READ: begin
//                    en_read <= 1'b1;             // Assert en_read for the next read
                    
////                    // Handle button press for cycling stages
////                    if (but0) begin
////                        // Increment the internal stage and wrap around based on digit_stages
////                        if (internal_stage == digit_stages) begin
////                            internal_stage <= 1; // Wrap back to stage 1
////                        end else begin
////                            internal_stage <= internal_stage + 1; // Increment stage
////                        end
            
////                        // Update the address range based on the new internal_stage
////                        start_address <= (internal_stage - 1) * 4;
////                        end_address <= internal_stage * 4 - 1;
////                    end

//                    // Logic for driving the corresponding LED based on led_active_counter
//                    case (led_active_counter)
//                        2'b00: led_active <= 4'b0111; // Activate LED 0 (active low)
//                        2'b01: led_active <= 4'b1011; // Activate LED 1 (active low)
//                        2'b10: led_active <= 4'b1101; // Activate LED 2 (active low)
//                        2'b11: led_active <= 4'b1110; // Activate LED 3 (active low)
//                        default: led_active <= 4'b1111; // Default to all LEDs off
//                    endcase

//                    // Increment the led_active_counter to cycle through the LEDs
//                    led_active_counter <= led_active_counter + 1;

//                    // Increment read_addr and wrap around based on the current stage's range
//                    if (read_addr == end_address + 1 || read_addr < start_address) begin
//                        led_active_counter <= 0;
//                        read_addr <= start_address; // Wrap around to start of range
//                    end else begin
//                        read_addr <= read_addr + 1; // Increment the read address
//                    end

//                    // Stay in READ state unless reset
//                end

//                default: state <= IDLE; // Default to IDLE state for safety
//            endcase
//        end
//    end

    led_clk led_clk1 (
        .CLK_100MHz(CLK),
        .RST(RST),
        .i_ce(i_ce),
        .CLK_LED(CLK_LED)
    );
    
    reg [1:0] led_active_counter; // Counter to track active LED
    
    // State machine states
    localparam IDLE = 2'b00, READ = 2'b01;
    reg [1:0] state; // Current state of the state machine
    
    
    
    // Initialization
    initial begin
        en_read <= 0;
        read_addr <= 0;
        led_active <= 4'b1111; // All LEDs off initially (active low)
        led_active_counter <= 0;
        state <= IDLE; // Start in IDLE state
    end
    
    
    // State machine to control en_read, led_active, and read_addr
    always @(posedge CLK_LED or posedge RST) begin
        if (RST) begin
            // Reset all signals and return to IDLE state
            state <= IDLE;
            en_read <= 0;
            read_addr <= 0;
            led_active <= 4'b1111;      // All LEDs off (active low)
            led_active_counter <= 0;   // Start with the first LED
        end else begin
            case (state)
                // IDLE: Wait for enable signal (i_ce) to begin reading
                IDLE: begin
                    if (i_ce) begin
                        // start reading which would introduce a delay, making the mem_out sync with led_active
                        en_read <= 1'b1;        // Assert en_read for the first read
                        read_addr <= read_addr + 1; // Increment the read address
                        state <= READ;        // Move to DELAY state
                    end
                end
                
                // READ: Activate LEDs and continue cycling through reads
                READ: begin
                    en_read <= 1'b1;            // Assert en_read for the next read
                    read_addr <= read_addr + 1; // Increment the read address
                    
                    // Logic for driving the corresponding LED based on led_active_counter
                    case (led_active_counter)
                        2'b00: led_active <= 4'b0111; // Activate LED 0 (active low)
                        2'b01: led_active <= 4'b1011; // Activate LED 1 (active low)
                        2'b10: led_active <= 4'b1101; // Activate LED 2 (active low)
                        2'b11: led_active <= 4'b1110; // Activate LED 3 (active low)
                        default: led_active <= 4'b1111; // Should not occur, default to all LEDs off
                    endcase
    
                    // Increment the led_active_counter to cycle through the LEDs
                    led_active_counter <= led_active_counter + 1;
    
                    // Stay in READ state unless reset
                end
    
                default: state <= IDLE; // Default to IDLE state for safety
            endcase
        end
    end
endmodule