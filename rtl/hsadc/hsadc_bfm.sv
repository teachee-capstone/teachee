`default_nettype none
`timescale 1ns / 1ps

module hsadc_bfm (
    hsadc_interface hsadc_ctrl_signals
);
    var logic [7:0] counter = 0;
    always_ff @(posedge hsadc_ctrl_signals.channel_a_enc) begin
        hsadc_ctrl_signals.channel_a <= counter;
        hsadc_ctrl_signals.channel_b <= counter;

        counter <= counter + 1;
    end
endmodule

`default_nettype none

