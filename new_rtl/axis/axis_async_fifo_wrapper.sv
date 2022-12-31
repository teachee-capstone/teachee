module axis_async_fifo_wrapper #(
    parameter DEPTH = 2,
    parameter DATA_WIDTH = 8
) (
    axis_io.Sink sink,
    axis_io.Source source
);

    axis_async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) tx_fifo (
        // AXI Stream Input
        .s_clk(sink.clk),
        .s_rst(sink.rst),
        .s_axis_tdata(sink.tdata),
        .s_axis_tvalid(sink.tvalid),
        .s_axis_tready(sink.tready),

        // AXI Stream Output
        .m_clk(source.clk),
        .m_rst(source.rst),
        .m_axis_tdata(source.tdata),
        .m_axis_tvalid(source.tvalid),
        .m_axis_tready(source.tready)
    );

endmodule