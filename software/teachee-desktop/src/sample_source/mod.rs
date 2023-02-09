use std::{marker::PhantomData, thread, time::Duration};

mod ft;
mod sine;

// flatten module structure
pub use ft::FtSampleSource;
pub use sine::SineSampleSource;

use crate::controller::{BufferState, Buffers};

pub type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;

pub enum Channel {
    VoltageA,
    VoltageB,
    VoltageC,
    Current,
}

/// A trait which represents a source of samples. Could be a real TeachEE or a mock data.
pub trait SampleSource {
    /// Attempt to init sample source.
    fn try_init() -> Result<Self>
    where
        Self: Sized;

    /// Read samples into a pre-allocated buffer. Return the number of samples written and their
    /// channel.
    fn read_samples(&mut self, samples: &mut [f64]) -> Result<(usize, Channel)>;
}

/// A generic manager which reads from a given `SampleSource` into shared buffers.
pub struct Manager<T>
where
    T: SampleSource,
{
    buffers: Buffers,
    phantom: PhantomData<T>,
}

impl<T> Manager<T>
where
    T: SampleSource,
{
    /// Infinite loop which continually attempts to initialize the `SampleSource`.
    pub fn manager_loop(buffers: Buffers) {
        let mut manager = Self {
            buffers,
            phantom: PhantomData,
        };

        loop {
            // sleep so we don't waste CPU cycles reinitializing a device which might not even be
            // plugged in.
            thread::sleep(Duration::from_secs(1));

            match T::try_init() {
                Ok(reader) => manager.read_samples_loop(reader),
                Err(error) => eprintln!("{error:?}"),
            }
        }
    }

    /// Inner loop which continually reads the `SampleSource` until an error occurs.
    fn read_samples_loop(&mut self, mut reader: T) {
        // TODO: set connection status flag on self.storage = true

        loop {
            let mut i = 0;
            for buf in self.buffers.bufs.iter() {
                let (condvar, mutex) = &**buf;

                let mut buf_state = condvar
                    .wait_while(mutex.lock().unwrap(), |buf_state| buf_state.is_full())
                    .unwrap();

                let mut buffer = buf_state.unwrap();
                if let Err(error) = reader.read_samples(&mut buffer) {
                    eprintln!("{error:?}");
                    // TODO: set connection status flag on self.storage = false
                    return;
                }

                // Tell Controller that this buffer is full, and wake them up if waiting.
                *buf_state = BufferState::Full(buffer);
                condvar.notify_one();
                println!("Read {}", i);
                i ^= 0x1;
            }
        }
    }

    fn handle_samples(&mut self, _channel: Channel, samples: &[f64]) {
        // self.storage.app.lock().unwrap().points[..samples.len()].copy_from_slice(&samples[..]);
        // dbg!(samples);
        // todo!("Do something with samples")
    }
}
