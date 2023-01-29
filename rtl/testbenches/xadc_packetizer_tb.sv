`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

import xadc_drp_package::*;
import xadc_packet_package::*;

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
        .di_in(),
        .daddr_in(xadc_daddr),
        .den_in(xadc_den),
        .dwe_in(),
        .drdy_out(xadc_drdy),
        .do_out(xadc_do),

        .vp_in(),
        .vn_in(),

        .vauxp4(),
        .vauxn4(),
        .vauxp12(),
        .vauxn12(),

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
        end

        `TEST_CASE("VERIFY_COBS_VOLTAGE_CURRENT_PACKETS") begin
            // Placeholder until full TB is implemented
            @(posedge clk) `CHECK_EQUAL(0, 0);
        end
    end


    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire