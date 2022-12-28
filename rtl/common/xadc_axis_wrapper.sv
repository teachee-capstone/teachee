`default_nettype none
`timescale 1ns / 1ps

// PLAN: Wrap DRP interface to an axis interface
// One axis source will provide current samples and a second will do voltage
// Each will be 16 bits in width
// Must start thinking about channel selection

module xadc_axis_wrapper (
    // Xilinx XADC IP Interface (Only putting through the required signals)
    input wire logic xadc_dclk,
    input wire logic xadc_reset,

    // Current Monitor Channel
    input wire logic vauxp4,
    input wire logic vauxn4,

    // Voltage ADC channel
    input wire logic vauxp12,
    input wire logic vauxn12,

    // ADC Channel AXI Streams
    axis_io.Source current_monitor_channel,
    axis_io.Source voltage_channel
);

    xadc_drp_addr_t xadc_daddr;
    var logic xadc_den;
    wire logic xadc_drdy;
    wire logic[15:0] xadc_do;
    wire logic xadc_eos;
endmodule
`default_nettype wire