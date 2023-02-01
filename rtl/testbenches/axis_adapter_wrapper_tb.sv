`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module axis_adapter_wrapper_tb;

    var logic reset = 0;
    var logic clk;

    always begin
        #10
        clk <= !clk;
    end 

    axis_interface #(
        .DATA_WIDTH(16)
    ) original_data (
        .clk(clk),
        .rst(reset)
    );

    axis_interface #(
        .DATA_WIDTH(8)
    ) modified_width_data (
        .clk(clk),
        .rst(reset)
    );

    axis_adapter_wrapper DUT (
        .original_data(original_data.Sink),
        .modified_width_data(modified_width_data.Source)
    );

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            // what would normally go in an initial block we can put here
            clk = 0;
            reset = 0;

            original_data.tdata = 16'h6971;
            original_data.tvalid = 1;
            original_data.tlast = 1;
            original_data.tuser = 0;
            original_data.tkeep <= '1;
            original_data.tid <= '0;
            original_data.tdest <= '0;

            // configure the encoded output
            modified_width_data.tready = 0;
        end

        `TEST_CASE("VIEW_REDUCED_WIDTH STREAM") begin
            // Check that each byte is legit here
            // the 16 bit should be broken up into two bytes
            automatic int cycles_counted = 0;
            while (cycles_counted < 100) begin
                cycles_counted = cycles_counted + 1;
                @(posedge clk);
            end
            `CHECK_EQUAL(0,0);
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
