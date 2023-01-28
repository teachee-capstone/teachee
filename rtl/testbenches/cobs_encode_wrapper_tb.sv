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

    cobs_encode_wrapper cobs_wrapper (
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
            encoded_stream.tready = 1;

            // initialize state
            state = LOAD_FIRST_BYTE;
        end

        `TEST_CASE("CHECK_COBS_OUTPUT_FROM_16BIT_SAMPLE") begin
            @(posedge clk) begin
                case (state)
                    LOAD_FIRST_BYTE: begin
                        if (raw_stream.tready) begin
                            raw_stream.tdata <= raw_stream.tdata + 1;
                            state <= LOAD_SECOND_BYTE;
                        end
                    end
                    LOAD_SECOND_BYTE: begin
                        if (raw_stream.tready) begin
                            raw_stream.tvalid <= 0;
                            // Mark that this is the last one with tlast
                            raw_stream.tlast <= 1;
                            state <= CONSUME_FIRST_BYTE;
                        end
                    end
                    CONSUME_FIRST_BYTE: begin
                        raw_stream.tlast <= 0;
                        // Wait for the encoded byte to become available on the other side of the module
                        if (encoded_stream.tvalid && encoded_stream.tready) begin
                            encoded_packet[31:24] <= encoded_stream.tdata;
                            state <= CONSUME_SECOND_BYTE;
                        end
                    end
                    CONSUME_SECOND_BYTE: begin
                        if (encoded_stream.tvalid && encoded_stream.tready) begin
                            encoded_packet[23:16] <= encoded_stream.tdata;
                            state <= CONSUME_THIRD_BYTE;
                        end
                    end
                    CONSUME_THIRD_BYTE: begin
                        if (encoded_stream.tvalid && encoded_stream.tready) begin
                            encoded_packet[15:8] <= encoded_stream.tdata;
                            state <= CONSUME_FOURTH_BYTE;
                        end
                    end
                    CONSUME_FOURTH_BYTE: begin
                        if (encoded_stream.tvalid && encoded_stream.tready) begin
                            encoded_packet[7:0] <= encoded_stream.tdata;
                            state <= RUN_CHECK;
                        end
                    end
                    // Now comapre the four encoded bytes against the expected value
                    RUN_CHECK: begin
                        `CHECK_EQUAL(encoded_packet, 32'h03_69_70_00);
                    end
                endcase
            end
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
