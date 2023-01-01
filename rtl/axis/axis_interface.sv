`default_nettype none
`timescale 1ns / 1ps

interface axis_interface #(
    parameter DATA_WIDTH = 8,
    parameter USER_WIDTH = 1,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter KEEP_WIDTH = (DATA_WIDTH+7)/8
) (
    input var logic clk,
    input var logic rst
);

    logic[DATA_WIDTH-1:0] tdata;
    logic tvalid;
    logic tready;

    // Drive these to default values if unused.
    logic tlast;
    logic[ID_WIDTH-1:0] tid;
    logic[USER_WIDTH-1:0] tuser;
    logic[DEST_WIDTH-1:0] tdest;
    logic[KEEP_WIDTH-1:0] tkeep; 

    // Default Values
    // tlast = 1
    // tkeep = 1
    // tid = 0
    // tuser = 0
    // tdest = 0


    modport Source (
        input clk, rst,
        output tdata, tkeep, tvalid, tlast, tid, tdest, tuser,
        input tready

    );

    modport Sink (
        input clk, rst,
        input tdata, tkeep, tvalid, tlast, tid, tdest, tuser,
        output tready
    );

endinterface //axis_interface

`default_nettype wire
