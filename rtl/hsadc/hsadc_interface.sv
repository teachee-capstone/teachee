`default_nettype none
`timescale 1ns / 1ps

interface hsadc_interface;
    var logic channel_a_enc;

    var logic[7:0] channel_a;

    var logic channel_b_enc;
    var logic[7:0] channel_b;

    var logic s1;
    var logic s2;
    var logic dfs;

    modport Source (
        output channel_a, channel_b,
        input channel_a_enc, channel_b_enc, s1, s2, dfs
    );

    modport Sink (
        input channel_a, channel_b,
        output channel_a_enc, channel_b_enc, s1, s2, dfs
    );

endinterface // hsadc_interface

`default_nettype wire

