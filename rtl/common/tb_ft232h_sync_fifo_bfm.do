vlib ./work

vlog -sv -work work ../../hdl/fifo/fifo.sv
vlog -sv -work work ../../hdl/ft232h_sync_fifo/ft232h_sync_fifo.sv
vlog -sv -work work ft232h_sync_fifo_bfm.sv
vlog -sv -work work tb_ft232h_sync_fifo_bfm.sv

vsim -novopt tb_ft232h_sync_fifo_bfm
add wave -position insertpoint sim:/tb_ft232h_sync_fifo_bfm/*