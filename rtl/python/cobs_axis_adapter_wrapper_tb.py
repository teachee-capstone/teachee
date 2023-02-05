"""
VUnit testbench for the cobs axis width adapter. This module, reduces the bus
width and then outputs the data cobs encoded per byte
"""

from pathlib import Path

import vunit_util

WORKSPACE = Path(__file__).parent / "workspace"
RTL_ROOT = Path(__file__).parent / ".."

# Create source list
sources = [
    RTL_ROOT / "testbenches" / "cobs_axis_adapter_wrapper_tb.sv",
    RTL_ROOT / "verilog-axis" / "rtl" / "axis_adapter.v",
    RTL_ROOT / "verilog-axis" / "rtl" / "axis_fifo.v",
    RTL_ROOT / "verilog-axis" / "rtl" / "axis_async_fifo.v",
    RTL_ROOT / "axis" / "*.sv",
    RTL_ROOT / "cobs" / "*.sv"
]

# Create VUnit instance and add sources to library
vu, lib = vunit_util.init(WORKSPACE)
lib.add_source_files(sources)

# Create testbench
tb = lib.test_bench("cobs_axis_adapter_wrapper_tb")

# Suppress vopt deprecation error
vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()
