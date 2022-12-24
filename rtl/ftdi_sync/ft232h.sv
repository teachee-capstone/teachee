`default_nettype none
`timescale 1ns / 1ps

module ft232h (
    input var logic ftdi_clk,

    // Control Inputs
    input var logic ftdi_rxf_n,
    input var logic ftdi_txe_n,

    // Control Outputs
    output var logic ftdi_rd_n,
    output var logic ftdi_wr_n,
    output var logic ftdi_siwu_n,
    output var logic ftdi_oe_n,

    // Data Bus
    output var logic[7:0] ftdi_adbus,

    // Programmer AXIS Interface
    axis_input_io sys_axis
);

// Define states for the device
typedef enum int {
    INIT,
    AWAIT_USB_HOST,
    SEND_TO_USB_HOST
} ftdi_state_t;

ftdi_state_t state;

// AXIS stream we will write to the FT232H
axis_output_io ftdi_axis;
assign ftdi_axis.clk = ftdi_clk;
assign ftdi_data = ftdi_axis.tdata;

axis_async_fifo_wrapper #(
    .DEPTH(2),
    .DATA_WIDTH(8)
) fpga_to_host_fifo (
    .axis_input(sys_axis),
    .axis_output(ftdi_axis)
);

// AXI Stream consumer state machine that sends data to FTDI
always_ff @(posedge ftdi_axis.clk) begin
    // Run the control state machine here
    case (state)
        INIT: begin
            // Init signals into disabled state
            ftdi_rd_n <= 1;
            ftdi_wr_n <= 1;
            ftdi_siwu_n <= 1;
            ftdi_oe_n <= 1;

            state <= WRITE_AWAIT;
        end
        AWAIT_USB_HOST: begin
            if (!ftdi_txe_n && ftdi_axis.tvalid) begin
                ftdi_wr_n <= 0;
                ftdi_axis.tready <= 1;
                state <= SEND_TO_USB_HOST;
            end
        end
        SEND_TO_USB_HOST: begin
            // If we fail the send condition. roll back to await state
            if (!(!ftdi_txe_n && ftdi_axis.tvalid && ftdi_axis.tready)) begin
                ftdi_wr_n <= 1;
                ftdi_axis.tready <= 0;
                state <= AWAIT_USB_HOST;
            end
        end 
        default: state <= INIT;
    endcase
end

endmodule

`default_nettype wire
