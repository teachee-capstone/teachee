`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module hsadc_axis_wrapper_tb;
    var logic reset;

    var logic sample_clk;
    var logic stream_clk;

    always begin
        #10
        stream_clk <= stream_clk;
    end

    always begin
        #100
        sample_clk <= !sample_clk;
    end

    axis_interface #(
        .DATA_WIDTH(16)
    ) hsadc_stream_axis (
        .clk(stream_clk),
        .rst(reset),
    );

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            sample_clk = 0;
            stream_clk = 0;
            reset = 0;
        end

        `TEST_CASE("CHECK_FIRST_SAMPLES") begin
            `CHECK_EQUAL(0, 0);
        end
    end

endmodule

`default_nettype none
