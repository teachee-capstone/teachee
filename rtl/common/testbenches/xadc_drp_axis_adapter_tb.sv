`default_nettype none
`timescale 1ns / 1ps


module xadc_drp_axis_adapter_tb;
    typedef enum int {
        READ_VOLTAGE_SAMPLE,
        VIEW_VOLTAGE_SAMPLE,
        READ_CURRENT_SAMPLE,
        VIEW_CURRENT_SAMPLE,
        DONE
    } xadc_drp_axis_adapter_tb_state_t;    

    typedef enum logic[6:0] {
        XADC_DRP_ADDR_CURRENT_CHANNEL = 7'h14,
        XADC_DRP_ADDR_VOLTAGE_CHANNEL = 7'h1c
    } xadc_drp_addr_t;
    xadc_drp_axis_adapter_tb_state_t state;

    var logic xadc_dclk;
    var logic xadc_reset;
    xadc_drp_addr_t xadc_daddr;
    var logic xadc_den;

    var logic xadc_drdy;
    var logic[15:0] xadc_do;
    var logic xadc_eos;

    initial begin
        xadc_dclk = 0;
        xadc_reset = 0;

        voltage_channel.tready = 1;
        current_monitor_channel.tready = 1;
    end

    always begin
        #10
        xadc_dclk = ~xadc_dclk;
    end
    
    // Create AXI interfaces to connect up to adapter outputs
    axis_io #(
        .DATA_WIDTH(16)
    ) voltage_channel (
        .clk(xadc_dclk),
        .rst(0)
    );

    axis_io #(
        .DATA_WIDTH(16)
    ) current_monitor_channel (
        .clk(xadc_dclk),
        .rst(0)
    );

    xadc_drp_fake fake_xadc_adapter (
        .current_monitor_channel(current_monitor_channel.Source)
    );
    // xadc_drp_axis_adapter adapter_dut (
    //     // .xadc_dclk(xadc_dclk),
    //     // .xadc_reset(0), 

    //     // // DRP and Conversion Signals
    //     // .xadc_daddr(xadc_daddr),
    //     // .xadc_den(xadc_den),
    //     // .xadc_drdy(xadc_drdy),
    //     // .xadc_do(xadc_do),

    //     // .xadc_eos(xadc_eos),

    //     .currrent_monitor_channel(current_monitor_channel.Source)
    //     // .voltage_channel(voltage_channel.Source)
    // );

    xadc_bfm xadc_bfm_inst (
        // Clock and reset
        .dclk_in(xadc_dclk),
        .reset_in(xadc_reset),

        // DRP interface (Reduced to read only in this tb)
        .di_in(0), // not used since we are not writing
        .daddr_in(xadc_daddr),
        .den_in(xadc_den),
        .dwe_in(0), // write enable is also not used
        .drdy_out(xadc_drdy),
        .do_out(xadc_do),

        // Must be connected in the real xadc IP core
        .vp_in(0),
        .vn_in(0),

        // Analog input channels (also need to be connected in real IP core)
        .vauxp4(0),
        .vauxn4(0),
        .vauxp12(0),
        .vauxn12(0),

        // conversion status signals
        .channel_out(),
        .eoc_out(),
        .alarm_out(), // not used
        .eos_out(xadc_eos),
        .busy_out()
    );

    // always @(posedge xadc_dclk) begin
    //     case (state)
    //         READ_VOLTAGE_SAMPLE: begin
    //             if (voltage_channel.tready && voltage_channel.tvalid) begin
    //                 state <= VIEW_VOLTAGE_SAMPLE;
    //             end
    //         end
    //         VIEW_VOLTAGE_SAMPLE: begin
    //             state <= READ_CURRENT_SAMPLE;
    //         end
    //         READ_CURRENT_SAMPLE: begin
    //             if (current_monitor_channel.tready && current_monitor_channel.tvalid) begin
    //                 state <= VIEW_CURRENT_SAMPLE;
    //             end
    //         end
    //         VIEW_CURRENT_SAMPLE: begin
    //             state <= DONE;
    //         end
    //         DONE: begin
    //             $stop;
    //         end
    //     endcase
    // end
endmodule

`default_nettype wire