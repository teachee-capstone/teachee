// hide console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::{thread, sync::{Arc, Mutex, Condvar}};

use eframe::{self, epaint::Vec2, NativeOptions, Theme};

use structopt::StructOpt;
use teachee_desktop::{
    sample_source::{FtSampleSource, Manager, SineSampleSource},
    storage::Storage, controller::{Buffers, Controller}, app::App,
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
            let app_storage = Arc::new((Condvar::new(), Mutex::new(Storage::default())));
            let controller_storage = app_storage.clone();

            let manager_buffers = Buffers::default();
            let controller_buffers = manager_buffers.clone();

            thread::Builder::new().name("USB Manager".into()).spawn(move || {
                if opt.sine {
                    Manager::<SineSampleSource>::manager_loop(manager_buffers)
                } else {
                    Manager::<FtSampleSource>::manager_loop(manager_buffers)
                }
            });

            thread::Builder::new().name("Sample Controller".into()).spawn(move || {
                Controller::new(controller_buffers, controller_storage).controller_loop()
            });

            Box::new(App::new(app_storage))
        }),
    );
}
