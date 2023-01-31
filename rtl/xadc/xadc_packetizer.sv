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

    // shared clock abbreviated for simplicity
    var logic clk;
    assign clk = voltage_channel.clk;

    typedef enum int {
        XADC_PACKETIZER_INIT,
        XADC_PACKETIZER_LOAD_NEW_SAMPLES,
        XADC_PACKETIZER_SEND_VOLTAGE_UPPER,
        XADC_PACKETIZER_SEND_VOLTAGE_LOWER,
        XADC_PACKETIZER_SEND_CURRENT_UPPER,
        XADC_PACKETIZER_SEND_CURRENT_LOWER
    } xadc_packetizer_state_t;

    xadc_packetizer_state_t state = XADC_PACKETIZER_INIT;

    axis_interface #(
        .DATA_WIDTH(8)
    ) raw_stream (
        .clk(clk),
        .rst(voltage_channel.rst || current_monitor_channel.rst)
    );

    cobs_encode_wrapper cobs_encoder (
        .raw_stream(raw_stream.Sink),
        .encoded_stream(packet_stream)
    );

    // Declare upper and lower byte for voltage / current
    var logic[7:0] voltage_upper;
    var logic[7:0] voltage_lower;

    var logic[7:0] current_upper;
    var logic[7:0] current_lower;

    always_ff @(posedge clk) begin
        case (state)
            XADC_PACKETIZER_INIT: begin
                // init raw_stream signals to default states
                raw_stream.tlast <= 0;
                raw_stream.tkeep <= 1;
                raw_stream.tid <= 0;
                raw_stream.tuser <= 0;
                raw_stream.tdest <= 0;

                voltage_channel.tready <= 0;
                current_monitor_channel.tready <= 0;

                raw_stream.tvalid <= 0;

                // Tell the input streams we are ready to intake bytes

                if (voltage_channel.tvalid && current_monitor_channel.tvalid) begin
                    // Wait until we have valid data before starting a load
                    voltage_channel.tready <= 1;
                    current_monitor_channel.tready <= 1;

                    state <= XADC_PACKETIZER_LOAD_NEW_SAMPLES;
                end
            end
            XADC_PACKETIZER_LOAD_NEW_SAMPLES: begin
                // Wait until there is both voltage and current data available
                // Then build a packet
                if (voltage_channel.tready && voltage_channel.tvalid && current_monitor_channel.tready && current_monitor_channel.tvalid) begin
                    // load the registers with the sample data
                    voltage_upper <= voltage_channel.tdata[15:8];
                    voltage_lower <= voltage_channel.tdata[7:0];

                    current_upper <= current_monitor_channel.tdata[15:8];
                    current_lower <= current_monitor_channel.tdata[7:0];

                    // The samples are only 12 bits so we are going to abuse the
                    // upper 4 bits to serve as packet header

                    // load the packet header into voltager_upper
                    // voltage_upper[15:12] <= XADC_PACKET_HEADER_LOW_SPEED_SAMPLE;

                    // Disable the tready signal and proceed to the next state
                    voltage_channel.tready <= 0;
                    current_monitor_channel.tready <= 0;

                    // enable tvalid to stream the data into raw_stream
                    raw_stream.tvalid <= 1;

                    // Note that we can't just use voltage_upper yet due to async assign
                    raw_stream.tdata <= voltage_channel.tdata[15:8]; // Note this includes the header
                    
                    state <= XADC_PACKETIZER_SEND_VOLTAGE_UPPER;
                end
            end
            XADC_PACKETIZER_SEND_VOLTAGE_UPPER: begin
                if (raw_stream.tvalid && raw_stream.tready) begin
                    // await tready to ensure the voltage upper is written and proceed to the next state
                    
                    raw_stream.tdata <= voltage_lower;
                    state <= XADC_PACKETIZER_SEND_VOLTAGE_LOWER;
                end
            end
            XADC_PACKETIZER_SEND_VOLTAGE_LOWER: begin
                if (raw_stream.tvalid && raw_stream.tready) begin
                    // after sending lower voltage, transition and send current data
                    raw_stream.tdata <= current_upper;
                    state <= XADC_PACKETIZER_SEND_CURRENT_UPPER;
                end
            end
            XADC_PACKETIZER_SEND_CURRENT_UPPER: begin
                // NEED TO HANDLE UPPER CURRENT CASE HERE
                if (raw_stream.tvalid && raw_stream.tready) begin
                    // load stream data with current lower byte and transition out of the state
                    raw_stream.tdata <= current_lower;

                    // flag to cobs encoder that this is the last byte of the packet
                    raw_stream.tlast <= 1;
                    state <= XADC_PACKETIZER_SEND_CURRENT_LOWER;
                end
            end
            XADC_PACKETIZER_SEND_CURRENT_LOWER: begin
                raw_stream.tvalid <= 0;

                // indicate that we are no longer ready for data from the current and voltage stream
                voltage_channel.tready <= 0;
                current_monitor_channel.tready <= 0;

                state <= XADC_PACKETIZER_INIT;
            end
        endcase
    end
endmodule

`default_nettype none
