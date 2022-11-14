use std::{
    sync::{Arc, Mutex},
    thread,
    time::Duration,
};

use eframe::egui;

use crate::app::App;

#[derive(Debug, Default, Clone)]
pub struct Storage {
    pub app: Arc<Mutex<App>>,
}

impl Storage {
    fn usb_manager(self) {
        loop {
            thread::sleep(Duration::from_secs(1));
            self.app.lock().unwrap().flip_flag();
        }
    }

    pub fn spawn_usb_manager_thread(self) {
        thread::spawn(move || self.usb_manager());
    }
}

impl eframe::App for Storage {
    fn update(&mut self, ctx: &egui::Context, frame: &mut eframe::Frame) {
        self.app.lock().unwrap().update(ctx, frame);
    }
}
