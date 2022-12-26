`default_nettype none
`timescale 1ns / 1ps

// DRP access addresses for the current / voltages values
`define CURRENT_CHANNEL_ADDR 7'h14
`define VOLTAGE_CHANNEL_ADDR 7'h1c
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

typedef enum int {
    INIT,
    IDLE,
    SEND_TO_HOST
} state_t;

state_t state = IDLE;


var logic[15:0] current_reading;
var logic[15:0] voltage_reading;

var logic[6:0] xadc_daddr;
var logic xadc_read_en;
wire xadc_dready;
wire[15:0] xadc_data;
wire xadc_eos;
wire xadc_eoc;
wire xadc_alarm;
wire xadc_busy;
wire[4:0] xadc_channel;
// TODO: Make an XADC axis wrapper
xadc_wiz_0 cmod_xadc_inst (
  // Clock and Reset
  .dclk_in(sys_clk),          // input wire dclk_in
  .reset_in(0),        // input wire reset_in

  // DRP interface
  .di_in(0),              // input wire [15 : 0] di_in
  .daddr_in(xadc_daddr),        // input wire [6 : 0] daddr_in
  .den_in(xadc_read_en),            // input wire den_in
  .dwe_in(0),            // input wire dwe_in
  .drdy_out(xadc_dready),        // output wire drdy_out
  .do_out(xadc_data),            // output wire [15 : 0] do_out

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
  .channel_out(xadc_channel),  // output wire [4 : 0] channel_out
  .eoc_out(xadc_eoc),          // output wire eoc_out
  .alarm_out(xadc_alarm),      // output wire alarm_out
  .eos_out(xadc_eos),          // output wire eos_out
  .busy_out(xadc_busy)        // output wire busy_out
);
// Basic idea is that xadc_eos should go high to indicate end of sequence.
// Once end of sequence is detected, the FPGA will initiate a read from each channel. (Use the addresses defined at top of file)
// The data out from the DRP interface will be stored in either the current or voltage reading register (depending on address value)
// Each value is 16 bits so we will combine them into one 32 bit async FIFO axi output. Then in future, the full scope design can consume
// those samples and stream them into the ft232h module as bytes using a cobs encoder.

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

always_ff @(posedge sys_clk) begin
    case (state)
        INIT: begin
            sys_axis.tdata <= 69;
            sys_axis.tvalid <= 0;
            state <= IDLE;
        end
        IDLE: begin
            if (sys_axis.tready) begin
                sys_axis.tvalid <= 1;
                state <= SEND_TO_HOST;
            end
        end
        SEND_TO_HOST: begin
            if (sys_axis.tready && sys_axis.tvalid) begin
                sys_axis.tdata <= sys_axis.tdata + 1;
            end
            sys_axis.tvalid <= 0;
            state <= IDLE;
        end
    endcase
end

endmodule

`default_nettype wire
