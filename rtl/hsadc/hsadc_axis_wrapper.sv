`default_nettype none
`timescale 1ns / 1ps

/*

This module will consume samples from both channels of the highspeed ADC and
output a single 16-bit AXI stream. This stream can then be compressed into a
byte stream using some of the other existing utilities in the repository for
stream manipulation.

 */

module hsadc_axis_wrapper (
    input var logic sample_clk,
    input var logic stream_clk,

    hsadc_interface hsadc_ctrl_signals,
    axis_interface.Source sample_stream
);
    // sample clock to control the ADC.
    // output side of the async fifo will use the stream clock provided to the module
endmodule

`default_nettype none
