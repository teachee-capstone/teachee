`default_nettype none
`timescale 1ns / 1ps

// Tutorial used to generate the ADC IP core from Xilinx: https://www.youtube.com/watch?v=2j4UHLYqBDI
// My only change is using channels 4 and 12 to correspond to our board design
// Also fed an input clock of 12 MHz for now. Will need 100MHz for full 1MSPS. Right now we make 230 KSPS
module xadc (
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

    typedef enum logic[6:0] {
        XADC_DRP_ADDR_CURRENT_CHANNEL = 7'h14,
        XADC_DRP_ADDR_VOLTAGE_CHANNEL = 7'h1c
    } xadc_drp_addr_t;


    typedef enum int {
        INIT,
        AWAIT_ADC_CONV,
        START_DRP_VOLTAGE_READ,
        AWAIT_DRP_DATA,
        SEND_TO_HOST
    } state_t;

    state_t state = INIT;

    xadc_drp_addr_t xadc_daddr;
    var logic xadc_den;
    var logic xadc_drdy;
    var logic[15:0] xadc_do;
    var logic xadc_eos;

    // TODO: Make an XADC axis wrapper
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

    // Programmer data input side wires
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

    var logic[7:0] sample_data = 0;

    always_ff @(posedge sys_clk) begin
        case (state)
            INIT: begin
                // Axis Signal Init
                sys_axis.tdata <= 0;
                sys_axis.tvalid <= 0;

                // DRP Controls
                xadc_daddr <= XADC_DRP_ADDR_VOLTAGE_CHANNEL;
                xadc_den <= 0;

                state <= AWAIT_ADC_CONV;
            end
            AWAIT_ADC_CONV: begin
                if (xadc_eos) begin
                    // set the signals to start the DRP read
                    // NOTE: change this to CURRENT_ADDR if you want to read the current probe
                    xadc_daddr <= XADC_DRP_ADDR_VOLTAGE_CHANNEL;
                    xadc_den <= 1;

                    state <= START_DRP_VOLTAGE_READ;
                end
            end
            START_DRP_VOLTAGE_READ: begin
                xadc_den <= 0;
                state <= AWAIT_DRP_DATA;
            end
            AWAIT_DRP_DATA: begin
                if (xadc_drdy) begin
                    // grab upper 8 bits of the conversion
                    sys_axis.tdata <= xadc_do[11:4];
                    sys_axis.tvalid <= 1;

                    state <= SEND_TO_HOST;
                end
            end
            SEND_TO_HOST: begin
                if (sys_axis.tready && sys_axis.tvalid) begin
                    sys_axis.tvalid <= 0;
                    state <= AWAIT_ADC_CONV;
                end
            end
        endcase
    end
endmodule
// Useful ILA for checking this FSM
// ila_0 xadc_fsm_ila (
// 	.clk(sys_clk), // input wire clk


// 	.probe0(state), // input wire [31:0]  probe0  
// 	.probe1({sys_axis.tready, sys_axis.tvalid}), // input wire [31:0]  probe1 
// 	.probe2(xadc_do), // input wire [31:0]  probe2 
// 	.probe3(xadc_drdy), // input wire [31:0]  probe3 
// 	.probe4(xadc_den), // input wire [31:0]  probe4 
// 	.probe5(xadc_daddr), // input wire [31:0]  probe5 
// 	.probe6(xadc_eos), // input wire [31:0]  probe6 
// 	.probe7('0), // input wire [31:0]  probe7 
// 	.probe8('0), // input wire [31:0]  probe8 
// 	.probe9('0), // input wire [31:0]  probe9 
// 	.probe10('0), // input wire [31:0]  probe10 
// 	.probe11('0), // input wire [31:0]  probe11 
// 	.probe12('0), // input wire [31:0]  probe12 
// 	.probe13('0), // input wire [31:0]  probe13 
// 	.probe14('0), // input wire [31:0]  probe14 
// 	.probe15('0) // input wire [31:0]  probe15
// );

`default_nettype wire