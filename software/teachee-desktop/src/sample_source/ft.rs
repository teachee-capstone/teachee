use std::{iter::zip, thread, time::Duration};

use libftd2xx::{BitMode, Ft232h, FtdiCommon};

use crate::controller::Channels;

use super::{Channel, Result, SampleSource};

const MASK: u8 = 0xFF;
const LATENCY_TIMER: Duration = Duration::from_millis(16);
const IN_TRANSFER_SIZE: u32 = 0x10000;
const RX_BUF_SIZE: usize = 100_000;
const PACKET_SIZE: usize = 6;

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
        // Position after first 0
        let start = self.rx_buf[..num_bytes].iter().position(|&x| x == 0).unwrap() + 1;
        // Position after last 0
        let end = num_bytes - self.rx_buf[..num_bytes].iter().rev().position(|&x| x == 0).unwrap();
        // Check that we have at least one packet
        debug_assert_ne!(start, end);
        debug_assert_eq!((end - start) % PACKET_SIZE, 0, "{start} {end}");

        for (packet, (v_sample, c_sample)) in self.rx_buf[start..end]
            .chunks_exact(PACKET_SIZE)
            .zip(zip(
                channels.voltage1.iter_mut(),
                channels.current1.iter_mut(),
            ))
        {
            debug_assert!(packet[0] < PACKET_SIZE as u8, "Unexpected block size: {}", packet[0]);
            debug_assert_eq!(packet[5], 0);
            if packet[0] == 5 {
                // Fast path
                *v_sample = ((packet[1] << 4) | packet[2]) as f64 * 3.3 / 4095.0;
                *c_sample = ((packet[3] << 4) | packet[4]) as f64 * 3.3 / 4095.0;
            } else {
                let mut block = packet[0] - 1;
                // Two bytes of packet overhead
                let mut decoded: [u8; PACKET_SIZE - 2] = [0; PACKET_SIZE - 2];
                let mut dst_index = 0;

                // Note: the packet index is just the dst_index + 1 (skip the first offset byte)
                // Example packet: 01 02 22 02 44 00
                // Decodes to:        00 22 00 44
                while dst_index < decoded.len() {
                    if block > 0 {
                        decoded[dst_index] = packet[dst_index + 1];
                    } else {
                        decoded[dst_index] = 0;
                        block = packet[dst_index + 1];
                    }
                    dst_index += 1;
                    block -= 1;
                }

                *v_sample = ((decoded[0] << 4) | decoded[1]) as f64 * 3.3 / 4095.0;
                *c_sample = ((decoded[2] << 4) | decoded[3]) as f64 * 3.3 / 4095.0;
            }
        }

        (end - start) / PACKET_SIZE
    }
}
