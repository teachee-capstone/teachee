#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use std::thread;
use tauri::{Manager, State};
use teachee::{
    canvas_state::CanvasState, scope_state::ScopeState, storage::Storage, ui_event::UiEvent,
};

#[tauri::command]
fn get_scope_state(storage: State<Storage>) -> ScopeState {
    storage.lock().clone()
}

#[tauri::command]
fn update_scope_state(storage: State<Storage>, event: UiEvent) {
    storage.handle_ui_event(event)
}

#[tauri::command]
fn get_canvas_state(storage: State<Storage>, width: u64, height: u64) -> CanvasState {
    storage.to_canvas_state(width, height)
}

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            let handle = app.app_handle();
            handle.manage(Storage::new(handle.clone()));
            thread::spawn(move || handle.state::<Storage>().usb_manager());
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            get_scope_state,
            update_scope_state,
            get_canvas_state
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
