`default_nettype none

package xadc_packet_package;
    parameter XADC_PACKET_HEADER_WIDTH = 4;

    typedef enum logic[XADC_PACKET_HEADER_WIDTH-1:0] {
        // Indicates that the sample contains the low speed current and voltage
        // channel readings
        XADC_PACKET_HEADER_LOW_SPEED_SAMPLE = 4'h1,
        
        // Indicates that the packet is bundling the fast samples from the two
        // highspeed ADC channels
        XADC_PACKET_HEADER_HIGHSPEED_SAMPLE = 4'h3
    } xadc_packet_header_t;
endpackage

`default_nettype wire