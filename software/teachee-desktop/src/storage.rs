use std::sync::{Arc, Mutex};

use eframe::egui;

use crate::app::App;

#[derive(Debug, Default, Clone)]
pub struct Storage {
    pub app: Arc<Mutex<App>>,
}

impl eframe::App for Storage {
    fn update(&mut self, ctx: &egui::Context, frame: &mut eframe::Frame) {
        self.app.lock().unwrap().update(ctx, frame);
    }
}
