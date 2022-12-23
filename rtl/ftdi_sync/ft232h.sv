`default_nettype none
`timescale 1ns / 1ps

module ft232h (
    input var logic ftdi_clk,

    // Control Inputs
    input var logic rxf_n,
    input var logic txe_n,

    // Control Outputs
    output var logic rd_n,
    output var logic wr_n,
    output var logic siwu_n,
    output var logic oe_n,

    // Data Bus
    output var logic[7:0] data,

    // Programmer AXIS Interface
    input wire sys_clk,
    input wire internal_fifo_rst,
    input wire[7:0] tdata,
    input wire tvalid,
    output wire tready
);

// Define states for the device
typedef enum int {
    INIT,
    WRITE_AWAIT,
    WRITING,
    IDLE
} ftdi_state_t;

ftdi_state_t state;

// AXIS FIFO input interface
// Overall flow is AXIS async FIFO -> ftdi module -> PC
wire[7:0] write_data;
wire fifo_out_valid;
axis_async_fifo #(
    .DEPTH(2),
    .DATA_WIDTH(8)
) tx_fifo (
    // AXI Stream Input
    .s_clk(sys_clk),
    .s_rst(internal_fifo_rst),
    .s_axis_tdata(tdata),
    .s_axis_tvalid(tvalid),
    .s_axis_tready(tready),

    // AXI Stream Output
    .m_clk(ftdi_clk),
    .m_rst(internal_fifo_rst),
    // .m_axis_tdata(data), // connect directly to the FTDI output
    .m_axis_tdata(write_data),
    .m_axis_tvalid(fifo_out_valid),
    .m_axis_tready(~wr_n)
);

always_ff @(posedge ftdi_clk) begin
    // Run the control state machine here
    case (state)
        INIT: begin
            // Init signals into disabled state
            rd_n <= 1;
            wr_n <= 1;
            siwu_n <= 1;
            oe_n <= 1;

            state <= WRITE_AWAIT;
        end
        WRITE_AWAIT: begin
            // State to await the conditions to write to the FTDI
            if (fifo_out_valid && !txe_n) begin
                wr_n <= 0;
                data <= write_data;
                state <= WRITING;
            end
        end
        WRITING: begin
            // TEST: Write only one byte a time

            wr_n <= 1;
            state <= IDLE;

            // Keep writing as long as FTDI or async FIFO allows
            // if (!(fifo_out_valid && !txe_n)) begin
            //     wr_n <= 1;
            //     state <= IDLE;
            // end else begin
            //     data <= write_data;
            // end
        end 
        IDLE: begin
            if (fifo_out_valid) begin
                // Start write process again when we have data in the fifo
                state <= WRITE_AWAIT;
            end
        end
        default: state <= IDLE;
    endcase
end

endmodule

`default_nettype wire
