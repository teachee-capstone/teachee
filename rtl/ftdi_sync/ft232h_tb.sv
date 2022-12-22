`default_nettype none

module ft232h_tb;

    wire [9:0] io_acbus;
    wire [7:0] io_adbus;

    var logic ft232h_reset_n;
    var logic [7:0] o_host_data;
    var logic host_write_en;
    var logic host_full;
    var logic [7:0] host_data;
    var logic host_read_en;
    var logic host_empty;

    ft232h_sync_fifo_bfm i_ft232h_sync_fifo_bfm (
        .io_acbus        (io_acbus        ),
        .io_adbus        (io_adbus        ),
        .i_ft232h_reset_n(ft232h_reset_n),
        .o_host_data     (o_host_data ),
        .i_host_write_en (host_write_en ),
        .o_host_full     (host_full     ),
        .i_host_data     (host_data  ),
        .i_host_read_en  (host_read_en  ),
        .o_host_empty    (host_empty    )
    );

    var logic sys_clk;
    initial begin
        sys_clk = 0;
    end
    // init FTDI clock (assuming this is coming from)
    always begin
        #5
        sys_clk = ~sys_clk;
    end


    // Initialize my module and test it against the BFM.
    var logic[7:0] write_data;
    var logic write_valid;

    var logic read_en;
    wire read_valid;
    ft232h DUT (
        .clk(sys_clk),

        .rxf_n(io_acbus[0]),
        .txe_n(io_acbus[1]),

        .rd_n(io_acbus[2]),
        .wr_n(io_acbus[3]),
        .siwu_n(io_acbus[4]),
        .oe_n(io_acbus[6]),

        .data(io_adbus),

        .write_data(write_data),
        .write_valid(write_valid),

        .read_en(read_en),
        .read_valid(read_valid)
    );


typedef enum int {
    RESET,
    IDLE,
    WRITE_SETUP,
    WRITING,
    READ_SETUP,
    READING,
    DONE
} tb_state_t;

tb_state_t tb_state = RESET;

always @(posedge sys_clk) begin
    case (tb_state)
        RESET: begin
            host_write_en <= 0;
            host_read_en <= 0;

            ft232h_reset_n <= 0;
            
            tb_state <= IDLE;
        end
        IDLE: begin
            ft232h_reset_n <= 1;

            tb_state <= WRITE_SETUP;
        end
        WRITE_SETUP: begin
            write_data <= 69; // Write Character E
            write_valid <= 1;
            tb_state <= WRITING;
        end
        WRITING: begin
            write_valid <= 0;
            host_read_en <= 1;
            tb_state <= READING;
        end
        READING: begin
            host_read_en <= 0;
            tb_state <= RESET;
            $stop;
        end
    endcase
end
endmodule

`default_nettype wire
