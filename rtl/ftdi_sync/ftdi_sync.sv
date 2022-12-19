// Blink led[0] with sysclk
// Blink led[1] with ftdi clock as verification that the device is functioning in synchronous mode.

// TODO: Write about ftdi set bit mode prerequisites here.
module ftdi_sync (
    input wire sysclk, // 12 MHz provided on the CMOD
    input wire ftdiclk, // 60 MHz provided by the FTDI

    // FTDI Control Interface
    input wire ftdi_rxf_n,
    input wire ftdi_txe_n,

    output reg ftdi_rd_n = 1,
    output reg ftdi_wr_n = 1,
    output reg ftdi_siwu_n = 1,
    output reg ftdi_oe_n = 1,

    inout[7:0] ftdi_data,

    // CMOD IO Declarations
    output[1:0] led,

    // TeachEE IO Declarations
    output reg[1:0] teachee_led
);
    localparam
        WAITING = 4'b0001,
        WRITE = 4'b0010;
    
    reg[7:0] counter = 69;
    reg[3:0] state = WAITING;

    always @(posedge ftdiclk) begin
        //counter <= counter + 1;
        if (~ftdi_txe_n) begin
            state <= WRITE;
        end else begin
            state <= WAITING;
        end
        case (state)
            WAITING: begin
                teachee_led[0] <= 1;
                ftdi_wr_n <= 1;    
            end
            WRITE: begin
                teachee_led[0] <= 0;
                ftdi_wr_n <= 0;
            end
        endcase
    end

    // Bidirectional data logic
    assign ftdi_data = (state == WRITE && ~ftdi_txe_n) ? counter : 8'bZZZZ_ZZZZ;
endmodule