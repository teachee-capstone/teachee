// Author: Alex Lao
// Date: February 13, 2019
// Little Endian

module ft232h_sync_fifo #(
    ADR_WIDTH = 16,
    DAT_WIDTH = 16,
    SEL_WIDTH = 2
)(
    input       i_reset,
    inout [9:0] io_acbus,
    inout [7:0] io_adbus,
    output      o_ft232h_reset_n,
    input       i_sample,
    output logic     start_sample,
    wishbone_bus.master wishbone_master, // wishbone master output
    wishbone_bus.slave  wishbone_slave    // wishbone slave input from mux network for programming the DMA engine
);

    assign o_ft232h_reset_n = !i_reset;
    assign wishbone_master.rst = i_reset;

    /* Wishbone Slave Logic (DMA Controller Registers) */
    // DMA Controller Register Map

    logic [DAT_WIDTH-1:0] dma_descriptor [20:0];

    /* Memory Map */
    // 0x00 - DMA Descriptor Length
    // 0x01 - DMA 1 Start Address
    // 0x02 - DMA 1 End Address
    // 0x03 - DMA 2 Start Address
    // 0x04 - DMA 2 End Address

    // till 0x0C

    always_ff @(posedge wishbone_slave.clk) begin : wishbone_logic
        if(wishbone_slave.rst) begin
            wishbone_slave.slave_dat <= '0;
        end else begin
            wishbone_slave.ack <= 1'b0;
            if (wishbone_slave.stb & wishbone_slave.cyc & wishbone_slave.we) begin
                dma_descriptor[wishbone_slave.adr] <= wishbone_slave.master_dat;
                wishbone_slave.ack <= 1'b1;
            end else if (wishbone_slave.stb & wishbone_slave.cyc & !wishbone_slave.we) begin
                wishbone_slave.slave_dat <= dma_descriptor[wishbone_slave.adr]; 
                wishbone_slave.ack <= 1'b1;
            end
        end
    end 

    logic [1:0] byte_counter;
    logic oe_n_delayed;

    /* io_acbus assignments - Start */

    // FT245 Sync FIFO Mode (Input/Output referenced from FPGA's prespective)
    // ACBUS[0] - rxf_n   - Input - low = FIFO not empty
    // ACBUS[1] - txe_n   - Input - low = FIFO not full
    // ACBUS[2] - rd_n    - Output
    // ACBUS[3] - wr_n    - Output
    // ACBUS[4] - siwu_n  - Output
    // ACBUS[5] - clkout  - Input
    // ACBUS[6] - oe_n    - Output

    // Inputs
    logic rxf_n;
    logic txe_n;
    logic ftdi_clk;
    // Outputs
    logic rd_n;
    logic wr_n;
    logic siwu_n;
    logic oe_n_reg;

    // Inputs
    assign rxf_n = io_acbus[0];
    assign io_acbus[0] = 1'bZ;

    assign txe_n = io_acbus[1];
    assign io_acbus[1] = 1'bZ;

    assign ftdi_clk = io_acbus[5];
    assign io_acbus[5] = 1'bZ;

    // Outputs
    assign io_acbus[2] = rd_n | byte_counter == 3;
    assign io_acbus[3] = wr_n;
    assign io_acbus[4] = siwu_n;
    assign io_acbus[6] = oe_n_reg;

    // Unusued
    assign io_acbus[7] = 1'bZ;
    assign io_acbus[8] = 1'bZ;
    assign io_acbus[9] = 1'bZ;

    /* io_acbus assignments - End */

    /* Async FIFOs */

    // HOST to FPGA
    logic        rx_fifo_write_en;
    logic [23:0] rx_fifo_din; // CMD BYTE / PAYLOAD HIGH BYTE / PAYLOAD LOW BYTE
    logic        rx_fifo_full;
    logic        rx_fifo_read_en;
    logic [23:0] rx_fifo_dout;
    logic        rx_fifo_empty;

    dc_fifo #(
        .ADDR_WIDTH(4), 
        .DATA_WIDTH(24)
    ) rx_fifo (
        .w_clk         (ftdi_clk        ),
        .w_clk_reset   (i_reset         ),
        .w_clk_write_en(rx_fifo_write_en),
        .w_clk_din     (rx_fifo_din     ),
        .w_clk_full    (rx_fifo_full    ),
        .r_clk         (wishbone_master.clk    ),
        .r_clk_reset   (wishbone_master.rst    ),
        .r_clk_read_en (rx_fifo_read_en ),
        .r_clk_dout    (rx_fifo_dout    ),
        .r_clk_empty   (rx_fifo_empty   )
    );


    // FPGA to HOST
    logic        tx_fifo_write_en;
    logic [15:0] tx_fifo_din; // DAT HIGH BYTE / DAT LOW BYTE
    logic        tx_fifo_full;
    logic        tx_fifo_read_en;
    logic [15:0] tx_fifo_dout;
    logic        tx_fifo_empty;

    dc_fifo #(
        .ADDR_WIDTH(10), 
        .DATA_WIDTH(16)
    ) tx_fifo (
        .w_clk         (wishbone_master.clk    ),
        .w_clk_reset   (wishbone_master.rst    ),
        .w_clk_write_en(tx_fifo_write_en),
        .w_clk_din     (tx_fifo_din     ),
        .w_clk_full    (tx_fifo_full    ),
        .r_clk         (ftdi_clk        ),
        .r_clk_reset   (i_reset         ),
        .r_clk_read_en (tx_fifo_read_en ),
        .r_clk_dout    (tx_fifo_dout    ),
        .r_clk_empty   (tx_fifo_empty   )
    );


    typedef enum logic [2:0] {
        FTDI_IDLE,
        FTDI_READ_FROM_HOST,
        FTDI_WRITE_TO_HOST,
        FTDI_DELAY,
        FTDI_WAIT_WRITE
    } ftdi_state_t;

    ftdi_state_t ftdi_state;

    // FPGA to HOST (Read from FPGA's Async FIFO)
    // rxf_n high == FTDI FIFO empty
    // txe_n high == FTDI FIFO full
    logic [7:0] ad_bus_output;
    
    always_ff @(posedge ftdi_clk or posedge i_reset) begin : FTDI_FSM
        if (i_reset) begin
            oe_n_reg <= 1;
            wr_n     <= 1;
            siwu_n   <= 1;
            rd_n     <= 1;
            rx_fifo_write_en <= 0;
            tx_fifo_read_en <= 0;
            ad_bus_output <= '0;
        end else begin
            wr_n     <= 1;
            siwu_n   <= 1;
            rd_n     <= 1;
            rx_fifo_write_en <= 0;
            tx_fifo_read_en <= 0;
            case (ftdi_state)
                FTDI_IDLE : begin
                    if (!txe_n & !tx_fifo_empty) begin // Write to host
                        oe_n_reg <= 1; // Disable FTDI output drivers
                        byte_counter <= 0;
                        ftdi_state <= FTDI_WRITE_TO_HOST;
                    end else if (!rxf_n & !rx_fifo_full) begin // Read from host
                        oe_n_reg <= 0; // Enable FTDI output drivers
                        byte_counter <= 0;
                        rx_fifo_din <='0;
                        ftdi_state <= FTDI_READ_FROM_HOST;
                    end 
                end

                FTDI_READ_FROM_HOST : begin // Must read 3 byte (cmd, payload high, payload low), left to right order
                    if(!oe_n_delayed & !rxf_n & (byte_counter != 3)) begin
                        rd_n <= 0;
                    end

                    if(!rxf_n & !rd_n & (byte_counter != 3)) begin
                        rx_fifo_din <= rx_fifo_din | (io_adbus << (byte_counter*8));
                        byte_counter <= byte_counter + 1;
                    end

                    if (byte_counter == 3) begin
                        rx_fifo_write_en <= 1;
                        ftdi_state <= FTDI_IDLE;
                    end
                end

                FTDI_WRITE_TO_HOST : begin // Respond with 2 bytes
                    if (!tx_fifo_empty) begin
                        if(oe_n_delayed & !txe_n & (byte_counter != 2)) begin
                            wr_n <= 0;
                            ad_bus_output <= tx_fifo_dout >> (byte_counter*8); // high, then low
                            byte_counter <= byte_counter + 1;
                            ftdi_state <= FTDI_WAIT_WRITE;
                        end
                        if (byte_counter == 2) begin
                            tx_fifo_read_en <= 1;
                            ftdi_state <= FTDI_DELAY;
                        end
                    end
                end

                FTDI_DELAY : begin
                    ftdi_state <= FTDI_IDLE;
                end

                FTDI_WAIT_WRITE : begin
                    if (txe_n) begin // If full, retry
                        byte_counter <= byte_counter - 1;
                        ftdi_state <= FTDI_WRITE_TO_HOST;
                    end else begin
                        ftdi_state <= FTDI_WRITE_TO_HOST;
                    end
                end

                default : begin
                    ftdi_state <= FTDI_IDLE;
                end
            endcase
        end
    end

    typedef enum logic [2:0] {
        WB_IDLE,
        WB_WAIT_ACK,
        WB_DELAY,
        WB_AUTO_SAMPLE,
        WB_WAIT_TX_FIFO_FULL
    } wb_state_t;
    wb_state_t wb_state;

    logic [5:0] current_descriptor_index;

    logic [15:0] current_adr;
    logic sample_last;
    logic sampling;
    //logic start_sample;
    //SPI Transaction requires a CMD Byte and two DATA bytes (Input from master if ADDR or WRITE) (Output to master if READ)
    // xxxxxx00 = READ
    // xxxxxx01 = WRITE
    // xxxxxx10 = SET ADR
    // xxxxxx11 = BUS RESET
    always_ff @(posedge wishbone_master.clk) begin : wishbone_master_FSM
        if(wishbone_master.rst) begin
            current_adr <= '0;
            wishbone_master.adr        <= '0;
            wishbone_master.master_dat <= '0;
            wishbone_master.sel        <= '0;
            wishbone_master.stb        <= 1'b0;
            wishbone_master.cyc        <= 1'b0;
            wishbone_master.we         <= 1'b0;

            rx_fifo_read_en <= 0;
            tx_fifo_write_en <= 0;
            sampling <= 0;
            wb_state <= WB_IDLE;
        end else begin
            //wishbone_master.adr        <= '0; // If we clear the address the mux will switch
            wishbone_master.master_dat <= '0;
            wishbone_master.sel        <= '0;
            wishbone_master.stb        <= 1'b0;
            wishbone_master.cyc        <= 1'b0;
            //wishbone_master.we         <= 1'b0;

            rx_fifo_read_en <= 0;
            tx_fifo_write_en <= 0;

            sample_last <= i_sample;
            if (!sample_last & i_sample) begin // Start trigger
                start_sample <= 1;
            end


            case (wb_state)
                WB_IDLE : begin
                    // Read from RX FIFO (commands)
                    // Respond on TX FIFO (reads only)
                    sampling <= 0;
                    if (!rx_fifo_empty & !tx_fifo_full) begin // read command
                        rx_fifo_read_en <= 1;
                        case (rx_fifo_dout[18:16]) 
                            3'd0 : begin // Issue WB read
                                wishbone_master.adr        <= current_adr;
                                wishbone_master.master_dat <= '0;
                                wishbone_master.sel        <= '1;
                                wishbone_master.stb        <= 1'b1;
                                wishbone_master.cyc        <= 1'b1;
                                wishbone_master.we         <= 1'b0;
                                wb_state <= WB_WAIT_ACK;
                            end

                            3'd1 : begin // Issue WB write
                                wishbone_master.adr        <= current_adr;
                                wishbone_master.master_dat <= rx_fifo_dout[15:0];
                                wishbone_master.sel        <= '1;
                                wishbone_master.stb        <= 1'b1;
                                wishbone_master.cyc        <= 1'b1;
                                wishbone_master.we         <= 1'b1;
                                wb_state <= WB_WAIT_ACK;
                            end

                            3'd2 : begin // set adr
                                current_adr <= rx_fifo_dout[15:0];
                                wb_state <= WB_DELAY;
                            end

                            3'd3 : begin // bus reset
                                wb_state <= WB_DELAY;
                            end

                            3'd4 : begin // start auto sample
                                current_adr <= dma_descriptor[1];
                                current_descriptor_index <= 1;
                                sampling <= 1;
                                wb_state <= WB_AUTO_SAMPLE;
                            end
                            
                        endcase
                    end
                end

                WB_WAIT_ACK : begin
                    if (wishbone_master.ack) begin
                        if (sampling) begin
                            wb_state <= WB_AUTO_SAMPLE;
                        end else begin
                            wb_state <= WB_IDLE;
                        end

                        if (!wishbone_master.we) begin
                            if (tx_fifo_full) begin
                                wb_state <= WB_WAIT_TX_FIFO_FULL;
                            end else begin
                                tx_fifo_write_en <= 1;
                            end
                            
                            tx_fifo_din <= wishbone_master.slave_dat;
                        end
                    end
                end

                WB_DELAY : begin
                    wb_state <= WB_IDLE;
                end
                default : begin
                    wb_state <= WB_IDLE;
                end

                WB_AUTO_SAMPLE : begin
                    //if (!tx_fifo_full) begin
                        if (current_adr == dma_descriptor[1]) begin
                            if (start_sample) begin // Start trigger
                                wishbone_master.adr        <= current_adr; // read
                                wishbone_master.master_dat <= '0;
                                wishbone_master.sel        <= '1;
                                wishbone_master.stb        <= 1'b1;
                                wishbone_master.cyc        <= 1'b1;
                                wishbone_master.we         <= 1'b0;
                                wb_state <= WB_WAIT_ACK;
                                current_adr <= current_adr + 1;
                            end
                        end else if (current_adr == dma_descriptor[current_descriptor_index+1]) begin
                            if (current_descriptor_index == dma_descriptor[0]-1) begin // If end of descriptor
                                start_sample <= 0;
                                current_descriptor_index <= 1; // Reset descriptor index
                                current_adr <= dma_descriptor[1]; // Reset address to first start address
                                if (!rx_fifo_empty) begin
                                    wb_state <= WB_IDLE;
                                end
                            end else begin
                                current_descriptor_index <= current_descriptor_index + 2;
                                current_adr <= dma_descriptor[current_descriptor_index + 2];
                            end
                        end else begin
                            wishbone_master.adr        <= current_adr; // read
                            wishbone_master.master_dat <= '0;
                            wishbone_master.sel        <= '1;
                            wishbone_master.stb        <= 1'b1;
                            wishbone_master.cyc        <= 1'b1;
                            wishbone_master.we         <= 1'b0;
                            wb_state <= WB_WAIT_ACK;
                            current_adr <= current_adr + 1;
                        end
                    //end
                end

                WB_WAIT_TX_FIFO_FULL : begin
                    if (!tx_fifo_full) begin
                        tx_fifo_write_en <= 1;
                        if (sampling) begin
                            wb_state <= WB_AUTO_SAMPLE;
                        end else begin
                            wb_state <= WB_IDLE;
                        end
                    end
                end
            endcase
        end
    end

    /* io_adbus direction control - Start */
    // If oe_n goes low, immediately turn off FPGA outputs
    // If oe_n goes high, turn on FPGA outputs 1 clock cycle later

    

    always_ff @(posedge ftdi_clk or posedge i_reset) begin
        if (i_reset) begin
            oe_n_delayed <= 1;
        end else begin
            oe_n_delayed <= oe_n_reg;
        end
    end

    assign io_adbus = oe_n_reg ? (oe_n_delayed ? ad_bus_output : 8'bzzzz_zzzz) : 8'bzzzz_zzzz;

    /* io_adbus direction control - End */

endmodule // ft232h_sync_fifo