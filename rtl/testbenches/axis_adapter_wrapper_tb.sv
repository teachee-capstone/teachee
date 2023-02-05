`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module axis_adapter_wrapper_tb;

    var logic reset = 0;
    var logic clk;

    typedef enum int {
        SEND_ORIGINAL_DATA,
        READ_OUT_FIRST_BYTE,
        READ_OUT_SECOND_BYTE,
        TESTS_FINISHED
    } axis_adapter_wrapper_tb_state_t;

    axis_adapter_wrapper_tb_state_t state = SEND_ORIGINAL_DATA;

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

    axis_adapter_wrapper #(
        .S_DATA_WIDTH(16),
        .M_DATA_WIDTH(8)
    ) DUT (
        .original_data(original_data.Sink),
        .modified_width_data(modified_width_data.Source)
    );

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            // what would normally go in an initial block we can put here
            clk = 0;
            reset = 0;

            original_data.tdata = 16'h6971;
            original_data.tvalid = 0;
            original_data.tlast = 1;
            original_data.tuser = 0;
            original_data.tkeep <= '1;
            original_data.tid <= '0;
            original_data.tdest <= '0;

            modified_width_data.tready = 0;
        end

        `TEST_CASE("VIEW_REDUCED_WIDTH STREAM") begin
            while (state != TESTS_FINISHED) begin
                @(posedge clk) begin
                    case (state)
                        SEND_ORIGINAL_DATA: begin
                            original_data.tvalid <= 1;
                            if (original_data.tready && original_data.tvalid) begin
                                modified_width_data.tready <= 1;
                                original_data.tvalid <= 0;

                                state <= READ_OUT_FIRST_BYTE;
                            end
                        end
                        READ_OUT_FIRST_BYTE: begin
                            if (modified_width_data.tready && modified_width_data.tvalid) begin
                                `CHECK_EQUAL(modified_width_data.tdata, 8'h71);

                                state <= READ_OUT_SECOND_BYTE;
                            end
                        end
                        READ_OUT_SECOND_BYTE: begin
                            if (modified_width_data.tready && modified_width_data.tvalid) begin
                                `CHECK_EQUAL(modified_width_data.tdata, 8'h69);
                                modified_width_data.tready <= 0;

                                state <= TESTS_FINISHED;
                            end
                        end
                    endcase
                end
            end
        end
    end
    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
