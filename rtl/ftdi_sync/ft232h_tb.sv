`default_nettype none
`timescale 1ns / 1ps

module ft232h_tb;

typedef enum int {
    IDLE,
    WRITE_AWAIT,
    WRITING,
    CHECK_ON_PC,
    READ_OUT,
    DONE
} ft232h_tb_state_t;

ft232h_tb_state_t state;

wire ftdi_clk;
var logic sys_clk;

wire rxf_n;
wire txe_n;

wire rd_n;
wire wr_n;
wire siwu_n;
wire oe_n;
wire rst_n;

wire[7:0] io_adbus;

// PC Side wires (FIFO output)
wire[7:0] pc_tdata;
wire pc_tvalid;
var logic pc_tready;

// Programmer data input side wires
var logic[7:0] write_data;
var logic tvalid;
wire tready;

var logic second_write;

// get variable logic into initial vals
initial begin
    sys_clk = 0;
    write_data = 69;
    tvalid = 0;
    pc_tready = 0;
    second_write = 0;

    state = IDLE;
end 
// generate sys_clk
always begin
    #100
    sys_clk = ~sys_clk;
end 

ft232h controller (
    .ftdi_clk(ftdi_clk),

    .rxf_n(rxf_n),
    .txe_n(txe_n),

    .rd_n(rd_n),
    .wr_n(wr_n),
    .siwu_n(siwu_n),
    .oe_n(oe_n),

    .data(io_adbus),

    // Programmer AXIS Interface
    .sys_clk(sys_clk),
    .internal_fifo_rst(0),
    .tdata(write_data),
    .tvalid(tvalid),
    .tready(tready)
);

ft232h_bfm bfm (
    .clk(ftdi_clk),

    .rxf_n(rxf_n),
    .txe_n(txe_n),

    .rd_n(rd_n),
    .wr_n(wr_n),
    .siwu_n(siwu_n),
    .oe_n(oe_n),
    .rst_n(rst_n),

    .data(io_adbus),

    // PC Side Signals (FIFO output)
    .tdata(pc_tdata),
    .tvalid(pc_tvalid),
    .tready(pc_tready)
);

always @(posedge sys_clk) begin
    case(state)
        IDLE: begin
            // Set everything to initial values
            write_data = 69;
            tvalid = 0;
            state <= WRITE_AWAIT;
        end
        WRITE_AWAIT: begin
            if (tready) begin
                tvalid <= 1;
                state <= WRITING;
            end
        end
        WRITING: begin
            if (tready) begin
                // keep going as long as FIFO is asking for more data
                write_data <= write_data + 1;
            end else begin
                tvalid <= 0;
                // after finishing, begin process of checking PC output
                state <= CHECK_ON_PC;
            end
        end
        CHECK_ON_PC: begin
            // impl in other clock domain
        end
        READ_OUT: begin
            // Let the data come out on pc_tdata until valid bit flips
            // state transition from this happens in the other clock domain
        end
        DONE: begin
            $stop;
        end
    endcase
end

always @(posedge ftdi_clk) begin
    if (state == CHECK_ON_PC) begin
        if (pc_tvalid) begin
            state <= READ_OUT;
        end
    end
    if (state == READ_OUT) begin
        if (pc_tvalid) begin
            pc_tready <= 1;
        end else begin
            pc_tready <= 0;
            state <= WRITE_AWAIT;
            if (second_write) begin
                state <= DONE;
            end
            second_write <= 1;
            // if (second_write) begin
            //     state <= DONE;
            // end else  begin
            //     state <= WRITE_AWAIT;
            // end
        end
    end
end 

endmodule

`default_nettype wire
