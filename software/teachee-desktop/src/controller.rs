use std::{
    mem::take,
    sync::{Arc, Condvar, Mutex, RwLock},
};

#[derive(Debug)]
pub enum BufferState {
    Full(Vec<f64>, usize),
    Empty(Vec<f64>),
}

impl BufferState {
    pub fn is_empty(&self) -> bool {
        match *self {
            BufferState::Empty(_) => true,
            BufferState::Full(..) => false,
        }
    }

    pub fn is_full(&self) -> bool {
        match *self {
            BufferState::Empty(_) => false,
            BufferState::Full(..) => true,
        }
    }

    /// Fetch the Vec from the enum. take() is used to take ownership
    /// by swapping with an empty Vec.
    pub fn unwrap(&mut self) -> (Vec<f64>, usize) {
        match self {
            BufferState::Empty(v) => (take(&mut *v), 0),
            BufferState::Full(v, num_samples) => (take(&mut *v), *num_samples),
        }
    }
}

const BUF_SIZE: usize = 1000;
const NUM_BUFS: usize = 2;
/// Represents two buffers that you can swap accesses between.
#[derive(Debug, Clone)]
pub struct USBData {
    pub bufs: Vec<Arc<(Condvar, Mutex<BufferState>)>>,
}

#[derive(Debug, Clone)]
pub struct AppData {
    pub bufs: Vec<Arc<(Condvar, Mutex<BufferState>)>>,
    pub trigger_value: Arc<RwLock<f64>>,
}

fn generate_buffers() -> Vec<Arc<(Condvar, Mutex<BufferState>)>> {
    let mut v = Vec::with_capacity(NUM_BUFS);
    (0..NUM_BUFS).for_each(|_| {
        v.push(Arc::new((
            Condvar::new(),
            Mutex::new(BufferState::Empty(vec![0.0; BUF_SIZE])),
        )))
    });
    v
}

impl Default for USBData {
    fn default() -> Self {
        Self {
            bufs: generate_buffers(),
        }
    }
}

impl Default for AppData {
    fn default() -> Self {
        Self {
            bufs: generate_buffers(),
            trigger_value: Arc::new(RwLock::new(0.0)),
        }
    }
}

/// Controller class copies from USB data buffer 1 into App data buffer 1,
/// then USB data buffer 2 into App data buffer 2.
pub struct Controller {
    usb_data: USBData,
    app_data: AppData,
}

impl Controller {
    pub fn new(usb_data: USBData, app_data: AppData) -> Self {
        Self { usb_data, app_data }
    }
    pub fn controller_loop(&mut self) {
        loop {
            let mut i = 0;
            // Cycle between the two buffers in each pair.
            for (dbuf, abuf) in self.usb_data.bufs.iter().zip(self.app_data.bufs.iter()) {
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

                let (mut dst, _) = app_state.unwrap();
                let (src, num_samples) = data_state.unwrap();
                Self::copy_with_trigger(
                    &mut dst,
                    &src,
                    num_samples,
                    *self.app_data.trigger_value.read().unwrap(),
                );

                *data_state = BufferState::Empty(src);
                *app_state = BufferState::Full(dst, num_samples);

                // Tell USB thread that the current data buffer is now empty.
                data_condvar.notify_one();
                // Tell App thread that the current app buffer is now full.
                app_condvar.notify_one();
                println!("Copy {}", i);
                i ^= 0x1;
            }
        }
    }

    fn copy_with_trigger(dst: &mut [f64], src: &[f64], num_samples: usize, trigger: f64) {
        if trigger > 0.0 {
            let first_lower = src.iter().position(|&val| val < trigger);
            if let Some(lower_idx) = first_lower {
                const WINDOW_SIZE: usize = 5;
                let mut sum: f64 = src[lower_idx..(lower_idx + WINDOW_SIZE)].iter().sum();

                // Iterate over all windows of size WINDOW_SIZE + 1. The first WINDOW_SIZE samples
                // are used to calculate the average value of previous samples, which is then
                // compared to the last (current) sample. This is done to find a rising trigger
                // while attempting to filter out noise.
                let first_higher = src[lower_idx..]
                    .windows(WINDOW_SIZE + 1)
                    .position(|window| {
                        let val = *window.last().unwrap();
                        val >= trigger && sum / (WINDOW_SIZE as f64) < val || {
                            // Update sliding window.
                            sum += val;
                            sum -= *window.first().unwrap();
                            false
                        }
                    });
                if let Some(higher_idx) = first_higher {
                    // higher_idx is relative to lower_idx. Also add WINDOW_SIZE to get the
                    // last element in the window.
                    let first_sample = lower_idx + higher_idx + WINDOW_SIZE;
                    dst[..(num_samples - first_sample)]
                        .copy_from_slice(&src[first_sample..num_samples]);
                    return;
                }
            }
        }

        // If no trigger or trigger search failed, just copy the available samples without triggering.
        dst[..num_samples].copy_from_slice(&src[..num_samples]);
    }
}
