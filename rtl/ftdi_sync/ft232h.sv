`default_nettype none

module ft232h (
    input var logic clk,

    input var logic sys_reset, // FPGA level reset, not the chip reset.

    // Control Inputs
    input var logic rxf_n,
    input var logic txe_n,

    // Control Outputs
    output var logic rd_n,
    output var logic wr_n,
    output var logic siwu_n,
    output var logic oe_n,

    // Data Bus
    inout tri logic[7:0] data,

    // Programmer Interface
    input var logic write_valid, // hold high if data on write_data input can be written
    input var logic[7:0] write_data,

    input var logic read_en, // input high when module user wants data from the FTDI
    output var logic read_valid // asserted when a read byte is on read_data output.
);

// Define states for the device
typedef enum int {
    IDLE,
    WRITING,
    READING,
    SWAP_IO,
    END_IO
} ftdi_state_t;

ftdi_state_t state;

// General Idea:

// ADC Samples (12 MHz clock domain)-> AXIS STREAM -> AXIS ASYNC FIFO -> FT232H

var logic[7:0] read_data;

always_ff @(posedge clk) begin
    if (sys_reset) begin
        rd_n <= 1;
        wr_n <= 1;
        siwu_n <= 1;
        oe_n <= 1;
    end else begin
        // Logic goes here
        case (state)
            IDLE: begin
                if (~txe_n & write_valid) begin
                    state <= WRITING;
                    // set wr_n to initiate the write
                    wr_n <= 0;
                end else if (~rxf_n & read_en) begin
                    state <= SWAP_IO;
                    // set output enable to prepare for read
                    oe_n <= 0;
                end
            end
            WRITING: begin
                if (~(~txe_n & write_valid)) begin
                    // FTDI can no longer accept additional data, return to to
                    // IDLE state
                    state <= END_IO; // effectively waiting for SW to consume the data
                end
            end
            SWAP_IO: begin
                // take a cycle to 
                rd_n <= 0; // set rd_n low after enabling the output.
                state <= READING;
            end
            READING: begin
                read_valid <= 1; 
                if (~(~rxf_n & read_en)) begin
                    state <= END_IO;
                    read_valid <= 0;
                end
            end
            END_IO: begin
                wr_n <= 1;
                oe_n <= 1;
                rd_n <= 1;
                state <= IDLE;
            end
            default: state <= END_IO;
        endcase
    end
end

assign data = state == WRITING ? write_data : 8'bZZZZ_ZZZZ;

endmodule

`default_nettype wire
