use std::{thread, time::Duration};

use libftd2xx::{BitMode, Ft232h, FtdiCommon};

use crate::controller::Channels;

use super::{Channel, Result, SampleSource};

const MASK: u8 = 0xFF;
const LATENCY_TIMER: Duration = Duration::from_millis(16);
const IN_TRANSFER_SIZE: u32 = 0x10000;
const RX_BUF_SIZE: usize = 100_000;

/// A sample source that reads from a real TeachEE device.
pub struct FtSampleSource {
    ft: Ft232h,
    rx_buf: Vec<u8>,
}

impl SampleSource for FtSampleSource {
    fn try_init() -> Result<Self> {
        // See: https://ftdichip.com/wp-content/uploads/2020/08/AN_130_FT2232H_Used_In_FT245-Synchronous-FIFO-Mode.pdf
        let mut ft = Ft232h::with_description("TeachEE")?;
        ft.set_bit_mode(MASK, BitMode::Reset)?;
        thread::sleep(Duration::from_millis(10));

        ft.set_bit_mode(MASK, BitMode::SyncFifo)?;
        ft.set_latency_timer(LATENCY_TIMER)?;
        ft.set_usb_parameters(IN_TRANSFER_SIZE)?;
        ft.set_flow_control_rts_cts()?;

        Ok(Self {
            ft,
            rx_buf: vec![0; RX_BUF_SIZE],
        })
    }

    fn read_samples(&mut self, channels: &mut Channels) -> Result<(usize, Channel)> {
        let num_bytes = self.read_bytes()?;
        let _rx_bytes = &self.rx_buf[0..num_bytes];
        // TODO: decode rx_bytes as samples
        self.decode_and_copy(channels);
        Ok((0, Channel::VoltageA))
    }
}

impl FtSampleSource {
    fn read_bytes(&mut self) -> Result<usize> {
        let num_bytes = self.ft.queue_status()?;
        self.ft.read_all(&mut self.rx_buf[0..num_bytes])?;
        Ok(num_bytes)
    }
    fn decode_and_copy(&mut self, _channels: &mut Channels) {}
}
