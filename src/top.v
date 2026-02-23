// Solana PoH verifier

module top (
    input  wire clk,        // 27 MHz clock input
    output wire [5:0] led   // 6 LED outputs
);

    // Counter for timing
    // 27MHz / 27M = 1 Hz blink rate
    reg [24:0] counter = 0;
    
    // LED pattern register
    reg [5:0] led_pattern = 6'b000001;
    
    // Counter logic
    always @(posedge clk) begin
        counter <= counter + 1;
        
        // Every ~0.5 seconds, shift LED pattern
        if (counter == 25'd13_500_000) begin
            counter <= 0;
            // Rotate pattern left with wrap
            led_pattern <= {led_pattern[4:0], led_pattern[5]};
        end
    end
    
    // Output assignment
    assign led = ~led_pattern;

endmodule