use std::{thread, time::Duration};

use libftd2xx::{BitMode, Ft232h, FtdiCommon};

use crate::controller::Channels;

use super::{Channel, Result, SampleSource};

const MASK: u8 = 0xFF;
const LATENCY_TIMER: Duration = Duration::from_millis(16);
const IN_TRANSFER_SIZE: u32 = 0x10000;
const RX_BUF_SIZE: usize = 10000;
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

        thread::sleep(Duration::from_millis(1000));

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
        self.ft.read_all(&mut self.rx_buf)?;

        Ok(RX_BUF_SIZE)
    }
    fn decode_and_copy(&mut self, channels: &mut Channels, num_bytes: usize) -> usize {
        // Position after first 0
        // println!("{num_bytes}");
        let start = self.rx_buf[..num_bytes]
            .iter()
            .position(|&x| x == 0)
            .unwrap()
            + 1;
        // Position after last 0
        let end = num_bytes
            - self.rx_buf[..num_bytes]
                .iter()
                .rev()
                .position(|&x| x == 0)
                .unwrap();
        let mut src_index = start;
        let mut dst_index = 0;

        'outer: while src_index + PACKET_SIZE < end && dst_index < channels.voltage1.len() {
            // Packet error: offset byte not in [1, 5] or packet not delimited with 0
            if self.rx_buf[src_index] == 0
                || self.rx_buf[src_index] >= PACKET_SIZE as u8
                || self.rx_buf[src_index + PACKET_SIZE - 1] != 0
            {
                src_index += 1;
                // Find the next 0
                match self.rx_buf[src_index..(end - 1)]
                    .iter()
                    .position(|&x| x == 0)
                {
                    Some(i) => {
                        // Advance to the next packet (which follows the 0)
                        src_index += i + 1;
                    }
                    None => {
                        // No more valid packets or the erroneous packet was the last
                        break;
                    }
                }
            } else {
                let packet = &self.rx_buf[src_index..(src_index + PACKET_SIZE)];
                let mut block = packet[0] - 1;
                // Two bytes of packet overhead
                let mut decoded: [u8; PACKET_SIZE - 2] = [0; PACKET_SIZE - 2];
                let mut decoded_index = 0;

                // Note: the packet index is just the decoded_index + 1 (skip the first offset byte)
                // Example packet: 01 02 22 02 44 00
                // Decodes to:        00 22 00 44
                while decoded_index < decoded.len() {
                    if block > 0 {
                        decoded[decoded_index] = packet[decoded_index + 1];
                    } else {
                        decoded[decoded_index] = 0;
                        block = packet[decoded_index + 1];

                        if block == 0 {
                            // The 4 sample bytes cannot be zero; skip this packet
                            src_index += PACKET_SIZE;
                            continue 'outer;
                        }
                    }
                    decoded_index += 1;
                    block -= 1;
                }

                channels.voltage1[dst_index] =
                    (((decoded[3] as u16) << 4) | decoded[2] as u16) as f64 * 3.3 / 4095.0;
                channels.current1[dst_index] =
                    ((((decoded[1] as u16) << 4) | decoded[0] as u16) as f64 * 3.3 / 4095.0 - 1.5)
                        * (1.0 / 0.09);
                src_index += PACKET_SIZE;
                dst_index += 1;
            }
        }

        dst_index
    }
}
