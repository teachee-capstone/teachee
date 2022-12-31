transcript off

set WildcardFilter [lsearch -not -all -inline $WildcardFilter Memory]

proc run_legacy_tb {tb_name waves} {
    global name
    # Just compile all relevant directories + the requested TB
    vlog ../../teachee_defs.sv
    vlog *.sv
    vlog ../../verilog-axis/rtl/axis_fifo.v
    vlog ../../verilog-axis/rtl/axis_async_fifo.v
    vlog ../../xadc/*.sv
    vlog ../../ft232h/*.sv
    vlog ../../axis/*.sv

    vsim $tb_name

    radix -hexadecimal

    foreach wave $waves {
        add wave $tb_name.$wave
    }

    run -all
}