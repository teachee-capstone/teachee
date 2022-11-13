use tauri::{AppHandle, Manager};

use crate::{canvas_state::CanvasState, scope_state::ScopeState, ui_event::UiEvent};
use std::{
    sync::{Arc, Mutex, MutexGuard},
    thread,
    time::Duration,
};

pub struct Storage {
    app: AppHandle,
    store: Arc<Mutex<ScopeState>>,
}

impl Storage {
    pub fn new(app: AppHandle) -> Self {
        Storage {
            app,
            store: Default::default(),
        }
    }

    pub fn lock(&self) -> MutexGuard<ScopeState> {
        self.store.lock().unwrap()
    }

    pub fn emit_state(&self) {
        self.app
            .emit_all("scope_state", self.lock().clone())
            .unwrap();
    }

    pub fn handle_ui_event(&self, event: UiEvent) {
        match event {
            UiEvent::SetChannel1(c) => {
                self.lock().channel1 = c;
            }
        }
        self.emit_state();
    }

    pub fn flip_flag(&self) {
        {
            let mut state = self.lock();
            state.flag = !state.flag;
        }
        self.emit_state();
    }

    pub fn to_canvas_state(&self, width: u64, height: u64) -> CanvasState {
        CanvasState {
            channel1: self.lock().channel1.to_points(width, height),
        }
    }

    pub fn usb_manager(&self) {
        loop {
            self.flip_flag();
            thread::sleep(Duration::from_secs(1));
        }
    }
}
