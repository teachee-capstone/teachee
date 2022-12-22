transcript off

set WildcardFilter [lsearch -not -all -inline $WildcardFilter Memory]

proc timed_tb {tb_name mod_name waves} {
    global name
    vlog ../common/*.sv
    vlog $tb_name.sv $mod_name.sv

    vsim $tb_name

    radix -hexadecimal

    foreach wave $waves {
        add wave $tb_name.$wave
    }

    run 1000ns
}