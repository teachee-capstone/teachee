use std::{marker::PhantomData, thread, time::Duration};

mod ft;
mod sine;

// flatten module structure
pub use ft::FtSampleSource;
pub use sine::SineSampleSource;

use crate::controller::{BufferState, USBData};

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
    data: USBData,
    phantom: PhantomData<T>,
}

impl<T> Manager<T>
where
    T: SampleSource,
{
    /// Infinite loop which continually attempts to initialize the `SampleSource`.
    pub fn manager_loop(data: USBData) {
        let mut manager = Self {
            data,
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
            for buf in self.data.bufs.iter() {
                let (condvar, mutex) = &**buf;

                let mut buf_state = condvar
                    .wait_while(mutex.lock().unwrap(), |buf_state| buf_state.is_full())
                    .unwrap();

                let (mut buffer, _) = buf_state.unwrap();
                match reader.read_samples(&mut buffer) {
                    Ok((num_samples, _channel)) => {
                        // Tell Controller that this buffer is full, and wake them up if waiting.
                        *buf_state = BufferState::Full(buffer, num_samples);
                        condvar.notify_one();
                        println!("Read {}, {} samples", i, num_samples);
                        i ^= 0x1;
                    }
                    Err(error) => {
                        eprintln!("{error:?}");
                        // TODO: set connection status flag on self.storage = false
                        return;
                    }
                }
            }
        }
    }
}
