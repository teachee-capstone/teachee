`default_nettype none
`timescale 1ns / 1ps

import ft232h_package::*;

// Tx only BFM for FT232H in FT245 Synchronous mode.
// Bit mode 0x40
module ft232h_bfm (
    output var logic clk,

    output wire rxf_n,
    output wire txe_n,

    input wire rd_n,
    input wire wr_n,
    input wire siwu_n,
    input wire oe_n,
    input wire rst_n,

    // Set to input for simplicity
    // Since this is a write only BFM
    input wire[7:0] data,

    // PC Side fake output
    output wire[7:0] tdata,
    output wire tvalid,
    input wire tready
);

    initial begin
        clk = 0;
    end

    always begin
        #8.333
        clk = ~clk;
    end

    wire s_axis_tready;
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
