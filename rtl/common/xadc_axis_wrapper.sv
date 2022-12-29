`default_nettype none
`timescale 1ns / 1ps

import teachee_defs::*;

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

    typedef enum int {
        XADC_AXIS_INIT,
        XADC_AXIS_AWAIT_EOS,
        XADC_AXIS_START_DRP_VOLTAGE_READ,
        XADC_AXIS_AWAIT_VOLTAGE_DATA,
        XADC_AXIS_SEND_TO_VOLTAGE_FIFO,
        XADC_AXIS_START_DRP_CURRENT_READ,
        XADC_AXIS_AWAIT_CURRENT_DATA,
        XADC_AXIS_SEND_TO_CURRENT_FIFO
    } xadc_axis_state_t;

    // XADC Conversion and DRP Control Signals
    xadc_drp_addr_t xadc_daddr; // probably want to import this type through a package or something
    var logic xadc_den;
    wire logic xadc_drdy;
    wire logic[15:0] xadc_do;
    wire logic xadc_eos;

    // Define AXI Stream Interfaces
    // These interfaces will be tagged as sinks into the FIFO
    axis_io #(
        .DATA_WIDTH(16)
    ) xadc_current_axis (
        .clk(xadc_dclk),
        .rst(xadc_reset)
    );

    axis_io #(
        .DATA_WIDTH(16)
    ) xadc_voltage_axis (
        .clk(xadc_dclk),
        .rst(xadc_reset)
    );

    // Create Async FIFOs
    axis_async_fifo_wrapper #(
        .DEPTH(128),
        .DATA_WIDTH(16)
    ) xadc_current_fifo (
        .sink(xadc_current_axis.Sink),
        .source(current_monitor_channel)
    );

    axis_async_fifo_wrapper #(
        .DEPTH(128),
        .DATA_WIDTH(16)
    ) xadc_voltage_fifo (
        .sink(xadc_voltage_axis.Sink),
        .source(voltage_channel)
    );

    xadc_wiz_0 xadc_wiz_cmod_inst (
        // Clock and Reset
        .dclk_in(sys_clk),          // input wire dclk_in
        .reset_in(0),        // input wire reset_in

        // DRP interface
        .di_in(0),              // input wire [15 : 0] di_in
        .daddr_in(xadc_daddr),        // input wire [6 : 0] daddr_in
        .den_in(xadc_den),            // input wire den_in
        .dwe_in(0),            // input wire dwe_in
        .drdy_out(xadc_drdy),        // output wire drdy_out
        .do_out(xadc_do),            // output wire [15 : 0] do_out

        // Dedicated analog input channel (we do not use this)
        .vp_in(0),              // input wire vp_in
        .vn_in(0),              // input wire vn_in

        // analog input channels, vaux4 is pin 15 = VIOUT of current sensor
        // vaux12 is pin 16 = low speed voltage channel.
        .vauxp4(xa_p[0]),            // input wire vauxp4
        .vauxn4(xa_n[0]),            // input wire vauxn4
        .vauxp12(xa_p[1]),          // input wire vauxp12
        .vauxn12(xa_n[1]),          // input wire vauxn12

        // conversion status signals
        .channel_out(),  // output wire [4 : 0] channel_out
        .eoc_out(),          // output wire eoc_out
        .alarm_out(),      // output wire alarm_out
        .eos_out(xadc_eos),          // output wire eos_out
        .busy_out()        // output wire busy_out
    );

    always_ff @(posedge xadc_clk) begin
        case (state)
            XADC_AXIS_INIT: begin
                // Init both AXIS Sinks
                xadc_current_axis.tdata <= 0;
                xadc_current_axis.tvalid <= 0;

                xadc_voltage_axis.tdata <= 0;
                xadc_current_axis.tvalid <= 0;

                xadc_daddr <= XADC_DRP_ADDR_VOLTAGE_CHANNEL;
                xadc_den <= 0;

                state <= XADC_AXIS_AWAIT_EOS;
            end
            XADC_AXIS_AWAIT_EOS: begin
                if (xadc_eos) begin
                    xadc_den <= 1;

                    state <= XADC_AXIS_START_DRP_VOLTAGE_READ;
                end
            end
            XADC_AXIS_START_DRP_VOLTAGE_READ: begin
                xadc_den <= 0;

                state <= XADC_AXIS_AWAIT_VOLTAGE_DATA;
            end
            XADC_AXIS_AWAIT_VOLTAGE_DATA: begin
                if (xadc_drdy) begin
                    xadc_voltage_axis.tdata <= xadc_do;
                    xadc_voltage_axis.tvalid <= 1;

                    state <= XADC_AXIS_SEND_TO_VOLTAGE_FIFO;
                end 
            end
            XADC_AXIS_SEND_TO_VOLTAGE_FIFO: begin
                if (xadc_voltage_axis.tready && xadc_voltage_axis.tvalid) begin
                    xadc_voltage_axis.tvalid <= 0;
                    state <= XADC_AXIS_START_DRP_CURRENT_READ;
                end
            end
            XADC_AXIS_START_DRP_CURRENT_READ: begin
                xadc_daddr <= XADC_DRP_ADDR_CURRENT_CHANNEL;
                xadc_den <= 1;

                state <= XADC_AXIS_AWAIT_CURRENT_DATA;
            end
            XADC_AXIS_AWAIT_CURRENT_DATA: begin
                if (xadc_drdy) begin
                    xadc_current_axis.tdata <= xadc_do;
                    xadc_current_axis.tvalid <= 1;

                    state <= XADC_AXIS_SEND_TO_CURRENT_FIFO;
                end
            end
            XADC_AXIS_SEND_TO_CURRENT_FIFO: begin
                if (xadc_current_axis.tready && xadc_current_axis.tvalid) begin
                    xadc_current_axis.tvalid <= 0;

                    state <= XADC_AXIS_AWAIT_EOS;
                end
            end
        endcase
    end
endmodule

`default_nettype wire
