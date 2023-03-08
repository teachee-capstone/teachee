"""
VUnit testbench for the High Speed ADC AXIS Adapter
"""

from pathlib import Path

import vunit_util

WORKSPACE = Path(__file__).parent / "workspace"
RTL_ROOT = Path(__file__).parent / ".."

# Create source list
sources = [
    RTL_ROOT / "testbenches" / "hsadc_axis_wrapper_tb.sv",
    RTL_ROOT / "hsadc" / "*.sv",
    RTL_ROOT / "axis" / "*.sv"
]

# Create VUnit instance and add sources to library
vu, lib = vunit_util.init(WORKSPACE)
lib.add_source_files(sources)

# Create testbench
tb = lib.test_bench("hsadc_axis_wrapper_tb")

# Suppress vopt deprecation error
vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()

