// Blink led[0] with sysclk
// Blink led[1] with ftdi clock as verification that the device is functioning in synchronous mode.

// TODO: Write about ftdi set bit mode prerequisites here.
module ftdi_sync (
    input wire sysclk, // 12 MHz provided on the CMOD
    input wire ftdiclk, // 60 MHz provided by the FTDI

    // FTDI Control Interface
    input wire ftdi_rxf_n,
    input wire ftdi_txe_n,

    output wire ftdi_rd_n,
    output wire ftdi_wr_n,
    output wire ftdi_siwu_n,
    output wire ftdi_oe_n,

    inout[7:0] ftdi_data,

    // CMOD IO Declarations
    output[1:0] led,

    // TeachEE IO Declarations
    output[1:0] teachee_led
);



endmodule