onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /xadc_packetizer_tb/reset
add wave -noupdate /xadc_packetizer_tb/clk
add wave -noupdate /xadc_packetizer_tb/xadc_daddr
add wave -noupdate /xadc_packetizer_tb/xadc_den
add wave -noupdate /xadc_packetizer_tb/xadc_drdy
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/xadc_do
add wave -noupdate /xadc_packetizer_tb/xadc_eos
add wave -noupdate /xadc_packetizer_tb/voltage_channel/clk
add wave -noupdate /xadc_packetizer_tb/voltage_channel/rst
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/voltage_channel/tdata
add wave -noupdate /xadc_packetizer_tb/voltage_channel/tvalid
add wave -noupdate /xadc_packetizer_tb/voltage_channel/tready
add wave -noupdate /xadc_packetizer_tb/voltage_channel/tlast
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/voltage_channel/tid
add wave -noupdate /xadc_packetizer_tb/voltage_channel/tuser
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/voltage_channel/tdest
add wave -noupdate /xadc_packetizer_tb/voltage_channel/tkeep
add wave -noupdate /xadc_packetizer_tb/current_monitor_channel/clk
add wave -noupdate /xadc_packetizer_tb/current_monitor_channel/rst
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/current_monitor_channel/tdata
add wave -noupdate /xadc_packetizer_tb/current_monitor_channel/tvalid
add wave -noupdate /xadc_packetizer_tb/current_monitor_channel/tready
add wave -noupdate /xadc_packetizer_tb/current_monitor_channel/tlast
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/current_monitor_channel/tid
add wave -noupdate /xadc_packetizer_tb/current_monitor_channel/tuser
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/current_monitor_channel/tdest
add wave -noupdate /xadc_packetizer_tb/current_monitor_channel/tkeep
add wave -noupdate /xadc_packetizer_tb/DUT/raw_stream/clk
add wave -noupdate /xadc_packetizer_tb/DUT/raw_stream/rst
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/DUT/raw_stream/tdata
add wave -noupdate /xadc_packetizer_tb/DUT/raw_stream/tvalid
add wave -noupdate /xadc_packetizer_tb/DUT/raw_stream/tready
add wave -noupdate /xadc_packetizer_tb/DUT/raw_stream/tlast
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/DUT/raw_stream/tid
add wave -noupdate /xadc_packetizer_tb/DUT/raw_stream/tuser
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/DUT/raw_stream/tdest
add wave -noupdate /xadc_packetizer_tb/DUT/raw_stream/tkeep
add wave -noupdate /xadc_packetizer_tb/DUT/state
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/DUT/voltage_upper
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/DUT/voltage_lower
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/DUT/current_upper
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/DUT/current_lower
add wave -noupdate /xadc_packetizer_tb/cobs_stream/clk
add wave -noupdate /xadc_packetizer_tb/cobs_stream/rst
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/cobs_stream/tdata
add wave -noupdate /xadc_packetizer_tb/cobs_stream/tvalid
add wave -noupdate /xadc_packetizer_tb/cobs_stream/tready
add wave -noupdate /xadc_packetizer_tb/cobs_stream/tlast
add wave -noupdate -radix hexadecimal /xadc_packetizer_tb/cobs_stream/tid
add wave -noupdate /xadc_packetizer_tb/cobs_stream/tuser
add wave -noupdate -radix decimal /xadc_packetizer_tb/cobs_stream/tdest
add wave -noupdate /xadc_packetizer_tb/cobs_stream/tkeep
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {595831 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 435
configure wave -valuecolwidth 200
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {452015 ps} {618315 ps}
