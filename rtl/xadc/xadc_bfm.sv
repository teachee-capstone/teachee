`default_nettype none
`timescale 1ns / 1ps

import xadc_drp_package::*;

// Read only BFM for the XADC in the CMOD A7 35T This module mocks the DRP and
// status signals provided by the xilinx IP wizard. It is assumed that the
// wizard was set to convert channels 4 and 12 continuously. NOTE: this BFM only
// triggers the EOS signal, it will need to be revised if single conversions are
// used.
module xadc_bfm (
    // Clock and reset
    input var logic dclk_in,
    input var logic reset_in,

    // DRP Interface
    input var logic[XADC_DRP_DATA_WIDTH-1:0] di_in, // DRP Data In
    input var logic[XADC_DRP_AXIS_ADDR_WIDTH-1:0] daddr_in, // DRP reg address in
    input var logic den_in, // DRP read enable
    input var logic dwe_in, // DRP write enable (not used in this bfm)
    output var logic drdy_out, // rising edge when data is on the output bus
    output var logic[XADC_DRP_DATA_WIDTH-1:0] do_out,

    // Dedicated Analog Input channel (not used)
    input var logic vp_in,
    input var logic vn_in,

    // Analog input channels. In the real module we will connect these to the
    // pins where the analog voltage is. However, in the BFM they can be left
    // disconnected as we will generate fake conversions
    input var logic vauxp4,
    input var logic vauxn4,
    input var logic vauxp12,
    input var logic vauxn12,

    // Conversion status signals
    output var logic[4:0] channel_out,
    output var logic eoc_out, // Indicates end of an ADC conversion

    // Logical OR of all alarms in the xadc peripheral. I disable all of these
    // so it should never go high.
    output var logic alarm_out,
    // Indicates end of a sequence of conversions. In this case, goes high after
    // both channels 4 and 12 have been sampled.
    output var logic eos_out,
    output var logic busy_out // busy flag indicating a conversion in progress
);

    typedef enum int {
        INIT,
        IDLE,
        PULSE_EOS,
        AWAIT_READ_REQUEST,
        READ_WAIT_CYCLE, // DRP will not have data right away so we will waste a cycle here
        PREP_READ_DATA, // Select the correct output data based on the address input
        SHOW_READ_DATA
    } xadc_bfm_state_t;

    xadc_bfm_state_t state;

    // Internal registers for fake data samples
    var logic[XADC_DRP_DATA_WIDTH-1:0] vaux4_conv;
    var logic[XADC_DRP_DATA_WIDTH-1:0] vaux12_conv;
    var logic[XADC_DRP_DATA_WIDTH-1:0] conv_value; // Changes between vaux4 and vaux12 depending on address given.

    always_ff @(posedge dclk_in) begin
        if (reset_in) begin
            state <= INIT;
        end else begin
            case (state)
                INIT: begin
                    // Set initial states for outputs and then transition into
                    // operating mode
                    drdy_out <= 0;
                    do_out <= 16'h00_00;
                    channel_out <= 5'b00000;
                    eoc_out <= 0;
                    eos_out <= 0;
                    alarm_out <= 0;
                    busy_out <= 0;

                    // Set internal registers
                    vaux12_conv <= 255;
                    vaux4_conv <= 127;
                    conv_value <= 0;

                    // Proceed to next state
                    state <= IDLE;
                end
                IDLE: begin
                    // set eos pulse for the next cycle and transition
                    eos_out <= 1;
                    state <= PULSE_EOS;
                end
                PULSE_EOS: begin
                    // Hold the EOS high for one cycle
                    eos_out <= 0;
                    state <= AWAIT_READ_REQUEST;
                end
                AWAIT_READ_REQUEST: begin
                    if (den_in) begin
                        // check the address provided and load the conversion reg
                        // TODO: These addresses should come from an include
                        if (daddr_in == XADC_DRP_ADDR_CURRENT_CHANNEL) begin
                            // if we are reading the current sensor
                            conv_value <= vaux4_conv;
                        end else if (daddr_in == XADC_DRP_ADDR_VOLTAGE_CHANNEL) begin
                            conv_value <= vaux12_conv;
                        end else begin
                            $display("Unknown Address provided");
                        end 
                        state <= READ_WAIT_CYCLE;
                    end
                end 
                READ_WAIT_CYCLE: state <= PREP_READ_DATA;
                PREP_READ_DATA: begin
                    // Set ready and data_output signals
                    drdy_out <= 1;
                    do_out <= conv_value;
                    state <= SHOW_READ_DATA;
                end
                SHOW_READ_DATA: begin
                    drdy_out <= 0;
                    do_out <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
