"""
Example VUnit testbench Python script for running RTL module testbench in SystemVerilog
"""

from pathlib import Path

import vunit_util

# NOTE: this needs to be run from the RTL directory
WORKSPACE = Path(__file__).parent / "workspace"
RTL_ROOT = Path(__file__).parent / ".." / "testbenches"

# Create source list
sources = [
    RTL_ROOT / "vunit_example_tb.sv",
]

# Create VUnit instance and add sources to library
vu, lib = vunit_util.init(WORKSPACE)
lib.add_source_files(sources)

# Create testbench
tb = lib.test_bench("vunit_example_tb")

# Suppress vopt deprecation error
vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()
