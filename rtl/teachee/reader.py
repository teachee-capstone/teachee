from pylibftdi import Device, Driver

print(Driver().list_devices())
user_in = input("exit now or start polling? y/n")
if user_in == 'y':
    exit()

with Device('FT84Y22T') as dev:
    # takes us from async to sync mode within ft245.
    # if you don't run this the clock does not come up
    dev.ftdi_fn.ftdi_set_bitmode(1, 0x40)
    data = dev.read(20_000)
    anomaly_counter = 0
    for i in range(1, len(data)):
        print(data[i])
        if data[i - 1] == 0 and data[i] > 5:
            anomaly_counter += 1

    print("found %d anomalies" % anomaly_counter)
