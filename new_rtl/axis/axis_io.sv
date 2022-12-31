interface axis_io #(
    DATA_WIDTH = 8
) (
    input clk,
    input rst
);

    logic[DATA_WIDTH-1:0] tdata;
    logic tvalid;
    logic tready;

    modport Source (
        input clk, rst,
        output tdata,
        output tvalid,
        input tready
    );

    modport Sink (
        input clk, rst,
        input tdata,
        input tvalid,
        output tready
    );

endinterface //axis_io
