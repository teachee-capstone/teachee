use std::{iter::zip, thread, time::Duration};

use libftd2xx::{BitMode, Ft232h, FtdiCommon};

use crate::controller::Channels;

use super::{Channel, Result, SampleSource};

const MASK: u8 = 0xFF;
const LATENCY_TIMER: Duration = Duration::from_millis(16);
const IN_TRANSFER_SIZE: u32 = 0x10000;
const RX_BUF_SIZE: usize = 100_000;
const CHUNK_SIZE: usize = 4;

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
        ft.purge_rx()?;

        thread::sleep(Duration::from_millis(10));

        Ok(Self {
            ft,
            rx_buf: vec![0; RX_BUF_SIZE],
        })
    }

    fn read_samples(&mut self, channels: &mut Channels) -> Result<(usize, Channel)> {
        let num_bytes = self.read_bytes()?;
        let num_samples = self.decode_and_copy(channels, num_bytes);
        Ok((num_samples, Channel::VoltageA))
    }
}

impl FtSampleSource {
    fn read_bytes(&mut self) -> Result<usize> {
        let num_bytes = self.ft.queue_status()?;
        self.ft.read_all(&mut self.rx_buf[0..num_bytes])?;
        Ok(num_bytes)
    }
    fn decode_and_copy(&mut self, channels: &mut Channels, num_bytes: usize) -> usize {
        // Byte after the first 0
        let start = self.rx_buf[..num_bytes].iter().position(|&x| x == 0).unwrap() + 1;
        // Last 0
        let end = self.rx_buf[..num_bytes].iter().rev().position(|&x| x == 0).unwrap();
        // Check that we have at least one packet
        assert_ne!(start - 1, end);
        let mut cur_packet = start;
        let mut channels_idx = 0;

        while cur_packet < end {
            let res = cobs::decode_in_place_report(&mut self.rx_buf[cur_packet..end]).unwrap();

            // Copy the decoded chunks (of 4 bytes)
            for (chunk, (v_sample, c_sample)) in self.rx_buf[cur_packet..(cur_packet + res.dst_used)]
                .chunks_exact(CHUNK_SIZE)
                .zip(zip(
                    channels.voltage1[channels_idx..].iter_mut(),
                    channels.current1[channels_idx..].iter_mut(),
                ))
            {
                *v_sample = ((chunk[0] << 4) | chunk[1]) as f64 * 3.3 / 4095.0;
                *c_sample = ((chunk[2] << 4) | chunk[3]) as f64 * 3.3 / 4095.0;
            }

            cur_packet += res.src_used + 1;
            channels_idx += res.dst_used / CHUNK_SIZE;
            assert_eq!(self.rx_buf[cur_packet - 1], 0);
            assert_eq!(res.dst_used % CHUNK_SIZE, 0);
        }

        channels_idx
    }
}
