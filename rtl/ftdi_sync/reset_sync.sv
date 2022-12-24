// Module to sync our reset signal to the 60 MHz domain

module reset_sync (
    input logic reset_in,
    input logic destination_clk,
    output logic reset_out
);

xpm_cdc_sync_rst #(
   .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
   .INIT(1),           // DECIMAL; 0=initialize synchronization registers to 0, 1=initialize synchronization
                       // registers to 1
   .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
   .SIM_ASSERT_CHK(0)  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
)
xpm_cdc_sync_rst_inst (
   .dest_rst(reset_out), // 1-bit output: src_rst synchronized to the destination clock domain. This output
                        // is registered.

   .dest_clk(destination_clk), // 1-bit input: Destination clock.
   .src_rst(reset_in)    // 1-bit input: Source reset signal.
);

endmodule