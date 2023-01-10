`default_nettype none
`timescale 1ns / 1ps
// This module will consume data from the XADC Channel FIFOs. The module will
// convert the two 16 bit streams into a single 8 bit stream. The 8 bit stream
// will contain header bytes to indicate what channel the sample is coming from.
// This stream will then be fed into a COBS encoder module which will feed the
// 8-bit USB fifo.
module xadc_packetizer ();
endmodule

`default_nettype none
