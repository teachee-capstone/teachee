`default_nettype none
`timescale 1ns / 1ps

// Runs a read cycle against the BFM to verify its function. In this tb, I will
// read from both the current monitor and voltage channel addresses for teachee
module xadc_bfm_tb;

typedef enum int {
    INIT,
    AWAIT_CONVERSION_SEQ,
    START_DRP_READ,
    WAIT_CYCLE,
    VIEW_RESULTS,
    DONE
} xadc_bfm_tb_state_t;

xadc_bfm_tb_state_t state;

var logic dclk_in;
var logic reset_in;
var logic[6:0] daddr_in;
var logic den_in;

wire drdy_out;
wire[15:0] do_out;
wire eos_out;

// Set initial state and signal values
intial begin
    dclk_in = 0;
    reset_in = 0;
    daddr_in = 0;
    den_in = 0;
    state = INIT;
end

always begin
    #10 // not true clock freq, for test purposes. Varies based off sample rate
    dclk_in = ~dclk_in;
end

xadc_bfm DUT (
    // Clock and reset
    .dclk_in(dclk_in),
    .reset_in(reset_in),

    // DRP interface (Reduced to read only in this tb)
    .di_in(0), // not used since we are not writing
    .daddr_in(daddr_in),
    .den_in(den_in),
    .dwe_in(0), // write enable is also not used
    .drdy_out(drdy_out),
    .do_out(do_out),

    // Must be connected in the real xadc IP core
    .vp_in(0),
    .vn_in(0),

    // Analog input channels (also need to be connected in real IP core)
    .vauxp4(0),
    .vauxn4(0),
    .vauxp12(0),
    .vauxn12(0),

    // conversion status signals
    .channel_out(),
    .eoc_out(),
    .alarm_out(), // not used
    .eos_out(eos_out),
    .busy_out()
);

// DRP Read FSM
always @(posedge dclk_in) begin
    case (state)
        INIT: begin
            // Set signals to their initial values
            dclk_in <= 0;
            reset_in <= 0;
            daddr_in <= 0;
            den_in <= 0;

            // AWAIT EOS SIGNAL
            state <= AWAIT_CONVERSION_SEQ;
        end
        AWAIT_CONVERSION_SEQ: begin
            if (eos_out) begin
                // If eos goes high, new samples have been written to regs.
                // Read out the current and voltage sample

            end
        end
    endcase
end

endmodule
`default_nettype wire