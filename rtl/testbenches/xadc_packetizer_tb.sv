`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

import xadc_drp_package::*;

module xadc_packetizer_tb;

    var logic reset;
    var logic clk;

    always begin
        #10
        clk <= !clk;
    end

    // Define AXIS interfaces for the packetizer
    axis_interface #(
        .DATA_WIDTH(XADC_DRP_DATA_WIDTH)
    ) voltage_channel (
        .clk(clk),
        .rst(reset)
    );

    axis_interface #(
        .DATA_WIDTH(XADC_DRP_DATA_WIDTH)
    ) current_monitor_channel (
        .clk(clk),
        .rst(reset)
    );

    axis_interface #(
        .DATA_WIDTH(8)
    ) cobs_stream (
        .clk(clk),
        .rst(reset)
    );

    // Declare XADC BFM and AXIS Adapter
    xadc_drp_addr_t xadc_daddr;
    var logic xadc_den;
    var logic xadc_drdy;
    var logic[XADC_DRP_DATA_WIDTH-1:0] xadc_do;
    var logic xadc_eos;

    xadc_bfm xadc (
        .dclk_in(clk),
        .reset_in(reset),

        // DRP
        .di_in(0),
        .daddr_in(xadc_daddr),
        .den_in(xadc_den),
        .dwe_in(0),
        .drdy_out(xadc_drdy),
        .do_out(xadc_do),

        .vp_in(0),
        .vn_in(0),

        .vauxp4(0),
        .vauxn4(0),
        .vauxp12(0),
        .vauxn12(0),

        .channel_out(),
        .eoc_out(),

        .alarm_out(),
        .eos_out(xadc_eos),
        .busy_out()
    );

    xadc_drp_axis_adapter xadc_axis_adapter (
        .xadc_dclk(clk),
        .xadc_reset(reset),

        // DRP
        .xadc_daddr(xadc_daddr),
        .xadc_den(xadc_den),
        .xadc_drdy(xadc_drdy),
        .xadc_do(xadc_do),
        .xadc_eos(xadc_eos),

        // AXIS OUTPUTS
        .current_monitor_channel(current_monitor_channel.Source),
        .voltage_channel(voltage_channel.Source)

    );

    xadc_packetizer DUT (
        .voltage_channel(voltage_channel.Sink),
        .current_monitor_channel(current_monitor_channel.Sink),
        .packet_stream(cobs_stream)
    );

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            // what would normally go in an initial block we can put here
            clk = 0;
            reset = 0;
            cobs_stream.tready = 1;
        end

        `TEST_CASE("VERIFY_COBS_VOLTAGE_CURRENT_PACKETS") begin
            // if we stick these two values into a cobs encoder we get the
            // following byte sequence we can check

            // input sequence
            // 0x00 0x0F 0x00 0x07

            // output sequence
            // 0x01 0x02 0x0F 0x02 0x07 0x00


            automatic int bytes_consumed = 0;
            while (bytes_consumed < 6) begin
                @(posedge clk) begin
                    if (cobs_stream.tready && cobs_stream.tvalid) begin
                        bytes_consumed = bytes_consumed + 1;
                        case (bytes_consumed)
                            1: begin
                                `CHECK_EQUAL(cobs_stream.tdata, 'h01);
                            end
                            2: begin
                                `CHECK_EQUAL(cobs_stream.tdata, 'h02);
                            end
                            3: begin
                                `CHECK_EQUAL(cobs_stream.tdata, 'h0F);
                            end
                            4: begin
                                `CHECK_EQUAL(cobs_stream.tdata, 'h02);
                            end
                            5: begin
                                `CHECK_EQUAL(cobs_stream.tdata, 'h07);
                            end
                            6: begin
                                `CHECK_EQUAL(cobs_stream.tdata, 'h00);
                            end
                        endcase
                    end
                end
            end
            // Placeholder until full TB is implemented
        end
    end

    `WATCHDOG(1ms);
endmodule

`default_nettype wire
