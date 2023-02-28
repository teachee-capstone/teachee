`default_nettype none
`timescale 1ns / 1ps

import xadc_drp_package::*;

module xadc_drp_axis_single_stream (
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
    axis_interface.Source sample_stream
);

    typedef enum int {
        XADC_AXIS_INIT,
        XADC_AXIS_AWAIT_EOS,
        XADC_AXIS_START_DRP_VOLTAGE_READ,
        XADC_AXIS_AWAIT_VOLTAGE_DATA,
        XADC_AXIS_STORE_VOLTAGE_DATA,
        XADC_AXIS_START_DRP_CURRENT_READ,
        XADC_AXIS_AWAIT_CURRENT_DATA,
        XADC_AXIS_SEND_TO_SAMPLE_FIFO
    } xadc_drp_axis_adapter_state_t;

    xadc_drp_axis_adapter_state_t state = XADC_AXIS_INIT;

    // Define AXI Stream Interfaces
    // These interfaces will be tagged as sinks into the FIFO
    axis_interface #(
        .DATA_WIDTH(2 * XADC_DRP_DATA_WIDTH)
    ) xadc_sample_data_axis (
        .clk(xadc_dclk),
        .rst(xadc_reset)
    );

    // Create Async FIFOs
    axis_async_fifo_wrapper #(
        .DEPTH(XADC_DRP_AXIS_FIFO_DEPTH),
        .DATA_WIDTH(2 * XADC_DRP_DATA_WIDTH),
        .KEEP_ENABLE(0)
    ) xadc_current_fifo (
        .sink(xadc_sample_data_axis.Sink),
        .source(sample_stream)
    );

    var logic [XADC_DRP_DATA_WIDTH-1:0] voltage_sample;
    always_ff @(posedge xadc_dclk) begin
        case (state)
            XADC_AXIS_INIT: begin
                // Init both AXIS Sinks
                xadc_sample_data_axis.tdata <= 0;
                xadc_sample_data_axis.tvalid <= 0;
                xadc_sample_data_axis.tlast <= 1;
                xadc_sample_data_axis.tkeep <= 0;

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
                    voltage_sample <= xadc_do;

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
                    xadc_sample_data_axis.tdata[XADC_DRP_DATA_WIDTH-1:0] <= xadc_do;
                    xadc_sample_data_axis.tdata[2*XADC_DRP_DATA_WIDTH - 1:XADC_DRP_DATA_WIDTH] <= voltage_sample;
                    xadc_sample_data_axis.tvalid <= 1;

                    state <= XADC_AXIS_SEND_TO_SAMPLE_FIFO;
                end
            end
            XADC_AXIS_SEND_TO_SAMPLE_FIFO: begin
                if (xadc_sample_data_axis.tready && xadc_sample_data_axis.tvalid) begin
                    xadc_sample_data_axis.tvalid <= 0;

                    state <= XADC_AXIS_AWAIT_EOS;
                end
            end
        endcase
    end

    // Set default values for the unused AXIS signals
    always_comb begin
        xadc_sample_data_axis.tlast = 1;
        xadc_sample_data_axis.tkeep = '1;
        xadc_sample_data_axis.tid = '0;
        xadc_sample_data_axis.tuser = '0;
        xadc_sample_data_axis.tdest = '0;
    end
endmodule

`default_nettype wire
