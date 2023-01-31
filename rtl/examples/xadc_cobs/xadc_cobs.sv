`default_nettype none
`timescale 1ns / 1ps

module xadc_cobs (
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

    axis_interface #(
        .DATA_WIDTH(16)
    ) voltage_channel (
        .clk(sys_clk),
        .rst(0)
    );

    axis_interface #(
        .DATA_WIDTH(16)
    ) current_monitor_channel (
        .clk(sys_clk),
        .rst(0)
    );

    axis_interface #(
        .DATA_WIDTH(8)
    ) sys_axis (
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
        // .sys_axis(sys_axis.Sink)
        .sys_axis(cobs_stream.Sink)
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


    xadc_teachee xadc_teachee_inst (
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



    axis_interface #(
        .DATA_WIDTH(8)
    ) cobs_stream (
        .clk(sys_clk),
        .rst(0)
    );

    axis_interface #(
        .DATA_WIDTH(8)
    ) raw_stream (
        .clk(sys_clk),
        .rst(0)
    );

    // xadc_packetizer sample_cobs_streamer (
    //     .voltage_channel(voltage_channel.Sink),
    //     .current_monitor_channel(current_monitor_channel.Sink),
    //     .packet_stream(cobs_stream.Source)
    // );

    cobs_encode_wrapper cobs_encoder (
        .raw_stream(raw_stream.Sink),
        .encoded_stream(cobs_stream.Source)
    );

    typedef enum int {
        INIT,
        WAIT_FOR_SAMPLE,
        COLLECT_UPPER_LOWER,
        PREP_LOAD,
        LOAD_UPPER,
        LOAD_LOWER
    } xadc_cobs_state_t;
    xadc_cobs_state_t state = INIT;

    var logic[15:0] voltage_sample;
    always_ff @(posedge sys_clk) begin
        case (state)
            INIT: begin
                voltage_sample <= 0;

                sys_axis.tlast <= 1;
                sys_axis.tkeep <= '1;
                sys_axis.tid <= '0;
                sys_axis.tuser <= '0;
                sys_axis.tdest <= '0;

                raw_stream.tlast <= 0;
                raw_stream.tkeep <= '1;
                raw_stream.tid <= '0;
                raw_stream.tuser <= '0;
                raw_stream.tdest <= '0;

                raw_stream.tvalid <= 0;
                raw_stream.tdata <= 0;

                // let current monitor channel flow out into nothing to prevent stalls
                current_monitor_channel.tready <= 1;

                voltage_channel.tready <= 0;

                state <= WAIT_FOR_SAMPLE;
            end
            WAIT_FOR_SAMPLE: begin
                if (voltage_channel.tvalid) begin
                    voltage_channel.tready <= 1;

                    state <= COLLECT_UPPER_LOWER;
                end
            end
            COLLECT_UPPER_LOWER: begin
                if (voltage_channel.tready && voltage_channel.tvalid) begin
                    voltage_sample <= voltage_channel.tdata;
                    voltage_channel.tready <= 0;

                    state <= PREP_LOAD;
                end
            end
            PREP_LOAD: begin
                raw_stream.tdata <= voltage_sample[15:8];
                raw_stream.tvalid <= 1;
                
                state <= LOAD_UPPER;
            end
            LOAD_UPPER: begin
                if (raw_stream.tvalid && raw_stream.tready) begin
                    // prep lower 8 bytes of voltage sample
                    raw_stream.tdata <= voltage_sample[7:0];
                    raw_stream.tlast <= 1;
                    state <= LOAD_LOWER;
                end
            end
            LOAD_LOWER: begin
                if (raw_stream.tvalid && raw_stream.tready) begin
                    // we are done writing into the encoder
                    raw_stream.tlast <= 0;
                    raw_stream.tvalid <= 0;
                    state <= WAIT_FOR_SAMPLE;
                end
            end
        endcase
    end

endmodule

`default_nettype wire
