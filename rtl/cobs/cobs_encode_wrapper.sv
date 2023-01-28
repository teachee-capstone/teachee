`default_nettype none
`timescale 1ns / 1ps
// Wrapper module to fit the cobs encoder library module to our interface

module cobs_encode_wrapper (
    axis_interface.Sink raw_stream, // Raw byte stream
    axis_interface.Source encoded_stream // Cobs encoded bytes
);
    axis_cobs_encode cobs_encoder
endmodule

`default_nettype none
