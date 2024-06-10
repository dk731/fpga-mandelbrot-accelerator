#!/usr/bin/env python3
from vunit import VUnit
import glob

# create VUnit project
prj = VUnit.from_argv()

# add OSVVM library
prj.add_osvvm()
prj.add_verification_components()


# add testbench
prj.add_source_file("../tb/tb.vhd")


# run VUnit simulation
prj.main()
