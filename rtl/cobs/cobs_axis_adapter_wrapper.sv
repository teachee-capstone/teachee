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

    // ila_1 your_instance_name (
    //     .clk(original_data.clk), // input wire clk

    //     .probe0(original_data.tdata), // input wire [15:0]  probe0  
    //     .probe1(original_data.tkeep), // input wire [15:0]  probe1 
    //     .probe2(original_data.tdest), // input wire [15:0]  probe2 
    //     .probe3(original_data.tuser), // input wire [15:0]  probe3 
    //     .probe4(modified_width_data.tuser), // input wire [15:0]  probe4 
    //     .probe5(modified_width_data.tdata), // input wire [15:0]  probe5 
    //     .probe6(modified_width_data.tkeep), // input wire [15:0]  probe6
    //     .probe7(modified_width_data.tdest), // input wire [15:0]  probe7 
    //     .probe8(original_data.tvalid), // input wire [0:0]  probe8 
    //     .probe9(original_data.tready), // input wire [0:0]  probe9 
    //     .probe10(original_data.tlast), // input wire [0:0]  probe10 
    //     .probe11(modified_width_data.tvalid), // input wire [0:0]  probe11 
    //     .probe12(modified_width_data.tready), // input wire [0:0]  probe12 
    //     .probe13(modified_width_data.tlast), // input wire [0:0]  probe13 
    //     .probe14(0), // input wire [0:0]  probe14 
    //     .probe15(0), // input wire [0:0]  probe15 
    //     .probe16(0), // input wire [0:0]  probe16 
    //     .probe17(0), // input wire [0:0]  probe17 
    //     .probe18(0), // input wire [0:0]  probe18 
    //     .probe19(0), // input wire [0:0]  probe19 
    //     .probe20(0), // input wire [0:0]  probe20 
    //     .probe21(0), // input wire [0:0]  probe21 
    //     .probe22(0), // input wire [0:0]  probe22 
    //     .probe23(0), // input wire [0:0]  probe23 
    //     .probe24(0), // input wire [0:0]  probe24 
    //     .probe25(0), // input wire [0:0]  probe25 
    //     .probe26(0), // input wire [0:0]  probe26 
    //     .probe27(0), // input wire [0:0]  probe27 
    //     .probe28(0), // input wire [0:0]  probe28 
    //     .probe29(0), // input wire [0:0]  probe29 
    //     .probe30(0), // input wire [0:0]  probe30 
    //     .probe31(0) // input wire [0:0]  probe31
    // );

endmodule

`default_nettype wire
