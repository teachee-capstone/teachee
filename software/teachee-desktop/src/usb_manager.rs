use std::{
    sync::{Arc, Mutex},
    thread,
    time::Duration,
};

use crate::storage::Storage;

pub fn usb_manager(storage: Arc<Mutex<Storage>>) {
    loop {
        thread::sleep(Duration::from_secs(1));
        storage.lock().unwrap().flip_flag();
    }
}
