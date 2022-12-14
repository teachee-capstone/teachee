// hide console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use eframe::{self, epaint::Vec2, NativeOptions, Theme};

use teachee_desktop::storage::Storage;

fn main() {
    tracing_subscriber::fmt::init();

    let options = NativeOptions {
        default_theme: Theme::Light,
        min_window_size: Some(Vec2 { x: 600.0, y: 400.0 }),
        ..NativeOptions::default()
    };

    eframe::run_native(
        "TeachEE",
        options,
        Box::new(|_cc| {
            let storage = Storage::default();
            storage.clone().spawn_usb_manager_thread();
            Box::new(storage)
        }),
    );
}
