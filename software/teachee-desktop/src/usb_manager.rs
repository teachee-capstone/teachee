use std::{error::Error, thread, time::Duration};

use libftd2xx::{BitMode, Ft232h, FtdiCommon};

use crate::storage::Storage;

pub trait Reader {
    /// Block until a non-zero number of bytes is available then write the bytes to `buf`. Return
    /// the number of bytes written.
    fn read(&mut self, buf: &mut [u8]) -> Result<usize, Box<dyn Error>>;
}

pub struct UsbManager {
    storage: Storage,
}

type ReaderInitResult = Result<Box<dyn Reader>, Box<dyn Error>>;

impl UsbManager {
    pub fn start(storage: Storage, init_reader: Box<dyn Fn() -> ReaderInitResult>) {
        let mut manager = Self { storage };

        loop {
            thread::sleep(Duration::from_secs(1));
            match init_reader() {
                Ok(reader) => manager.rx_loop(reader),
                Err(error) => {
                    println!("{:?}", error);
                }
            }
        }
    }

    fn rx_loop(&mut self, mut reader: Box<dyn Reader>) {
        // TODO: set connection status flag on self.storage = true

        let mut buf = vec![0; 100_000];

        loop {
            match reader.read(&mut buf) {
                Ok(num_bytes) => self.handle_rx(&buf[0..num_bytes]),
                Err(error) => {
                    println!("{:?}", error);
                    // TODO: set connection status flag on self.storage = false
                    break;
                }
            }
        }
    }

    fn handle_rx(&mut self, data: &[u8]) {
        dbg!(data.len());
        self.storage.app.lock().unwrap().flip_flag();
    }
}

pub struct FtReader {
    ft: Ft232h,
}

impl FtReader {
    pub fn init() -> ReaderInitResult {
        // See: https://ftdichip.com/wp-content/uploads/2020/08/AN_130_FT2232H_Used_In_FT245-Synchronous-FIFO-Mode.pdf
        const MASK: u8 = 0xFF;
        const LATENCY_TIMER: Duration = Duration::from_millis(16);
        const IN_TRANSFER_SIZE: u32 = 0x10000;

        let mut ft = Ft232h::with_description("TeachEE")?;
        ft.set_bit_mode(MASK, BitMode::Reset)?;
        thread::sleep(Duration::from_millis(10));

        ft.set_bit_mode(MASK, BitMode::SyncFifo)?;
        ft.set_latency_timer(LATENCY_TIMER)?;
        ft.set_usb_parameters(IN_TRANSFER_SIZE)?;
        ft.set_flow_control_rts_cts()?;

        Ok(Box::new(Self { ft }))
    }
}

impl Reader for FtReader {
    fn read(&mut self, buf: &mut [u8]) -> Result<usize, Box<dyn Error>> {
        let num_bytes = self.ft.queue_status()?;
        self.ft.read_all(&mut buf[0..num_bytes])?;
        Ok(num_bytes)
    }
}

pub struct CountReader;

impl CountReader {
    pub fn init() -> ReaderInitResult {
        Ok(Box::new(Self))
    }
}

impl Reader for CountReader {
    fn read(&mut self, buf: &mut [u8]) -> Result<usize, Box<dyn Error>> {
        const NUM_SAMPLES: usize = 256;
        thread::sleep(Duration::from_millis(10));

        for (n, item) in buf.iter_mut().enumerate().take(NUM_SAMPLES) {
            *item = n as u8;
        }

        Ok(NUM_SAMPLES)
    }
}
