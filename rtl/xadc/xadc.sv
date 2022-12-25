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

typedef enum int {
    INIT,
    IDLE,
    SEND_TO_HOST
} state_t;

state_t state = IDLE;

// Instance template for the ADC

// xadc_wiz_0 your_instance_name (
//   .di_in(di_in),              // input wire [15 : 0] di_in
//   .daddr_in(daddr_in),        // input wire [6 : 0] daddr_in
//   .den_in(den_in),            // input wire den_in
//   .dwe_in(dwe_in),            // input wire dwe_in
//   .drdy_out(drdy_out),        // output wire drdy_out
//   .do_out(do_out),            // output wire [15 : 0] do_out
//   .dclk_in(dclk_in),          // input wire dclk_in
//   .reset_in(reset_in),        // input wire reset_in
//   .vp_in(vp_in),              // input wire vp_in
//   .vn_in(vn_in),              // input wire vn_in
//   .vauxp4(vauxp4),            // input wire vauxp4
//   .vauxn4(vauxn4),            // input wire vauxn4
//   .vauxp12(vauxp12),          // input wire vauxp12
//   .vauxn12(vauxn12),          // input wire vauxn12
//   .channel_out(channel_out),  // output wire [4 : 0] channel_out
//   .eoc_out(eoc_out),          // output wire eoc_out
//   .alarm_out(alarm_out),      // output wire alarm_out
//   .eos_out(eos_out),          // output wire eos_out
//   .busy_out(busy_out)        // output wire busy_out
// );

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
