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
    output reg[1:0] teachee_led
);

    assign ftdi_siwu_n = 1;
    assign ftdi_rd_n = 1;
    assign ftdi_wr_n = 1;
    assign ftdi_oe_n = 1;

    assign ftdi_data = 8'bZZZZ_ZZZZ;

    reg[31:0] sys_counter = 0;
    reg[31:0] ftdi_counter = 0;
    always @(posedge sysclk) begin
        sys_counter <= sys_counter + 1;
        if (sys_counter == 6000000) begin
            teachee_led[0] <= ~teachee_led[0];
            sys_counter <= 0;
        end
    end

    always @(posedge ftdiclk) begin
        ftdi_counter <= ftdi_counter + 1;
        if (ftdi_counter == 6000000) begin
            teachee_led[1] <= ~teachee_led[1];
            ftdi_counter <= 0;
        end
    end
endmodule