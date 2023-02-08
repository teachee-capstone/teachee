use std::sync::{Arc, Mutex, Condvar};

use crate::storage::Storage;

const BUF_SIZE: usize = 1000;
const NUM_BUFS: usize = 2;
#[derive(Clone)]
pub struct Buffers {
    pub bufs: Vec<Arc<(Condvar, Mutex<Vec<f64>>)>>,
}

pub struct Controller {
    buffers: Buffers,
    storage: Arc<(Condvar, Mutex<Storage>)>,
}

impl Default for Buffers {
    fn default() -> Self {
        Self {
            bufs: vec![Arc::new((Condvar::new(), Mutex::new(vec![0.0; BUF_SIZE]))); NUM_BUFS],
        }
    }
}

impl Controller {
    pub fn new(buffers: Buffers, storage: Arc<(Condvar, Mutex<Storage>)>) -> Self {
        Self {
            buffers,
            storage,
        }
    }
    pub fn controller_loop(&mut self) {
        loop {
            let mut i = false;
            for buf in self.buffers.bufs.iter() {
                // TODO: ignore samples until trigger sample
                let buf_condvar = &buf.0;
                let buf_mutex = buf.1.lock().unwrap();
                let (app_condvar, app_mutex) = &*self.storage;
                let mut app_guard = app_mutex.lock().unwrap();
                app_guard.samples.copy_from_slice(&buf_mutex);
                app_condvar.notify_all();
                buf_condvar.notify_all();
                println!("Copy {}", i as u32);
                i = true;
                app_condvar.wait(app_guard);
                buf_condvar.wait(buf_mutex);
            }
        }
    }
}
