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
    input var logic reset,

    hsadc_interface hsadc_ctrl_signals,
    axis_interface.Source sample_stream
);
    typedef enum int {
        HSADC_INIT,
        HSADC_COLLECT_AND_STORE,
        HSADC_IDLE
    } hsadc_axis_wrapper_state_t;

    hsadc_axis_wrapper_state_t state = HSADC_INIT;

    axis_interface #(
        .DATA_WIDTH(16)
    ) hsadc_axis (
        .clk(sample_clk),
        .rst(reset),
    );

    axis_async_fifo_wrapper #(
        .DEPTH(256),
        .DATA_WIDTH(16),
        .KEEP_ENABLE(0)
    ) hsadc_sample_fifo (
        .sink(hsadc_axis),
        .source(sample_stream)
    );

    var logic [31:0] cycle_counter = 0;
    always_ff @(posedge sample_clk) begin
        case (state)
            HSADC_INIT: begin
                // Set the ADC into data alignment mode between channel A and B
                hsadc_ctrl_signals.s1 <= 1;
                hsadc_ctrl_signals.s2 <= 1;

                // Two's comp output format
                hsadc_ctrl_signals.dfs <= 1;
            end
        endcase
        // DATA COLLECTION FSM HERE
        // GOAL: get data from both chanA and chanB. Store in a single 16 bit FIFO
        // Also Remember to scale sample clk to an effective 1MHz sample rate
    end
    // sample clock to control the ADC.
    // output side of the async fifo will use the stream clock provided to the module
endmodule

`default_nettype none
