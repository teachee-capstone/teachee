`default_nettype none
`timescale 1ns / 1ps

module xadc_axis (
    input var logic sys_clk, // 12 MHz provided on the CMOD
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

    axis_io #(
        .DATA_WIDTH(16)
    ) voltage_channel (
        .clk(sys_clk),
        .rst(0)
    );

    axis_io #(
        .DATA_WIDTH(16)
    ) current_monitor_channel (
        .clk(sys_clk),
        .rst(0)
    );

    axis_io sys_axis (
        .clk(sys_clk),
        .rst(0)
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

    var logic xadc_reset;
    xadc_drp_addr_t xadc_daddr;
    var logic xadc_den;

    var logic xadc_drdy;
    var logic[15:0] xadc_do;
    var logic xadc_eos;

    xadc_drp_axis_adapter xadc_drp_axis_adapter_inst (
        .xadc_dclk(sys_clk),
        .xadc_reset(0), 

        // DRP and Conversion Signals
        .xadc_daddr(xadc_daddr),
        .xadc_den(xadc_den),
        .xadc_drdy(xadc_drdy),
        .xadc_do(xadc_do),

        .xadc_eos(xadc_eos),

        // .vauxp4(xa_p[0]),
        // .vauxn4(xa_n[0]),

        // .vauxp12(xa_p[1]),
        // .vauxn12(xa_n[1]),

        .current_monitor_channel(current_monitor_channel.Source),
        .voltage_channel(voltage_channel.Source)
    );


    xadc_axis_ip xadc_teachee_inst (
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

    always_ff @(posedge sys_clk) begin
        // comment / uncomment blocks depending on whether you want to view voltage or current readings
        // voltage_channel.tready <= 1;
        // current_monitor_channel.tready <= sys_axis.tready;
        // sys_axis.tvalid <= current_monitor_channel.tvalid;
        // sys_axis.tdata <= current_monitor_channel.tdata[11:4];

        // The adapter stalls if both FIFOs aren't being consumed
        // set current channel to unload data even though we are not actually sending over USB yet
        current_monitor_channel.tready <= 1;
        voltage_channel.tready <= sys_axis.tready;
        sys_axis.tvalid <= voltage_channel.tvalid;
        sys_axis.tdata <= voltage_channel.tdata[11:4];
    end

endmodule

`default_nettype wire
