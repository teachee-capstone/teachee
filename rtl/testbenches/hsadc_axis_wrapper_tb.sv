`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module hsadc_axis_wrapper_tb;
    var logic reset;

    var logic sample_clk;
    var logic stream_clk;

    always begin
        #10
        stream_clk <= !stream_clk;
    end

    always begin
        #100
        sample_clk <= !sample_clk;
    end

    axis_interface #(
        .DATA_WIDTH(16)
    ) hsadc_stream_axis (
        .clk(stream_clk),
        .rst(reset)
    );

    hsadc_interface hsadc_ctrl_signals ();

    hsadc_axis_wrapper hsadc_wrapper (
        .sample_clk(sample_clk),
        .stream_clk(stream_clk),
        .reset(reset),

        .hsadc_ctrl_signals(hsadc_ctrl_signals.Sink),
        .sample_stream(hsadc_stream_axis)
    );

    hsadc_bfm bfm (
        .hsadc_ctrl_signals(hsadc_ctrl_signals.Source)
    );

    var logic [7:0] counter = 0;
    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            sample_clk = 0;
            stream_clk = 0;
            reset = 0;

        end

        `TEST_CASE("CHECK_FIRST_SAMPLES") begin
            hsadc_stream_axis.tready = 1;
            while (1) begin
                @(posedge stream_clk) begin
                    // Run checks here
                    if (hsadc_stream_axis.tready && hsadc_stream_axis.tvalid) begin
                        `CHECK_EQUAL(hsadc_stream_axis.tdata[7:0], counter);
                        `CHECK_EQUAL(hsadc_stream_axis.tdata[15:8], counter);
                        counter <= counter + 1;
                        $display("passed counter = %d, assertion", counter);
                    end

                    if (counter == 10) begin
                        break;
                    end

                end
            end
        end
    end

endmodule

`default_nettype none
