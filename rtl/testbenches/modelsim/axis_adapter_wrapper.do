onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /axis_adapter_wrapper_tb/reset
add wave -noupdate /axis_adapter_wrapper_tb/clk
add wave -noupdate /axis_adapter_wrapper_tb/state
add wave -noupdate /axis_adapter_wrapper_tb/original_data/clk
add wave -noupdate /axis_adapter_wrapper_tb/original_data/rst
add wave -noupdate -radix hexadecimal /axis_adapter_wrapper_tb/original_data/tdata
add wave -noupdate /axis_adapter_wrapper_tb/original_data/tvalid
add wave -noupdate /axis_adapter_wrapper_tb/original_data/tready
add wave -noupdate /axis_adapter_wrapper_tb/original_data/tlast
add wave -noupdate /axis_adapter_wrapper_tb/original_data/tid
add wave -noupdate /axis_adapter_wrapper_tb/original_data/tuser
add wave -noupdate /axis_adapter_wrapper_tb/original_data/tdest
add wave -noupdate /axis_adapter_wrapper_tb/original_data/tkeep
add wave -noupdate /axis_adapter_wrapper_tb/modified_width_data/clk
add wave -noupdate /axis_adapter_wrapper_tb/modified_width_data/rst
add wave -noupdate -radix hexadecimal /axis_adapter_wrapper_tb/modified_width_data/tdata
add wave -noupdate /axis_adapter_wrapper_tb/modified_width_data/tvalid
add wave -noupdate /axis_adapter_wrapper_tb/modified_width_data/tready
add wave -noupdate /axis_adapter_wrapper_tb/modified_width_data/tlast
add wave -noupdate /axis_adapter_wrapper_tb/modified_width_data/tid
add wave -noupdate /axis_adapter_wrapper_tb/modified_width_data/tuser
add wave -noupdate /axis_adapter_wrapper_tb/modified_width_data/tdest
add wave -noupdate /axis_adapter_wrapper_tb/modified_width_data/tkeep
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {43269 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ps} {294912 ps}
