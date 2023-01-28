`default_nettype none
`timescale 1ns / 1ps
// Wrapper module to fit the cobs encoder library module to our interface

module cobs_encode_wrapper (
    axis_interface.Sink raw_stream, // Raw byte stream
    axis_interface.Source encoded_stream // Cobs encoded bytes
);
    axis_cobs_encode cobs_encoder (
        // AXI input
        .s_axis_tdata(raw_stream.tdata),
        .s_axis_tvalid(raw_stream.tvalid),
        .s_axis_tready(raw_stream.tready),
        .s_axis_tlast(raw_stream.tlast),
        .s_axis_tuser(raw_stream.tuser),

        // AXI Output
        .m_axis_tdata(encoded_stream.tdata),
        .m_axis_tvalid(encoded_stream.tvalid),
        .m_axis_tready(encoded_stream.tready),
        .m_axis_tlast(encoded_stream.tlast),
        .m_axis_tuser(encoded_stream.tuser)
    );
endmodule

`default_nettype none
