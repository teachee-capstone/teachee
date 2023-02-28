`default_nettype none
`timescale 1ns / 1ps

interface hsadc_interface #(
    parameter DATA_WIDTH = 8,
    parameter USER_WIDTH = 1,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter KEEP_WIDTH = (DATA_WIDTH+7)/8
) (
    input var logic clk,
    input var logic rst
);
 // TODO

endinterface // hsadc_interface
