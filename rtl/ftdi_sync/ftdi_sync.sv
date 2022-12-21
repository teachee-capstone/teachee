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
    
    logic[7:0] counter = 69; // Character code is E
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
    
    // ila_0 ethan_ila (
    //     .clk(ftdiclk), // input wire clk


    //     .probe0(btn), // input wire [31:0]  probe0  
    //     .probe1(reset), // input wire [31:0]  probe1 
    //     .probe2(state), // input wire [31:0]  probe2 
    //     .probe3(ftdi_txe_n), // input wire [31:0]  probe3 
    //     .probe4(counter), // input wire [31:0]  probe4 
    //     .probe5(ftdi_wr_n), // input wire [31:0]  probe5 
    //     .probe6(ftdi_rd_n), // input wire [31:0]  probe6 
    //     .probe7(ftdi_oe_n) // input wire [31:0]  probe7
    // );

    // Bidirectional data logic
    assign ftdi_data = ~ftdi_txe_n ? counter : 8'bZZZZ_ZZZZ;
endmodule

`default_nettype wire
