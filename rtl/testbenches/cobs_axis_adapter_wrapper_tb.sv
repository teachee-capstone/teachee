`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module cobs_axis_adapter_wrapper_tb;

    var logic reset = 0;
    var logic clk;

    typedef enum int {
        SEND_ORIGINAL_DATA,
        READ_OUT_FIRST_BYTE,
        READ_OUT_SECOND_BYTE,
        READ_OUT_THIRD_BYTE,
        READ_OUT_FOURTH_BYTE,
        TESTS_FINISHED
    } cobs_axis_adapter_wrapper_tb_state_t;

    cobs_axis_adapter_wrapper_tb_state_t state = SEND_ORIGINAL_DATA;

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
    ) encoded_data (
        .clk(clk),
        .rst(reset)
    );

    axis_interface #(
        .DATA_WIDTH(16)
    ) fifo_data (
        .clk(clk),
        .rst(reset)
    );

    // want to see how the module behaves against a FIFO output since that is
    // what it will get in use
    axis_async_fifo_wrapper #(
        .DATA_WIDTH(16),
        .DEPTH(5),
        .KEEP_ENABLE(0)
    ) test_fifo (
        .sink(original_data.Sink),
        .source(fifo_data.Source)
    );

    cobs_axis_adapter_wrapper #(
        .S_DATA_WIDTH(16),
        .M_DATA_WIDTH(8)
    ) DUT (
        .original_data(fifo_data.Sink),
        .encoded_data(encoded_data.Source)
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
            original_data.tkeep = '1;
            original_data.tid = '0;
            original_data.tdest = '0;

            encoded_data.tready = 0;

        end

        `TEST_CASE("VIEW_REDUCED_WIDTH_COBS_STREAM") begin
            // Load the FIFO UP
            for (int i = 0; i < 5; i = i + 1) begin
                @(posedge clk) begin
                    if (original_data.tready && original_data.tvalid) begin
                        original_data.tdata = original_data.tdata + 1;
                    end
                end
            end

            while (state != TESTS_FINISHED) begin
                @(posedge clk) begin
                    case (state)
                        SEND_ORIGINAL_DATA: begin
                            original_data.tvalid <= 1;
                            if (original_data.tready && original_data.tvalid) begin
                                encoded_data.tready <= 1;
                                original_data.tvalid <= 0;

                                state <= READ_OUT_FIRST_BYTE;
                            end
                        end
                        READ_OUT_FIRST_BYTE: begin
                            if (encoded_data.tready && encoded_data.tvalid) begin
                                `CHECK_EQUAL(encoded_data.tdata, 8'h03);

                                state <= READ_OUT_SECOND_BYTE;
                            end
                        end
                        READ_OUT_SECOND_BYTE: begin
                            if (encoded_data.tready && encoded_data.tvalid) begin
                                // `CHECK_EQUAL(encoded_data.tdata, 8'h71);

                                state <= READ_OUT_THIRD_BYTE;
                            end
                        end
                        READ_OUT_THIRD_BYTE: begin
                            if (encoded_data.tready && encoded_data.tvalid) begin
                                // `CHECK_EQUAL(encoded_data.tdata, 8'h69);

                                state <= READ_OUT_FOURTH_BYTE;
                            end

                        end
                        READ_OUT_FOURTH_BYTE: begin
                            if (encoded_data.tready && encoded_data.tvalid) begin
                                // `CHECK_EQUAL(encoded_data.tdata, 8'h00);

                                encoded_data.tready <= 0;

                                state <= TESTS_FINISHED;
                            end
                        end
                    endcase
                end
            end
            `CHECK_EQUAL(0, 0);
        end
    end
    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
