`timescale 1ns/1ps

module tb_ft232h_sync_fifo_bfm ();

    wire [9:0] io_acbus;
    wire [7:0] io_adbus;

    logic i_ft232h_reset_n;
    logic [7:0] o_host_data;
    logic i_host_write_en;
    logic o_host_full;
    logic [7:0] i_host_data;
    logic i_host_read_en;
    logic o_host_empty;

    logic reset;

    initial begin
        reset = 0;
        #100
        reset = 1;
        #100
        reset = 0;
    end

    ft232h_sync_fifo_bfm i_ft232h_sync_fifo_bfm (
        .io_acbus        (io_acbus        ),
        .io_adbus        (io_adbus        ),
        .i_ft232h_reset_n(i_ft232h_reset_n),
        .o_host_data     (o_host_data ),
        .i_host_write_en (i_host_write_en ),
        .o_host_full     (o_host_full     ),
        .i_host_data     (i_host_data  ),
        .i_host_read_en  (i_host_read_en  ),
        .o_host_empty    (o_host_empty    )
    );

    logic fpga_clk = 0;

    always begin
        #5
        fpga_clk = ~fpga_clk;
    end

    
    ft232h_sync_fifo i_ft232h_sync_fifo (
        .i_clk           (fpga_clk        ),
        .i_reset         (reset           ),
        .io_acbus        (io_acbus        ),
        .io_adbus        (io_adbus        ),
        .o_ft232h_reset_n(i_ft232h_reset_n)
    );


    always_ff @(posedge io_acbus[5] or negedge i_ft232h_reset_n) begin : proc_
        if(!i_ft232h_reset_n) begin
            i_host_write_en <= 0;
            i_host_read_en <= 0;
        end else begin

            if (!o_host_full) begin
                i_host_write_en <= 1;
                i_host_data <= $urandom_range(0,255);
            end else begin
                i_host_write_en <= 0;
            end

            if (!o_host_empty) begin
                i_host_read_en <= 1;
                $display("HOST Received Data: %d", o_host_data);
            end else begin
                i_host_read_en <= 0;
            end
        end
    end

endmodule