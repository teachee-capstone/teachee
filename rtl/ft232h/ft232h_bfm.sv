`default_nettype none
`timescale 1ns / 1ps

import ft232h_package::*;

// Tx only BFM for FT232H in FT245 Synchronous mode.
// Bit mode 0x40
module ft232h_bfm (
    output var logic clk,

    output var logic rxf_n,
    output var logic txe_n,

    input var logic rd_n,
    input var logic wr_n,
    input var logic siwu_n,
    input var logic oe_n,
    input var logic rst_n,

    // Set to input for simplicity
    // Since this is a write only BFM
    input var logic[7:0] data,

    // PC Side fake output
    output var logic[7:0] tdata,
    output var logic tvalid,
    input var logic tready
);

    initial begin
        clk = 0;
    end

    always begin
        #8.333
        clk = ~clk;
    end

    logic s_axis_tready;
    axis_fifo #(
        .DEPTH(FT232H_BFM_AXIS_FIFO_DEPTH)
    ) tx_fifo (
        // Clock and reset
        .clk(clk),
        .rst(~rst_n),

        // Input Side of FIFO
        .s_axis_tdata(data),
        .s_axis_tvalid(~wr_n),
        .s_axis_tready(s_axis_tready),

        // Output Side of FIFO
        .m_axis_tdata(tdata),
        .m_axis_tvalid(tvalid),
        .m_axis_tready(tready)
    );
    // handle inversion of ready signal to reflect ftdi chip
    assign txe_n = ~s_axis_tready;

endmodule

`default_nettype wire
