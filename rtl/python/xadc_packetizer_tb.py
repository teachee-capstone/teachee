"""
VUnit testbench for the XADC COBS Packetizer.
TB uses the XADC BFM and AXIS Adapter to test the COBS packetizer
"""

from pathlib import Path

import vunit_util

WORKSPACE = Path(__file__).parent / "workspace"
RTL_ROOT = Path(__file__).parent / ".."

# Create source list
sources = [
    RTL_ROOT / "testbenches" / "xadc_packetizer_tb.sv",
    RTL_ROOT / "xadc" / "xadc_packet_package.sv",
    RTL_ROOT / "xadc" / "xadc_drp_package.sv",
    RTL_ROOT / "xadc" / "xadc_packetizer.sv",
    RTL_ROOT / "cobs" / "cobs_encode_wrapper.sv",
    RTL_ROOT / "verilog-axis" / "rtl" / "axis_cobs_encode.v",
    RTL_ROOT / "verilog-axis" / "rtl" / "axis_fifo.v",
    RTL_ROOT / "axis" / "axis_interface.sv"
]

# Create VUnit instance and add sources to library
vu, lib = vunit_util.init(WORKSPACE)
lib.add_source_files(sources)

# Create testbench
tb = lib.test_bench("xadc_packetizer_tb")

# Suppress vopt deprecation error
vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()