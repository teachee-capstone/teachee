`default_nettype none
`timescale 1ns / 1ps

// Test bench for the TX only BFM
// timed_tb ftdi_sync ft232h_bfm_tb {state clk rxf_n txe_n rd_n wr_n siwu_n oe_n rst_n write_data tdata tvalid tready pc_data}
module ft232h_bfm_tb;

    typedef enum int {
        INIT,
        RESET,
        WRITE_AWAIT,
        WRITING,
        CHECK_ON_PC,
        READ_OUT,
        DONE
    } ft232h_bfm_tb_state_t;

    wire clk;

    wire rxf_n;
    wire txe_n;

    var logic rd_n;
    var logic wr_n;
    var logic siwu_n;
    var logic oe_n;
    var logic rst_n;

    var logic[7:0] write_data;

    // PC Side wires (FIFO output)
    wire[7:0] tdata;
    wire tvalid;
    var logic tready;

    ft232h_bfm_tb_state_t state;
    initial begin
        rd_n = 1;
        wr_n = 1;
        siwu_n = 1;
        oe_n = 1;
        rst_n = 1;

        tready = 0;
        state = INIT;
    end

    ft232h_bfm ftdi (
        .clk(clk),

        .rxf_n(rxf_n),
        .txe_n(txe_n),

        .rd_n(rd_n),
        .wr_n(wr_n),
        .siwu_n(siwu_n),
        .oe_n(oe_n),
        .rst_n(rst_n),

        .data(write_data),

        // PC Side Signals (FIFO output)
        .tdata(tdata),
        .tvalid(tvalid),
        .tready(tready)
    );

    var logic[7:0] pc_data;

    always @(posedge clk) begin
        case (state)
            INIT: begin
                // Start reset procedure
                rst_n <= 0;
                state <= RESET;
            end
            RESET: begin
                rst_n <= 1;
                state <= WRITE_AWAIT;
            end
            WRITE_AWAIT: begin
                if (~txe_n) begin
                    write_data <= 69;
                    wr_n <= 0;
                    state <= WRITING;
                end
            end
            WRITING: begin
                if (txe_n) begin
                    wr_n <= 1;
                    state <= CHECK_ON_PC;
                end else begin
                    // If the FIFO still has space write more data
                    write_data <= write_data + 1;
                end
            end
            CHECK_ON_PC: begin
                if (tvalid) begin
                    tready <= 1; // tell the FIFO that We want to start clocking outputs
                    state <= READ_OUT;
                end
            end
            READ_OUT: begin
                if (tvalid) begin
                    pc_data <= tdata;
                end else begin
                    tready <= 0;
                    state <= DONE;
                end
            end
            DONE: begin
                $stop;
            end
        endcase
    end

endmodule

`default_nettype wire