package xadc_drp_package;
    parameter XADC_DRP_DATA_WIDTH = 16;
    parameter XADC_DRP_AXIS_FIFO_DEPTH = 128;
    parameter XADC_DRP_AXIS_ADDR_WIDTH = 7;

    typedef enum logic[XADC_DRP_AXIS_ADDR_WIDTH-1:0] {
        XADC_DRP_ADDR_CURRENT_CHANNEL = 7'h14,
        XADC_DRP_ADDR_VOLTAGE_CHANNEL = 7'h1c
    } xadc_drp_addr_t;
endpackage