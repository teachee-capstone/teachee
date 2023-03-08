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
        HSADC_COLLECT,
        HSADC_AXIS_STORE,
        HSADC_IDLE
    } hsadc_axis_wrapper_state_t;

    hsadc_axis_wrapper_state_t state = HSADC_INIT;

    axis_interface #(
        .DATA_WIDTH(16)
    ) hsadc_axis (
        .clk(sample_clk),
        .rst(reset)
    );

    axis_async_fifo_wrapper #(
        .DEPTH(256),
        .DATA_WIDTH(16),
        .KEEP_ENABLE(0)
    ) hsadc_sample_fifo (
        .sink(hsadc_axis.Sink),
        .source(sample_stream)
    );

    // mirror channel A encode signal onto channel B so we can get data from
    // each aligned at the same time.
    assign hsadc_ctrl_signals.channel_b_enc = hsadc_ctrl_signals.channel_a_enc;

    var logic [31:0] cycle_counter = 0;
    always_ff @(posedge sample_clk) begin
        case (state)
            HSADC_INIT: begin
                // Set the ADC into data alignment mode between channel A and B
                hsadc_ctrl_signals.s1 <= 1;
                hsadc_ctrl_signals.s2 <= 0;

                // Two's comp output format
                hsadc_ctrl_signals.dfs <= 1;

                // Configure encode pins
                hsadc_ctrl_signals.channel_a_enc <= 0;

                // Start awaiting data
                state <= HSADC_COLLECT;
            end
            HSADC_COLLECT: begin
                // effective sampling at 1 MSPS
                // Only count to 8 instead of 10 since two cycles are spent storing
                if (cycle_counter == 8) begin
                    cycle_counter <= 0;
                    hsadc_ctrl_signals.channel_a_enc <= 1;
                    state <= HSADC_IDLE;
                end else begin
                    cycle_counter <= cycle_counter + 1;
                end
            end
            HSADC_IDLE: begin
                // immediately drop the clock back low
                hsadc_ctrl_signals.channel_a_enc <= 0;

                // load up data to be sent into the FIFO
                hsadc_axis.tdata[15:8] <= hsadc_ctrl_signals.channel_a;
                hsadc_axis.tdata[7:0] <= hsadc_ctrl_signals.channel_b;
                hsadc_axis.tvalid <= 1;

                // transition to AXIS Store
                state <= HSADC_AXIS_STORE;
            end
            HSADC_AXIS_STORE: begin
                if (hsadc_axis.tvalid && hsadc_axis.tready) begin
                    hsadc_axis.tvalid <= 0;

                    // transition back into collection state
                    state <= HSADC_COLLECT;
                end
            end
        endcase
        // DATA COLLECTION FSM HERE
        // GOAL: get data from both chanA and chanB. Store in a single 16 bit FIFO
        // Also Remember to scale sample clk to an effective 1MHz sample rate
    end

    // Set default values for the unused AXIS signals
    always_comb begin
        hsadc_axis.tlast = 1;
        hsadc_axis.tkeep = '1;
        hsadc_axis.tid = '0;
        hsadc_axis.tuser = '0;
        hsadc_axis.tdest = '0;
    end
endmodule

`default_nettype none

