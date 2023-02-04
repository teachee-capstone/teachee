`timescale 1ns / 1ps
`default_nettype none

module axis_adapter_wrapper #(
    // Input AXIS Data width
    parameter S_DATA_WIDTH = 8,
    parameter M_DATA_WIDTH = 8,
    parameter ID_ENABLE = 1,
    parameter DEST_ENABLE = 1,
    parameter USER_ENABLE = 1
) (
    axis_interface.Sink original_data,
    axis_interface.Source modified_width_data
);

    // assumption that both streams are in the same clock domain
    axis_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .DEST_ENABLE(DEST_ENABLE),
        .USER_ENABLE(USER_ENABLE)
        // .S_KEEP_ENABLE(0)
        // .M_KEEP_ENABLE(0)
    ) width_adapter (
        .clk(original_data.clk),
        .rst(original_data.rst || modified_width_data.rst),

        // AXI INPUT
        .s_axis_tdata(original_data.tdata),
        .s_axis_tkeep(original_data.tkeep),
        .s_axis_tvalid(original_data.tvalid),
        .s_axis_tready(original_data.tready),
        .s_axis_tlast(original_data.tlast),
        .s_axis_tid(original_data.tid),
        .s_axis_tdest(original_data.tdest),
        .s_axis_tuser(original_data.tuser),

        // AXI OUTPUT
        .m_axis_tdata(modified_width_data.tdata),
        .m_axis_tkeep(modified_width_data.tkeep),
        .m_axis_tvalid(modified_width_data.tvalid),
        .m_axis_tready(modified_width_data.tready),
        .m_axis_tlast(modified_width_data.tlast),
        .m_axis_tid(modified_width_data.tid),
        .m_axis_tdest(modified_width_data.tdest),
        .m_axis_tuser(modified_width_data.tuser)
    );
endmodule

`default_nettype wire

