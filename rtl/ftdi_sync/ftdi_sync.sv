`default_nettype none
// Blink led[0] with sysclk
// Blink led[1] with ftdi clock as verification that the device is functioning in synchronous mode.

// TODO: Write about ftdi set bit mode prerequisites here.
module ftdi_sync (
    input var logic sysclk, // 12 MHz provided on the CMOD
    input var logic ftdiclk, // 60 MHz provided by the FTDI

    // FTDI Control Interface
    input var logic ftdi_rxf_n,
    input var logic ftdi_txe_n,

    output var logic ftdi_rd_n,
    output var logic ftdi_wr_n,
    output var logic ftdi_siwu_n,
    output var logic ftdi_oe_n,

    inout tri logic[7:0] ftdi_data,

    // CMOD IO Declarations
    input var logic[1:0] btn,
    output var logic[1:0] led,

    // TeachEE IO Declarations
    output var logic[1:0] teachee_led
);

    // Use this for states instead of localparams!
    typedef enum int {
        WAITING,
        WRITE
    } state_t;
    
    state_t state;

    var logic reset;
    reset_sync rst_sync (
        .reset_in(btn[0]),
        .destination_clk(ftdiclk),
        .reset_out(reset)
    );

    always_ff @(posedge ftdiclk) begin
        if (reset) begin
            state <= WAITING;
        end else begin
            // non-reset behaviour here.
        end
    end

    // Bidirectional data logic
    assign ftdi_data = ~ftdi_txe_n ? counter : 8'bZZZZ_ZZZZ;
endmodule

`default_nettype wire
