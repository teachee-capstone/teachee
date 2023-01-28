`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module cobs_encode_wrapper_tb;

    var logic reset;
    var logic clk;

    typedef enum int {
        LOAD_FIRST_BYTE,
        LOAD_SECOND_BYTE,
        CONSUME_FIRST_BYTE,
        CONSUME_SECOND_BYTE,
        CONSUME_THIRD_BYTE,
        RUN_CHECK
    } cobs_encode_wrapper_tb_state_t;

    cobs_encode_wrapper_tb_state_t state;

    always begin
        #10
        clk <= !clk;
    end 

    axis_interface #(
        .DATA_WIDTH(8)
    ) raw_stream (
        .clk(clk),
        .rst(reset)
    );

    axis_interface #(
        .DATA_WIDTH(8)
    ) encoded_stream (
        .clk(clk),
        .rst(reset)
    );

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            // what would normally go in an initial block we can put here
            clk = 0;
            reset = 0;

            // Configure the raw_stream
            raw_stream.tdata = 69;
            raw_stream.tvalid = 1;
            raw_stream.tlast = 0;
            raw_stream.tuser = 0;

            // configure the encoded output
            encoded_stream.tready = 1;

            // initialize state
            state = LOAD_FIRST_BYTE;
        end

        `TEST_CASE("CHECK_COBS_OUTPUT_FROM_16BIT_SAMPLE") begin
            @(posedge clk) `CHECK_EQUAL(0, 0);
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
