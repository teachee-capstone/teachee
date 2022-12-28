# TeachEE RTL
This folder contains all the SystemVerilog code for the CMOD A7 35-T FPGA Module
installed on the TeachEE PCB. The directory structure is as follows:
- `ftdi_sync` is an example project which sends data over USB using the FT232H
  located on the PCB. The FT232H is operated in synchronous mode and there is a python script included to read out the sample stream.
- `blink` is a simple example of blinking an LED on the TeachEE PCB. It also
  makes use of the button on the FPGA module to change the color of an RGB LED.
- `xadc` is an example project which demonstrates streaming samples from the
  FPGA's internal XADC peripheral over USB.
- The `common` directory contains all the RTL that is used in multiple example
  projects.