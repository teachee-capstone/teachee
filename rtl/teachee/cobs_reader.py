from pylibftdi import Device, Driver
from cobs import cobs
import matplotlib.pyplot as plt

print(Driver().list_devices())
user_in = input("exit now or start polling? y/n")
if user_in == 'y':
    exit()

with Device('FT84Y22T') as dev:
    # takes us from async to sync mode within ft245.
    # if you don't run this the clock does not come up
    dev.ftdi_fn.ftdi_set_bitmode(1, 0x40)
    data = dev.read(1000)
    plot_samples = []
    for i in range(1, len(data) - 1):
        if data[i - 1] == 0 and data[i] == 3:
            plot_samples.append(data[i + 1])
plt.plot(plot_samples)
plt.show()
