`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module cobs_encode_wrapper_tb;

    var logic reset;
    var logic clk;

    // Will be 16 bits of sample data plus 0 byte overhead
    var logic[31:0] encoded_packet;

    typedef enum int {
        LOAD_FIRST_BYTE,
        LOAD_SECOND_BYTE,
        CONSUME_FIRST_BYTE,
        CONSUME_SECOND_BYTE,
        CONSUME_THIRD_BYTE,
        CONSUME_FOURTH_BYTE,
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

    cobs_encode_wrapper DUT (
        .raw_stream(raw_stream),
        .encoded_stream(encoded_stream)
    );

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            // what would normally go in an initial block we can put here
            clk = 0;
            reset = 0;

            // Configure the raw_stream
            raw_stream.tdata = 'h69;
            raw_stream.tvalid = 1;
            raw_stream.tlast = 0;
            raw_stream.tuser = 0;

            // configure the encoded output
            encoded_stream.tready = 0;

            // initialize state
            encoded_packet = 0;
        end

        `TEST_CASE("CHECK_COBS_OUTPUT") begin
            automatic int bytes_loaded = 0;
            automatic int bytes_consumed = 0;
            while (bytes_loaded < 2) begin
                @(posedge clk) begin
                    if (raw_stream.tvalid && raw_stream.tready) begin
                        raw_stream.tdata = raw_stream.tdata + 1;
                        bytes_loaded = bytes_loaded + 1;
                        if (bytes_loaded == 2) begin
                            raw_stream.tlast = 1;
                        end
                    end
                end
            end
            
            // now consume the output
            encoded_stream.tready = 1;
            while (bytes_consumed < 4) begin
                @(posedge clk) begin
                    if (encoded_stream.tvalid && encoded_stream.tready) begin
                        // do stuff here 
                    end
                    bytes_consumed = bytes_consumed + 1;
                end
            end
            // wait (bytes_loaded == 2) `CHECK_EQUAL(encoded_packet, 32'h03_69_70_00);
            wait (bytes_consumed == 4) `CHECK_EQUAL(encoded_packet, 32'h03_69_70_00);
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
