module blink(
    output led,
    output TEACHEE_LED0,
    output TEACHEE_LED1,
    input btn,
    input sysclk
    );
    
    reg led_state = 0;
    reg[31:0] counter = 0;
    assign led = btn;
    
    always @(posedge sysclk) begin
        counter <= counter + 1;
        if (counter == 6000000) begin
            led_state <= ~led_state;
            counter <= 0;
        end
    end   
    assign TEACHEE_LED0 = led_state;
    assign TEACHEE_LED1 = ~led_state; 
endmodule