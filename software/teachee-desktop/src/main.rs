// hide console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::thread;

use eframe::{self, epaint::Vec2, NativeOptions, Theme};

use structopt::StructOpt;
use teachee_desktop::{
    sample_source::{FtSampleSource, Manager, SineSampleSource},
    storage::Storage,
};

#[derive(Debug, StructOpt)]
struct Opt {
    /// Read fake sine data instead of a real TeachEE device
    #[structopt(short, long)]
    sine: bool,
}

fn main() {
    let options = NativeOptions {
        default_theme: Theme::Light,
        min_window_size: Some(Vec2 { x: 496.0, y: 518.0 }),
        ..NativeOptions::default()
    };

    let opt = Opt::from_args();

    eframe::run_native(
        "TeachEE",
        options,
        Box::new(move |_cc| {
            let storage = Storage::default();
            let manager_storage = storage.clone();

            thread::spawn(move || {
                if opt.sine {
                    Manager::<SineSampleSource>::manager_loop(manager_storage)
                } else {
                    Manager::<FtSampleSource>::manager_loop(manager_storage)
                }
            });

            Box::new(storage)
        }),
    );
}
