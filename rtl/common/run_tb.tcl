transcript off

set WildcardFilter [lsearch -not -all -inline $WildcardFilter Memory]

proc timed_tb {project_name tb_name waves} {
    global name
    vlog *.sv
    vlog ../common/verilog-axis/rtl/axis_fifo.v
    vlog ../common/verilog-axis/rtl/axis_async_fifo.v
    vlog ../$project_name/*.sv
    vlog ../$project_name/testbenches/*.sv

    vsim $tb_name

    radix -hexadecimal

    foreach wave $waves {
        add wave $tb_name.$wave
    }

    run -all
}