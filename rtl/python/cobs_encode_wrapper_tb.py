"""
VUnit testbench for the cobs encoder wrapper.
"""

from pathlib import Path

import vunit_util

WORKSPACE = Path(__file__).parent / "workspace"
RTL_ROOT = Path(__file__).parent / ".."

# Create source list
sources = [
    RTL_ROOT / "testbenches" / "cobs_encode_wrapper_tb.sv",
    RTL_ROOT / "cobs" / "cobs_encode_wrapper.sv",
    RTL_ROOT / "verilog-axis" / "rtl" / "axis_cobs_encode.v",
    RTL_ROOT / "verilog-axis" / "rtl" / "axis_fifo.v",
    RTL_ROOT / "axis" / "axis_interface.sv"
]

# Create VUnit instance and add sources to library
vu, lib = vunit_util.init(WORKSPACE)
lib.add_source_files(sources)

# Create testbench
tb = lib.test_bench("cobs_encode_wrapper_tb")

# Suppress vopt deprecation error
vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()