`default_nettype none
`timescale 1ns / 1ps

module pll_blink (
    output var logic TEACHEE_LED0,
    output var logic TEACHEE_LED1,
    input var logic cmod_osc
);

    var logic sys_clk;
    var logic locked;

    pll_100 pll_example_100 (
        // Clock out ports
        .sys_clk(sys_clk),     // output sys_clk
        // Status and control signals
        .reset(0), // input reset
        .locked(locked),       // output locked
        // Clock in ports
        .cmod_osc(cmod_osc)      // input osc_in
    );

    var logic[31:0] counter = 0;
    always_ff @(posedge sys_clk) begin
        if (locked) begin
            counter <= counter + 1;
            if (counter == 100_000_000) begin
                counter <= 0;
                TEACHEE_LED0 <= ~TEACHEE_LED0;
                TEACHEE_LED1 <= ~TEACHEE_LED1;
            end
        end else begin
            TEACHEE_LED0 <= 0;
            TEACHEE_LED1 <= 0;
        end
    end

endmodule

`default_nettype wire
