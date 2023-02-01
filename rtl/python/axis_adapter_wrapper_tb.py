"""
VUnit testbench for the axis bus width adapter.
"""

from pathlib import Path

import vunit_util

WORKSPACE = Path(__file__).parent / "workspace"
RTL_ROOT = Path(__file__).parent / ".."

# Create source list
sources = [
    RTL_ROOT / "testbenches" / "axis_adapter_wrapper_tb.sv",
    RTL_ROOT / "verilog-axis" / "rtl" / "axis_adapter.v",
    RTL_ROOT / "verilog-axis" / "rtl" / "axis_fifo.v",
    RTL_ROOT / "axis" / "*.sv"
]

# Create VUnit instance and add sources to library
vu, lib = vunit_util.init(WORKSPACE)
lib.add_source_files(sources)

# Create testbench
tb = lib.test_bench("axis_adapter_wrapper_tb")

# Suppress vopt deprecation error
vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()