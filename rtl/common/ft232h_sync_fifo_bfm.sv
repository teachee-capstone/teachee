
// Input into FT232H from FPGA
// Output from FT232H to FPGA
// Receive into FT232H from Host or from FT232H to FPGA
// Transmit from FT232H to Host or into FPGA from FT232H

module ft232h_sync_fifo_bfm (
    output logic clk,
    inout [9:0] io_acbus,
    inout [7:0] io_adbus,
    input       i_ft232h_reset_n,

    // TB interface
    output [7:0] o_host_data,
    input i_host_write_en,
    output o_host_full,
    input [7:0] i_host_data,
    input i_host_read_en,
    output o_host_empty
);
    initial begin
        clk = 0;
    end

    always begin
        #8.333
        clk = !clk;
    end

    logic [7:0] adbus_output;
    logic rxf_n;
    logic txe_n;

    /* io_acbus inputs - Start */
    logic fpga_read_en_n;
    assign fpga_read_en_n = io_acbus[2];
    logic fpga_write_en_n;
    assign fpga_write_en_n = io_acbus[3];

    logic oe_n_reg;

    always_ff @(posedge clk or negedge i_ft232h_reset_n) begin : proc_
        if(!i_ft232h_reset_n) begin
            oe_n_reg <= 1'b1;
        end else begin
            oe_n_reg <= io_acbus[6];
        end
    end
    /* io_acbus inputs - End */

    // 1024 Byte Receive FIFO - Host -> FPGA
    fifo # (
        .ADDR_WIDTH(10       ),
        .DATA_WIDTH(8        )
    ) receive_fifo (
        .clk     (clk              ),
        .reset   (!i_ft232h_reset_n),
        .din     (i_host_data      ), // Insert from testbench
        .dout    (adbus_output     ),
        .write_en(i_host_write_en  ),
        .read_en (!fpga_read_en_n  ),
        .full    (o_host_full      ),
        .empty   (rxf_n            ),
        .level   (                 )
    );

    logic [7:0] rx_data;
    always_ff @(posedge clk) begin
        rx_data <= adbus_output;
    end

    // 1024 Byte Transmit FIFO - FPGA -> Host
    fifo # (
        .ADDR_WIDTH(10       ),
        .DATA_WIDTH(8        ),
        .INITIAL_FIFO_LEVEL(0)
        //.INITIAL_DATA('{(2**10){'1}})
    ) transmit_fifo (
        .clk     (clk              ),
        .reset   (!i_ft232h_reset_n),
        .din     (io_adbus         ),
        .dout    (o_host_data      ), // Print as if host
        .write_en(!fpga_write_en_n ),
        .read_en (i_host_read_en   ),
        .full    (txe_n            ),
        .empty   (o_host_empty     ),
        .level   (                 )
    );

    // FT245 Sync FIFO Mode (Input/Output referenced from FT232H's prespective)
    // ACBUS[0] - rxf_n   - Output - low = FIFO not empty
    // ACBUS[1] - txe_n   - Output - low = FIFO not full
    // ACBUS[2] - rd_n    - Input
    // ACBUS[3] - wr_n    - Input
    // ACBUS[4] - siwu_n  - Input
    // ACBUS[5] - clkout  - Output
    // ACBUS[6] - oe_n    - Input

    logic clkout;
    assign clkout = clk;

    assign io_acbus[0] = rxf_n;
    assign io_acbus[1] = txe_n;
    assign io_acbus[2] = 1'bZ;
    assign io_acbus[3] = 1'bZ;
    assign io_acbus[4] = 1'bZ;
    assign io_acbus[5] = i_ft232h_reset_n ? clkout : 0;
    assign io_acbus[6] = 1'bZ;
    assign io_acbus[7] = 1'bZ;
    assign io_acbus[8] = 1'bZ;
    assign io_acbus[9] = 1'bZ;

    assign io_adbus = oe_n_reg ? 8'bzzzz_zzzz : rx_data;
endmodule