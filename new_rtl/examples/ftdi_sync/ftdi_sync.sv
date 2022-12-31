`default_nettype none
`timescale 1ns / 1ps

// TODO: Write about ftdi set bit mode prerequisites here.
module ftdi_sync (
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

    // TeachEE IO Declarations
    output var logic[1:0] teachee_led
);

    typedef enum int {
        INIT,
        IDLE,
        SEND_TO_HOST
    } state_t;

    state_t state = IDLE;

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
        // Do write state machine here
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
