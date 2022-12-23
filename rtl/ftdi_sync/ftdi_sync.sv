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
    WRITING
} state_t;

state_t state = IDLE;

// wire sys_clk;
// assign sys_clk = ftdi_clk;

// Programmer data input side wires
var logic[7:0] write_data;
var logic tvalid;
wire tready;

ft232h usb (
    .ftdi_clk(ftdi_clk),

    .rxf_n(ftdi_rxf_n),
    .txe_n(ftdi_txe_n),

    .rd_n(ftdi_rd_n),
    .wr_n(ftdi_wr_n),
    .siwu_n(ftdi_siwu_n),
    .oe_n(ftdi_oe_n),

    .data(ftdi_data),

    // Programmer AXIS Interface
    .sys_clk(sys_clk),
    .internal_fifo_rst(0),
    .tdata(write_data),
    .tvalid(tvalid),
    .tready(tready)
);

always_ff @(posedge sys_clk) begin
    // Do write state machine here
    case (state)
        INIT: begin
            write_data <= 0;
            tvalid <= 0;
            state <= IDLE;
        end
        IDLE: begin
            if (tready) begin
                tvalid <= 1;
                write_data <= write_data + 1;
                state <= WRITING;
            end
        end
        WRITING: begin
            // write as long as tready is asserted by the async fifo
            if (~tready) begin
                tvalid <= 0;
                state <= IDLE;
            end else begin
                // write_data <= write_data + 1;
            end
            // tvalid <= 0;
            // state <= IDLE;
        end
    endcase
end

endmodule

`default_nettype wire
