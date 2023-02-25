// hide console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::thread;

use eframe::{self, epaint::Vec2, NativeOptions, Theme};

use structopt::StructOpt;
use teachee_desktop::{
    app::App,
    controller::{AppData, Controller, USBData},
    sample_source::{FtSampleSource, Manager, SineSampleSource},
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
            let app_data = AppData::default();
            let controller_app_data = app_data.clone();

            let manager_data = USBData::default();
            let controller_manager_data = manager_data.clone();

            thread::Builder::new()
                .name("USB Manager".into())
                .spawn(move || {
                    if opt.sine {
                        Manager::<SineSampleSource>::manager_loop(manager_data)
                    } else {
                        Manager::<FtSampleSource>::manager_loop(manager_data)
                    }
                })
                .unwrap();

            thread::Builder::new()
                .name("Sample Controller".into())
                .spawn(move || {
                    Controller::new(controller_manager_data, controller_app_data).controller_loop()
                })
                .unwrap();

            Box::new(App::new(app_data))
        }),
    );
}
