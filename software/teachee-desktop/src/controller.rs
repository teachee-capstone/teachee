use std::{
    mem::take,
    sync::{Arc, Condvar, Mutex},
};

#[derive(Debug)]
pub enum BufferState {
    Full(Vec<f64>),
    Empty(Vec<f64>),
}

impl BufferState {
    pub fn is_empty(&self) -> bool {
        match *self {
            BufferState::Empty(_) => true,
            BufferState::Full(_) => false,
        }
    }

    pub fn is_full(&self) -> bool {
        match *self {
            BufferState::Empty(_) => false,
            BufferState::Full(_) => true,
        }
    }

    /// Fetch the Vec from the enum. take() is used to take ownership
    /// by swapping with an empty Vec.
    pub fn unwrap(&mut self) -> Vec<f64> {
        match self {
            BufferState::Empty(v) => take(&mut *v),
            BufferState::Full(v) => take(&mut *v),
        }
    }
}

const BUF_SIZE: usize = 1000;
const NUM_BUFS: usize = 2;
/// Represents two buffers that you can swap accesses between.
#[derive(Debug, Clone)]
pub struct Buffers {
    pub bufs: Vec<Arc<(Condvar, Mutex<BufferState>)>>,
}

impl Default for Buffers {
    fn default() -> Self {
        Self {
            bufs: {
                let mut v = Vec::with_capacity(NUM_BUFS);
                (0..NUM_BUFS).for_each(|_| {
                    v.push(Arc::new((
                        Condvar::new(),
                        Mutex::new(BufferState::Empty(vec![0.0; BUF_SIZE])),
                    )))
                });
                v
            },
        }
    }
}

/// Controller class copies from USB data buffer 1 into App data buffer 1,
/// then USB data buffer 2 into App data buffer 2.
pub struct Controller {
    data_buffers: Buffers,
    app_buffers: Buffers,
}

impl Controller {
    pub fn new(data_buffers: Buffers, app_buffers: Buffers) -> Self {
        Self {
            data_buffers,
            app_buffers,
        }
    }
    pub fn controller_loop(&mut self) {
        loop {
            let mut i = 0;
            // Cycle between the two buffers in each pair.
            for (dbuf, abuf) in self
                .data_buffers
                .bufs
                .iter()
                .zip(self.app_buffers.bufs.iter())
            {
                // TODO: ignore samples until trigger sample
                let (data_condvar, data_mutex) = &**dbuf;
                let (app_condvar, app_mutex) = &**abuf;

                // If the current USB buffer is empty, release lock, wait until USB thread has filled it.
                // When this function returns the lock will have been reacquired.
                let mut data_state = data_condvar
                    .wait_while(data_mutex.lock().unwrap(), |data_state| {
                        data_state.is_empty()
                    })
                    .unwrap();

                // Wait if app buffer is full.
                let mut app_state = app_condvar
                    .wait_while(app_mutex.lock().unwrap(), |app_state| app_state.is_full())
                    .unwrap();

                let mut dst = app_state.unwrap();
                let src = data_state.unwrap();
                dst.copy_from_slice(&src);

                *data_state = BufferState::Empty(src);
                *app_state = BufferState::Full(dst);

                // Tell USB thread that the current data buffer is now empty.
                data_condvar.notify_one();
                // Tell App thread that the current app buffer is now full.
                app_condvar.notify_one();
                println!("Copy {}", i);
                i ^= 0x1;
            }
        }
    }
}
