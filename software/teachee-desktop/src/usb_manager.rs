use std::{thread, time::Duration};

use libftd2xx::{BitMode, DeviceTypeError, Ft232h, FtdiCommon};

use crate::storage::Storage;

pub trait UsbManager {
    fn manage(storage: &mut Storage) -> Result<(), DeviceTypeError>;

    fn spawn_thread(mut storage: Storage) {
        thread::spawn(move || loop {
            thread::sleep(Duration::from_secs(1));
            if let Err(e) = Self::manage(&mut storage) {
                println!("{:?}", e);
            }
        });
    }
}

pub struct RealUsbManager;
impl UsbManager for RealUsbManager {
    fn manage(storage: &mut Storage) -> Result<(), DeviceTypeError> {
        // See: https://ftdichip.com/wp-content/uploads/2020/08/AN_130_FT2232H_Used_In_FT245-Synchronous-FIFO-Mode.pdf
        const MASK: u8 = 0xFF;
        const LATENCY_TIMER: Duration = Duration::from_millis(16);
        const IN_TRANSFER_SIZE: u32 = 0x10000;

        let mut ft = Ft232h::with_description("teachee")?;
        ft.set_bit_mode(MASK, BitMode::Reset)?;
        thread::sleep(Duration::from_millis(10));

        ft.set_bit_mode(MASK, BitMode::SyncFifo)?;
        ft.set_latency_timer(LATENCY_TIMER)?;
        ft.set_usb_parameters(IN_TRANSFER_SIZE)?;
        ft.set_flow_control_rts_cts()?;

        // read data here

        storage.app.lock().unwrap().flip_flag();

        Ok(())
    }
}

pub struct MockUsbManager;
impl UsbManager for MockUsbManager {
    fn manage(storage: &mut Storage) -> Result<(), DeviceTypeError> {
        loop {
            thread::sleep(Duration::from_secs(1));
            storage.app.lock().unwrap().flip_flag();
        }
    }
}
