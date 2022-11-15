// hide console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::path::PathBuf;

use eframe::{self, epaint::Vec2, NativeOptions, Theme};

use structopt::StructOpt;
use teachee_desktop::{
    storage::Storage,
    usb_manager::{ft_manger, mock_manager, spawn_manager},
};

#[derive(Debug, StructOpt)]
struct Opt {
    #[structopt(long, short)]
    mock_csv_path: Option<PathBuf>,
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
        Box::new(|_cc| {
            let storage = Storage::default();

            match opt.mock_csv_path {
                None => spawn_manager(storage.clone(), ft_manger),
                Some(_path) => spawn_manager(storage.clone(), mock_manager),
            };

            Box::new(storage)
        }),
    );
}
