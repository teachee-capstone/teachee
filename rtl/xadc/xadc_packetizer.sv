`default_nettype none
`timescale 1ns / 1ps
import xadc_drp_package::*;
import xadc_packet_package::*;

// This module will consume data from the XADC Channel FIFOs. The module will
// convert the two 16 bit streams into a single 8 bit stream. The 8 bit stream
// will contain header bytes to indicate what channel the sample is coming from.
// This stream will then be fed into a COBS encoder module which will feed the
// 8-bit USB fifo.

// packets will be 16 bits
// upper 4 bits are a header

module xadc_packetizer (
    // NOTE: this module expects that both input streams share a clock since
    // they come from the same XADC
    axis_interface.Sink voltage_channel,
    axis_interface.Sink current_monitor_channel,

    // Packet stream that can be sent to the encoder (COBS in this case)
    axis_interface.Source packet_stream
);

    typedef enum int {
        XADC_PACKETIZER_INIT,
        XADC_PACKETIZER_LOAD_UPPER_VOLTAGE_BYTE,
        XADC_PACKETIZER_LOAD_LOWER_VOLTAGE_BYTE,
        XADC_PACKETIZER_LOAD_UPPER_CURRENT_BYTE,
        XADC_PACKETIZER_LOAD_LOWER_CURRENT_BYTE,
        XADC_PACKETIZER_AWAIT_SAMPLES
    } xadc_packetizer_state_t;

    xadc_packetizer_state_t state = XADC_PACKETIZER_INIT;

    // Note: we are assuming that the voltage and current channel clocks are identical. Not an async module
    // Also, the XADC axis is already FIFO'd on one side so we will not repeat FIFO instances here

    always_ff @(posedge voltage_channel.clk) begin
        case (state)
            XADC_PACKETIZER_INIT: begin
                // Select who has data available and transition into the loading state.
                // if neither stream has data, await data instead
            end
        endcase
    end
endmodule

`default_nettype none
