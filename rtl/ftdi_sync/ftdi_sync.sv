// Blink led[0] with sysclk
// Blink led[1] with ftdi clock as verification that the device is functioning in synchronous mode.

// TODO: Write about ftdi set bit mode prerequisites here.
module ftdi_sync (
    input logic sysclk, // 12 MHz provided on the CMOD
    input logic ftdiclk, // 60 MHz provided by the FTDI

    // FTDI Control Interface
    input logic ftdi_rxf_n,
    input logic ftdi_txe_n,

    output logic ftdi_rd_n,
    output logic ftdi_wr_n,
    output logic ftdi_siwu_n,
    output logic ftdi_oe_n,

    inout tri[7:0] ftdi_data,

    // CMOD IO Declarations
    input logic[1:0] btn,
    output logic[1:0] led,

    // TeachEE IO Declarations
    output logic[1:0] teachee_led
);

    // Use this for states instead of localparams!
    typedef enum int {
        WAITING,
        WRITE
    } state_t;
    
    logic[7:0] counter = 69; // Character code is E
    state_t state;

    logic reset;
    reset_sync rst_sync (
        .reset_in(~btn[0]),
        .destination_clk(ftdi_clk),
        .reset_out(reset)
    );

    always_ff @(posedge ftdiclk) begin
        if (reset) begin
            state <= WAITING;
            ftdi_rd_n <= 1;
            ftdi_wr_n <= 1;
            ftdi_siwu_n <= 1;
            ftdi_oe_n <= 1;
        end else begin
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
    end

    // Bidirectional data logic
    assign ftdi_data = (state == WRITE && ~ftdi_txe_n) ? counter : 8'bZZZZ_ZZZZ;
endmodule