`timescale 1ns / 1ps
`default_nettype none

module axis_async_fifo_wrapper #(
    parameter DEPTH = 2,
    parameter DATA_WIDTH = 8,
    parameter USER_WIDTH = 1,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter KEEP_WIDTH = (DATA_WIDTH+7)/8
) (
    axis_interface.Sink sink,
    axis_interface.Source source
);

    axis_async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH),

        // Propagate the unused signals
        .ID_ENABLE(1),
        .DEST_ENABLE(1)
    ) tx_fifo (
        // AXI Stream Input
        .s_clk(sink.clk),
        .s_rst(sink.rst),
        .s_axis_tdata(sink.tdata),
        .s_axis_tvalid(sink.tvalid),
        .s_axis_tready(sink.tready),
        .s_axis_tlast(sink.tlast),
        .s_axis_tid(sink.tid),
        .s_axis_tdest(sink.tdest),
        .s_axis_tuser(sink.tuser),

        // AXI Stream Output
        .m_clk(source.clk),
        .m_rst(source.rst),
        .m_axis_tdata(source.tdata),
        .m_axis_tvalid(source.tvalid),
        .m_axis_tready(source.tready),
        .m_axis_tlast(source.tlast),
        .m_axis_tid(source.tid),
        .m_axis_tdest(source.tdest),
        .m_axis_tuser(source.tuser)
    );

endmodule

`default_nettype wire
