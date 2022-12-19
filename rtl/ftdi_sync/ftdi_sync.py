from pylibftdi import Driver

print(Driver().list_devices())

# TODO:
# Get the FPGA side pins configured such that the device has known states on its inputs
# Set the bitmode to 0x40 in python
# Try to observe the clock signal
# go from there
