`default_nettype none
`timescale 1ns / 1ps

interface hsadc_interface (
    output var logic channel_a_enc,
    input  var logic[7:0] channel_a,

    output var logic channel_b_enc,
    input  var logic[7:0] channel_b,

    // control signals
    output var logic s1,
    output var logic s2,
    output var logic dfs
);

endinterface // hsadc_interface

`default_nettype wire

