use std::{
    sync::{Arc, Mutex},
    thread,
    time::Duration,
};

use crate::storage::Storage;

#[derive(Debug, Default)]
pub struct USBManager {
    storage: Arc<Mutex<Storage>>,
}

impl USBManager {
    pub fn new(storage: Arc<Mutex<Storage>>) -> Self {
        Self { storage }
    }

    pub fn start(self) {
        thread::spawn(move || self.usb_manager());
    }

    pub fn usb_manager(self) {
        loop {
            thread::sleep(Duration::from_secs(1));
            self.storage.lock().unwrap().flip_flag();
        }
    }
}
