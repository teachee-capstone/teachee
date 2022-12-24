interface axis_input_io #(
    DATA_WIDTH = 8
) (
    input wire clk,
    input wire rst,
    input wire tvalid,
    input wire[DATA_WIDTH-1:0] tdata
);
    logic tready;
endinterface //axis_input_io

interface axis_output_io #(
    DATA_WIDTH = 8
) (
    input wire clk,
    input wire rst,
    input wire tready,
);
    logic[DATA_WIDTH-1:0] tdata;
    logic tvalid;
endinterface //axis_output_io