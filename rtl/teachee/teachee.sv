`default_nettype none
`timescale 1ns / 1ps

import xadc_drp_package::*;

module teachee (
    input  var logic cmod_osc, // 12 MHz provided on the CMOD
    input  var logic ftdi_clk, // 60 MHz provided by the FTDI

    // FTDI Control Interface
    input  var logic ftdi_rxf_n,
    input  var logic ftdi_txe_n,

    output var logic ftdi_rd_n,
    output var logic ftdi_wr_n,
    output var logic ftdi_siwu_n,
    output var logic ftdi_oe_n,

    output var logic[7:0] ftdi_data,

    // High Speed ADC IO Interface
    output var logic hsadc_a_enc,
    input var logic[7:0] hsadc_a,

    output var logic hsadc_b_enc,
    input var logic[7:0] hsadc_b,

    // CMOD IO Declarations
    input var logic[1:0] btn,
    output var logic[1:0] led,

    input var logic[1:0] xa_n,
    input var logic[1:0] xa_p,

    // TeachEE IO Declarations
    output var logic[1:0] teachee_led,
    inout wire[5:0] spare_pin
);
    // Spare pin 0 = s1
    // spare pin 1 = s2
    // spare pin 4 = dfs

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

    hsadc_interface hsadc_ctrl ();
    assign hsadc_a_enc = hsadc_ctrl.channel_a_enc;
    assign hsadc_ctrl.channel_a = hsadc_a;

    assign hsadc_b_enc = hsadc_ctrl.channel_b_enc;
    assign hsadc_ctrl.channel_b = hsadc_b;

    assign hsadc_ctrl.s1 = spare_pin[0];
    assign hsadc_ctrl.s2 = spare_pin[1];
    assign hsadc_ctrl.dfs = spare_pin[4];

    axis_interface #(
        .DATA_WIDTH(2 * XADC_DRP_DATA_WIDTH)
    ) xadc_sample_channel (
        .clk(sys_clk),
        .rst(reset)
    );

    axis_interface #(
        .DATA_WIDTH(16)
    ) hsadc_sample_channel (
        .clk(sys_clk),
        .rst(reset)
    );

    axis_interface #(
        .DATA_WIDTH(8)
    ) hsadc_usb_axis (
        .clk(sys_clk),
        .rst(reset)
    );

    axis_interface #(
        .DATA_WIDTH(8)
    ) xadc_usb_axis (
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
        // CHANGE THIS BASED ON WHETHER YOU WANT TO USE XADC OR HSADC
        .sys_axis(xadc_usb_axis.Sink)
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

    // Configure HSADC AXI Streamer
    hsadc_axis_wrapper hsadc (
        .sample_clk(clk_10),
        .stream_clk(sys_clk),
        .reset(reset),

        .hsadc_ctrl_signals(hsadc_ctrl.Sink),
        .sample_stream(hsadc_sample_channel.Source)
    );

    cobs_axis_adapter_wrapper #(
        .S_DATA_WIDTH(16),
        .M_DATA_WIDTH(8)
    ) hsadc_packetizer (
        .original_data(hsadc_sample_channel.Sink),
        .encoded_data(hsadc_usb_axis.Source)
    );

    cobs_axis_adapter_wrapper #(
        .S_DATA_WIDTH(2 * XADC_DRP_DATA_WIDTH),
        .M_DATA_WIDTH(8)
    ) xadc_packetizer (
        .original_data(xadc_sample_channel.Sink),
        .encoded_data(xadc_usb_axis.Source)
    );

    always_comb begin
        // Set one of these depending on which stream is being sent
        // xadc_sample_channel.tready = 1;
        // xadc_usb_axis.tready = 1;

        hsadc_sample_channel.tready = 1;
        hsadc_usb_axis.tready = 1;

    end

endmodule

`default_nettype wire

