#!/usr/bin/env python3

"""
Utilities to setup basic VUnit Testbench
"""

from pathlib import Path

from vunit import VUnitCLI
from vunit.verilog import VUnit

def init(workspace):
    cli = VUnitCLI()
    cli.parser.set_defaults(output_path=workspace) # Override 'output_path'

    vu = VUnit.from_args(args=cli.parse_args())
    lib = vu.add_library("lib")
 
    return (vu, lib)
