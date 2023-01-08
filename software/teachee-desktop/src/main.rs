// hide console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::thread;

use eframe::{self, epaint::Vec2, NativeOptions, Theme};

use structopt::StructOpt;
use teachee_desktop::{
    storage::Storage,
    usb_manager::{CountReader, FtReader, UsbManager},
};

#[derive(Debug, StructOpt)]
struct Opt {
    /// Make USBManager read a sine wave instead of real data
    #[structopt(short, long)]
    sine: bool,
}

fn main() {
    let opt = Opt::from_args();

    eframe::run_native(
        "TeachEE",
        NativeOptions {
            default_theme: Theme::Light,
            min_window_size: Some(Vec2 { x: 600.0, y: 400.0 }),
            ..NativeOptions::default()
        },
        Box::new(move |_cc| {
            let storage = Storage::default();

            let manager_storage = storage.clone();
            let init_reader = Box::new(if opt.sine {
                CountReader::init
            } else {
                FtReader::init
            });
            thread::spawn(move || UsbManager::start(manager_storage, init_reader));

            Box::new(storage)
        }),
    );
}
