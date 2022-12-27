`default_nettype none
`timescale 1ns / 1ps
module xadc_axis_wrapper (
    // PLAN: Wrap DRP interface to an axis interface
    // One axis source will provide current samples and a second will do voltage
    // Each will be 16 bits in width
    // Must start thinking about channel selection
);
endmodule
`default_nettype wire