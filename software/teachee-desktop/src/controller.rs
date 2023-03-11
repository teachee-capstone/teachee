use std::{
    cmp::min,
    mem::take,
    sync::{Arc, Condvar, Mutex, RwLock},
};

// Number of samples in each channel's buffer
const BUF_SIZE: usize = 10000;
const NUM_BUFS: usize = 2;

#[derive(Debug)]
pub struct Channels {
    pub voltage1: Vec<f64>,
    pub current1: Vec<f64>,
}

impl Default for Channels {
    fn default() -> Self {
        Self {
            voltage1: vec![0.0; BUF_SIZE],
            current1: vec![0.0; BUF_SIZE],
        }
    }
}

#[derive(Debug)]
pub enum BufferState {
    Full(Channels, usize),
    Empty(Channels),
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

    /// Fetch the Channels from the enum. take() is used to take ownership
    /// by swapping with an empty Channels.
    pub fn unwrap(&mut self) -> (Channels, usize) {
        match self {
            BufferState::Empty(c) => (take(&mut *c), 0),
            BufferState::Full(c, num_samples) => (take(&mut *c), *num_samples),
        }
    }
}

/// Represents two buffers that you can swap accesses between.
#[derive(Debug, Clone)]
pub struct USBData {
    pub bufs: Vec<Arc<(Condvar, Mutex<BufferState>)>>,
}

#[derive(Debug, Clone)]
pub struct AppData {
    pub bufs: Vec<Arc<(Condvar, Mutex<BufferState>)>>,
    pub voltage_trigger_threshold: Arc<RwLock<f64>>,
    pub current_trigger_threshold: Arc<RwLock<f64>>,
}

fn generate_buffers() -> Vec<Arc<(Condvar, Mutex<BufferState>)>> {
    let mut v = Vec::with_capacity(NUM_BUFS);
    (0..NUM_BUFS).for_each(|_| {
        v.push(Arc::new((
            Condvar::new(),
            Mutex::new(BufferState::Empty(Channels::default())),
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
            voltage_trigger_threshold: Arc::new(RwLock::new(0.0)),
            current_trigger_threshold: Arc::new(RwLock::new(0.0)),
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
                let num_remaining = Self::copy_channels(
                    &mut dst,
                    &src,
                    num_samples,
                    *self.app_data.voltage_trigger_threshold.read().unwrap(),
                    *self.app_data.current_trigger_threshold.read().unwrap(),
                );

                *data_state = BufferState::Empty(src);
                *app_state = BufferState::Full(dst, num_remaining);

                // Tell USB thread that the current data buffer is now empty.
                data_condvar.notify_one();
                // Tell App thread that the current app buffer is now full.
                app_condvar.notify_one();
            }
        }
    }

    fn copy_channels(
        dst: &mut Channels,
        src: &Channels,
        num_samples: usize,
        v_trigger: f64,
        c_trigger: f64,
    ) -> usize {
        // Return the least number of samples between the two channels (discard some from the channel with more)
        min(
            Self::copy_with_trigger(&mut dst.voltage1, &src.voltage1, num_samples, v_trigger),
            Self::copy_with_trigger(&mut dst.current1, &src.current1, num_samples, c_trigger),
        )
    }

    fn copy_with_trigger(dst: &mut [f64], src: &[f64], num_samples: usize, trigger: f64) -> usize {
        if trigger > -15.0 && trigger < 15.0 {
            let first_sample: usize;
            #[cfg(feature = "window_trigger")]
            {
                first_sample = Self::window_trigger(&src[..num_samples], trigger);
            }
            #[cfg(not(feature = "window_trigger"))]
            {
                first_sample = Self::hysteresis_trigger(&src[..num_samples], trigger);
            }

            dst[..(num_samples - first_sample)].copy_from_slice(&src[first_sample..num_samples]);

            return num_samples - first_sample;
        }

        // If no trigger, just copy the available samples without triggering.
        dst[..num_samples].copy_from_slice(&src[..num_samples]);
        num_samples
    }

    #[cfg(feature = "window_trigger")]
    fn window_trigger(src: &[f64], trigger: f64) -> usize {
        let first_lower = src.iter().position(|&val| val < trigger);
        if let Some(lower_idx) = first_lower {
            const WINDOW_SIZE: usize = 10;
            let mut sum: f64 = src[lower_idx..(lower_idx + WINDOW_SIZE)].iter().sum();

            // Iterate over all windows of size WINDOW_SIZE + 1. The first WINDOW_SIZE samples
            // are used to calculate the average value of previous samples, which is then
            // compared to the last sample. This is done to find a rising trigger
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
                return lower_idx + higher_idx + WINDOW_SIZE;
            }
        }

        // If trigger failed, copy without trigger
        0
    }

    #[cfg(not(feature = "window_trigger"))]
    fn hysteresis_trigger(src: &[f64], trigger: f64) -> usize {
        // Hysteresis width as fraction of peak to peak
        const HYSTERESIS_WIDTH: f64 = 0.25;
        let mut max_val = f64::MIN;
        let mut min_val = f64::MAX;
        for &val in src.iter() {
            max_val = f64::max(max_val, val);
            min_val = f64::min(min_val, val);
        }
        let hysteresis = (max_val - min_val) * HYSTERESIS_WIDTH;

        // Trigger when signal first falls below trigger - hysteresis and then rises above trigger
        let first_lower = src.iter().position(|&val| val < trigger - hysteresis);
        if let Some(lower_idx) = first_lower {
            let first_higher = src[lower_idx..].iter().position(|&val| val >= trigger);
            if let Some(higher_idx) = first_higher {
                return lower_idx + higher_idx;
            }
        }

        0
    }
}
