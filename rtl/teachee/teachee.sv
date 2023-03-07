`default_nettype none
`timescale 1ns / 1ps

import xadc_drp_package::*;

module teachee (
    input var logic cmod_osc, // 12 MHz provided on the CMOD
    input var logic ftdi_clk, // 60 MHz provided by the FTDI

    // FTDI Control Interface
    input var logic ftdi_rxf_n,
    input var logic ftdi_txe_n,

    output var logic ftdi_rd_n,
    output var logic ftdi_wr_n,
    output var logic ftdi_siwu_n,
    output var logic ftdi_oe_n,

    output var logic[7:0] ftdi_data,

    // CMOD IO Declarations
    input var logic[1:0] btn,
    output var logic[1:0] led,

    input var logic[1:0] xa_n,
    input var logic[1:0] xa_p,

    // TeachEE IO Declarations
    output var logic[1:0] teachee_led
);

    var logic locked;
    var logic sys_clk;
    var logic reset;

    assign reset = !locked;

    assign sys_clk = clk_100;

    var logic clk_100;
    var logic clk_50;
    var logic clk_25;
    var logic clk_20;
    var logic clk_10;

    teachee_pll teachee_pll_ip_inst (
        // Clock out ports
        .clk_100(clk_100),     // output clk_100
        .clk_50(clk_50),     // output clk_50
        .clk_25(clk_25),     // output clk_25
        .clk_20(clk_20),     // output clk_20
        .clk_10(clk_10),     // output clk_10

        // Status and control signals
        .reset(0), // input reset
        .locked(locked),       // output locked

        // Clock in ports
        .cmod_osc(cmod_osc)      // input cmod_osc
    );

    axis_interface #(
        .DATA_WIDTH(2 * XADC_DRP_DATA_WIDTH)
    ) xadc_sample_channel (
        .clk(sys_clk),
        .rst(reset)
    );

    axis_interface #(
        .DATA_WIDTH(8)
    ) sys_axis (
        .clk(sys_clk),
        .rst(reset)
    );

    ft232h usb_fifo (
        .ftdi_clk(ftdi_clk),

        .ftdi_rxf_n(ftdi_rxf_n),
        .ftdi_txe_n(ftdi_txe_n),

        .ftdi_rd_n(ftdi_rd_n),
        .ftdi_wr_n(ftdi_wr_n),
        .ftdi_siwu_n(ftdi_siwu_n),
        .ftdi_oe_n(ftdi_oe_n),

        .ftdi_adbus(ftdi_data),

        // Programmer AXIS Interface
        .sys_axis(sys_axis.Sink)
    );

    xadc_drp_addr_t xadc_daddr;
    var logic xadc_den;

    var logic xadc_drdy;
    var logic[XADC_DRP_DATA_WIDTH-1:0] xadc_do;
    var logic xadc_eos;

    xadc_drp_axis_single_stream xadc_drp_axis_adapter_inst (
        .xadc_dclk(sys_clk),
        .xadc_reset(reset),

        // DRP and Conversion Signals
        .xadc_daddr(xadc_daddr),
        .xadc_den(xadc_den),
        .xadc_drdy(xadc_drdy),
        .xadc_do(xadc_do),

        .xadc_eos(xadc_eos),

        .sample_stream(xadc_sample_channel.Source)
    );


    xadc_teachee xadc_teachee_inst (
        // Clock and Reset
        .dclk_in(sys_clk),          // input wire dclk_in
        .reset_in(reset),        // input wire reset_in

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

    cobs_axis_adapter_wrapper #(
        .S_DATA_WIDTH(2 * XADC_DRP_DATA_WIDTH),
        .M_DATA_WIDTH(8)
    ) packetizer (
        .original_data(xadc_sample_channel.Sink),
        .encoded_data(sys_axis.Source)
    );

endmodule

`default_nettype wire
