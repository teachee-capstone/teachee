`default_nettype none
`timescale 1ns / 1ps

import xadc_drp_package::*;

module xadc_drp_axis_adapter (
    // Xilinx XADC IP Interface (Only putting through the required signals)
    input var logic xadc_dclk,
    input var logic xadc_reset,

    // DRP Interface and Conversion Signals
    output xadc_drp_addr_t xadc_daddr,
    output var logic xadc_den,
    input var logic xadc_drdy,
    input var logic[XADC_DRP_DATA_WIDTH-1:0] xadc_do,
    input var logic xadc_eos,

    // ADC Channel AXI Streams
    axis_interface.Source current_monitor_channel,
    axis_interface.Source voltage_channel
);

    typedef enum int {
        XADC_AXIS_INIT,
        XADC_AXIS_AWAIT_EOS,
        XADC_AXIS_START_DRP_VOLTAGE_READ,
        XADC_AXIS_AWAIT_VOLTAGE_DATA,
        XADC_AXIS_SEND_TO_VOLTAGE_FIFO,
        XADC_AXIS_START_DRP_CURRENT_READ,
        XADC_AXIS_AWAIT_CURRENT_DATA,
        XADC_AXIS_SEND_TO_CURRENT_FIFO
    } xadc_drp_axis_adapter_state_t;

    xadc_drp_axis_adapter_state_t state = XADC_AXIS_INIT;

    // Define AXI Stream Interfaces
    // These interfaces will be tagged as sinks into the FIFO
    axis_interface #(
        .DATA_WIDTH(XADC_DRP_DATA_WIDTH)
    ) xadc_current_axis (
        .clk(xadc_dclk),
        .rst(xadc_reset)
    );

    axis_interface #(
        .DATA_WIDTH(XADC_DRP_DATA_WIDTH)
    ) xadc_voltage_axis (
        .clk(xadc_dclk),
        .rst(xadc_reset)
    );

    // Create Async FIFOs
    axis_async_fifo_wrapper #(
        .DEPTH(XADC_DRP_AXIS_FIFO_DEPTH),
        .DATA_WIDTH(XADC_DRP_DATA_WIDTH)
    ) xadc_current_fifo (
        .sink(xadc_current_axis.Sink),
        .source(current_monitor_channel)
    );

    axis_async_fifo_wrapper #(
        .DEPTH(XADC_DRP_AXIS_FIFO_DEPTH),
        .DATA_WIDTH(XADC_DRP_DATA_WIDTH)
    ) xadc_voltage_fifo (
        .sink(xadc_voltage_axis.Sink),
        .source(voltage_channel)
    );

    always_ff @(posedge xadc_dclk) begin
        case (state)
            XADC_AXIS_INIT: begin
                // Init both AXIS Sinks
                xadc_current_axis.tdata <= 0;
                xadc_current_axis.tvalid <= 0;

                xadc_voltage_axis.tdata <= 0;
                xadc_current_axis.tvalid <= 0;

                xadc_daddr <= XADC_DRP_ADDR_VOLTAGE_CHANNEL;
                xadc_den <= 0;

                state <= XADC_AXIS_AWAIT_EOS;
            end
            XADC_AXIS_AWAIT_EOS: begin
                if (xadc_eos) begin
                    xadc_daddr <= XADC_DRP_ADDR_VOLTAGE_CHANNEL;
                    xadc_den <= 1;

                    state <= XADC_AXIS_START_DRP_VOLTAGE_READ;
                end
            end
            XADC_AXIS_START_DRP_VOLTAGE_READ: begin
                xadc_den <= 0;

                state <= XADC_AXIS_AWAIT_VOLTAGE_DATA;
            end
            XADC_AXIS_AWAIT_VOLTAGE_DATA: begin
                if (xadc_drdy) begin
                    xadc_voltage_axis.tdata <= xadc_do;
                    xadc_voltage_axis.tvalid <= 1;

                    state <= XADC_AXIS_SEND_TO_VOLTAGE_FIFO;
                end 
            end
            XADC_AXIS_SEND_TO_VOLTAGE_FIFO: begin
                if (xadc_voltage_axis.tready && xadc_voltage_axis.tvalid) begin
                    xadc_voltage_axis.tvalid <= 0;
                    state <= XADC_AXIS_START_DRP_CURRENT_READ;
                end
            end
            XADC_AXIS_START_DRP_CURRENT_READ: begin
                xadc_daddr <= XADC_DRP_ADDR_CURRENT_CHANNEL;
                xadc_den <= 1;

                state <= XADC_AXIS_AWAIT_CURRENT_DATA;
            end
            XADC_AXIS_AWAIT_CURRENT_DATA: begin
                xadc_den <= 0;
                if (xadc_drdy) begin
                    xadc_current_axis.tdata <= xadc_do;
                    xadc_current_axis.tvalid <= 1;

                    state <= XADC_AXIS_SEND_TO_CURRENT_FIFO;
                end
            end
            XADC_AXIS_SEND_TO_CURRENT_FIFO: begin
                if (xadc_current_axis.tready && xadc_current_axis.tvalid) begin
                    xadc_current_axis.tvalid <= 0;

                    state <= XADC_AXIS_AWAIT_EOS;
                end
            end
        endcase
    end

    // Set default values for the unused AXIS signals
    always begin
        xadc_current_axis.tlast <= 1;
        xadc_current_axis.tkeep <= '1;
        xadc_current_axis.tid <= '0;
        xadc_current_axis.tuser <= '0;
        xadc_current_axis.tdest <= '0;

        xadc_voltage_axis.tlast <= 1;
        xadc_voltage_axis.tkeep <= '1;
        xadc_voltage_axis.tid <= '0;
        xadc_voltage_axis.tuser <= '0;
        xadc_voltage_axis.tdest <= '0;
    end
endmodule

`default_nettype wire
