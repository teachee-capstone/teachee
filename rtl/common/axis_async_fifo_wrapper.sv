module axis_async_fifo_wrapper #(
    parameter DEPTH = 2,
    parameter DATA_WIDTH = 8
) (
    axis_input_io axis_input,
    axis_output_io axis_output,
);

    axis_async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) tx_fifo (
        // AXI Stream Input
        .s_clk(axis_input.clk),
        .s_rst(axis_input.rst),
        .s_axis_tdata(axis_input.tdata),
        .s_axis_tvalid(axis_input.tvalid),
        .s_axis_tready(axis_input.tready),

        // AXI Stream Output
        .m_clk(axis_output.clk),
        .m_rst(axis_output.rst),
        .m_axis_tdata(axis_output.tdata),
        .m_axis_tvalid(axis_output.tvalid),
        .m_axis_tready(axis_output.tready)
    );

endmodule