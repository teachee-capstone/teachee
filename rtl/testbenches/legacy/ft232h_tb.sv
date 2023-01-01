`default_nettype none
`timescale 1ns / 1ps
// timed_tb ftdi_sync ft232h_tb {sys_clk ftdi_clk state ftdi_txe_n ftdi_wr_n ftdi_adbus sys_axis.tdata sys_axis.tready sys_axis.tvalid pc_tvalid pc_tready pc_tdata}
module ft232h_tb;

    typedef enum int {
        AWAIT_FTDI,
        SEND_TO_FTDI,
        READ_OUT,
        DONE
    } ft232h_tb_state_t;

    ft232h_tb_state_t state;

    wire ftdi_clk;
    var logic sys_clk;

    wire ftdi_rxf_n;
    wire ftdi_txe_n;

    wire ftdi_rd_n;
    wire ftdi_wr_n;
    wire ftdi_siwu_n;
    wire ftdi_oe_n;
    wire ftdi_rst_n;

    wire[7:0] ftdi_adbus;

    // PC Side wires (FIFO output)
    wire[7:0] pc_tdata;
    wire pc_tvalid;
    var logic pc_tready;

    var logic second_write;

    axis_interface sys_axis (
        .clk(sys_clk),
        .rst(0)
    );

    // get variable logic into initial vals
    initial begin
        sys_clk = 0;
        pc_tready = 0;
        second_write = 0;

        sys_axis.tdata = 69;
        sys_axis.tvalid = 0;

        state = AWAIT_FTDI;
    end 

    always begin
        #100
        sys_clk = ~sys_clk;
    end 

    ft232h ftdi_dut (
        .ftdi_clk(ftdi_clk),

        .ftdi_rxf_n(ftdi_rxf_n),
        .ftdi_txe_n(ftdi_txe_n),

        .ftdi_rd_n(ftdi_rd_n),
        .ftdi_wr_n(ftdi_wr_n),
        .ftdi_siwu_n(ftdi_siwu_n),
        .ftdi_oe_n(ftdi_oe_n),

        .ftdi_adbus(ftdi_adbus),

        // Programmer AXIS Interface
        .sys_axis(sys_axis.Sink)
    );

    ft232h_bfm bfm (
        .clk(ftdi_clk),

        .rxf_n(ftdi_rxf_n),
        .txe_n(ftdi_txe_n),

        .rd_n(ftdi_rd_n),
        .wr_n(ftdi_wr_n),
        .siwu_n(ftdi_siwu_n),
        .oe_n(ftdi_oe_n),
        .rst_n(ftdi_rst_n),

        .data(ftdi_adbus),

        // PC Side Signals (FIFO output)
        .tdata(pc_tdata),
        .tvalid(pc_tvalid),
        .tready(pc_tready)
    );

    always @(posedge sys_axis.clk) begin
        case(state)
            AWAIT_FTDI: begin
                if (sys_axis.tready) begin
                    sys_axis.tvalid <= 1;
                    state <= SEND_TO_FTDI;
                end
            end
            SEND_TO_FTDI: begin
                if (sys_axis.tready && sys_axis.tvalid) begin
                    sys_axis.tdata <= sys_axis.tdata + 1;
                end else begin
                    sys_axis.tvalid <= 0;
                    pc_tready <= 1;
                    state <= READ_OUT;
                end
            end
            DONE: begin
                $stop;
            end
        endcase
    end

    always @(posedge ftdi_clk) begin
        // consume readout from FTDI clock domain
        case (state)
            READ_OUT: begin
                // Read out the pc_tdata signal in sim. Proceed to done when there is no more data
                if (!(pc_tvalid && pc_tready)) begin
                    state <= DONE;
                end 
            end
        endcase
    end 

endmodule

`default_nettype wire
