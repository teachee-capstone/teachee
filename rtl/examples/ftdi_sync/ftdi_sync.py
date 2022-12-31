from pylibftdi import Device, Driver

print(Driver().list_devices())
user_in = input("exit now or start polling? y/n")
if user_in == 'y':
    exit()

with Device('FT6TRZH9') as dev:
    # takes us from async to sync mode within ft245.
    # if you don't run this the clock does not come up
    dev.ftdi_fn.ftdi_set_bitmode(1, 0x40)
    # print(dev.read(100))
    while(True):
        print(int.from_bytes(dev.read(1), "big"))