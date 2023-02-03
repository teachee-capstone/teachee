`timescale 1ns / 1ps
`default_nettype none

// This wrapper uses the axis width and cobs encoders wrappers to adapt a stream
// to a smaller size and then cobs encode it

module cobs_axis_adapter_wrapper #(
    parameter S_DATA_WIDTH = 8,
    parameter M_DATA_WIDTH = 8,
    parameter ID_ENABLE = 1,
    parameter DEST_ENABLE = 1,
    parameter USER_ENABLE = 1
) (
   axis_interface.Sink original_data,
   axis_interface.Source encoded_data
);

    // note that we will use the same clock as this is a synchronous module
    axis_interface #(
        .DATA_WIDTH(M_DATA_WIDTH)
    ) modified_width_data (
        .clk(original_data.clk),
        .rst(original_data.rst)
    );

    axis_adapter_wrapper #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .DEST_ENABLE(DEST_ENABLE),
        .USER_ENABLE(USER_ENABLE)
    ) axis_width_adapter (
        .original_data(original_data),
        .modified_width_data(modified_width_data)
    );

    // Now feed the width adapter output directly into the COBS wrapper
    cobs_encode_wrapper cobs_encoder (
        .raw_stream(modified_width_data.Sink),
        .encoded_stream(encoded_data)
    );

endmodule

`default_nettype wire
