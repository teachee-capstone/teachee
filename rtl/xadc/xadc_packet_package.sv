`default_nettype none

package xadc_packet_package;
    parameter XADC_PACKET_HEADER_WIDTH = 4;

    typedef enum logic[XADC_PACKET_HEADER_WIDTH-1:0] {
        XADC_PACKET_HEADER_VOLTAGE_SAMPLE = 4'h1,
        XADC_PACKET_HEADER_CURRENT_SAMPLE = 4'h3
    } xadc_packet_header_t;
endpackage

`default_nettype wire