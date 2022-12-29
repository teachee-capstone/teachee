package teachee_defs;
    typedef enum logic[6:0] {
        XADC_DRP_ADDR_CURRENT_CHANNEL = 7'h14,
        XADC_DRP_ADDR_VOLTAGE_CHANNEL = 7'h1c
    } xadc_drp_addr_t;
    // add more shared typedefs here as needed
endpackage