from pylibftdi import Device

# TODO:
# Get the FPGA side pins configured such that the device has known states on its inputs
# Set the bitmode to 0x40 in python
# Try to observe the clock signal
# go from there

with Device() as dev:
    dev.ftdi_fn.ftdi_set_bitmode(1, 0x40)
    dev.write('y')

print("done")