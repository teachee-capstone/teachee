module xadc_drp_fake (
    axis_io.Source current_monitor_channel

);

    axis_io #(
        .DATA_WIDTH(16)
    ) xadc_current_axis (
        .clk(0),
        .rst(0)
    );

    axis_async_fifo_wrapper #(
        .DEPTH(128),
        .DATA_WIDTH(16)
    ) xadc_current_fifo (
        .sink(xadc_current_axis.Sink),
        .source(current_monitor_channel)
    );
endmodule