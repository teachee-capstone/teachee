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

    inout tri logic[7:0] data

    // PC Side fake output
    output wire tdata,
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

    axis_fifo #(
        .DEPTH(0)
    ) tx_fifo (
        // Clock and reset
        .clk(clk),
        .rst(~rst_n),

        // Input Side of FIFO
        .s_axis_tdata(data),
        .s_axis_tvalid(~wr_n),
        .s_axis_tready(~txe_n),

        // Output Side of FIFO
        .m_axis_tdata(tdata),
        .m_axis_tvalid(tvalid),
        .m_axis_tready(tready)
    );

endmodule