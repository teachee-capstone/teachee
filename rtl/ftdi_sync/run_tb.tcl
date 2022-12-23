transcript off

set WildcardFilter [lsearch -not -all -inline $WildcardFilter Memory]

proc timed_tb {tb_name mod_name waves} {
    global name
    vlog ../common/ft232h_bfm.sv
    vlog ../common/ft232h_bfm_tb.sv
    vlog ../common/verilog-axis/rtl/axis_fifo.v
    vlog ../common/verilog-axis/rtl/axis_async_fifo.v
    vlog $tb_name.sv $mod_name.sv

    vsim $tb_name

    radix -hexadecimal

    foreach wave $waves {
        add wave $tb_name.$wave
    }

    run -all
}