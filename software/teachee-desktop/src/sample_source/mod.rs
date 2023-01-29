use std::{marker::PhantomData, thread, time::Duration};

use crate::storage::Storage;

mod ft;
mod sine;

// flatten module structure
pub use ft::FtSampleSource;
pub use sine::SineSampleSource;

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

/// A generic manager which reads from a given `SampleSource` in order to update `Storage` with data
/// for the UI.
pub struct Manager<T>
where
    T: SampleSource,
{
    storage: Storage,
    phantom: PhantomData<T>,
}

impl<T> Manager<T>
where
    T: SampleSource,
{
    /// Infinite loop which continually attempts to initialize the `SampleSource`.
    pub fn manager_loop(storage: Storage) {
        let mut manager = Self {
            storage,
            phantom: PhantomData,
        };

        loop {
            // sleep so we don't waste CPU cycles reinitializing a device which might not even be
            // plugged in.
            thread::sleep(Duration::from_secs(1));

            match T::try_init() {
                Ok(reader) => manager.read_samples_loop(reader),
                Err(error) => eprintln!("{:?}", error),
            }
        }
    }

    /// Inner loop which continually reads the `SampleSource` until an error occurs.
    fn read_samples_loop(&mut self, mut reader: T) {
        // TODO: set connection status flag on self.storage = true

        const SAMPLE_BUF_SIZE: usize = 100_000;
        let mut sample_buf = vec![0.0; SAMPLE_BUF_SIZE];

        loop {
            match reader.read_samples(&mut sample_buf) {
                Ok((num_samples, channel)) => {
                    self.handle_samples(channel, &sample_buf[0..num_samples])
                }
                Err(error) => {
                    eprintln!("{:?}", error);
                    // TODO: set connection status flag on self.storage = false
                    break;
                }
            }
        }
    }

    fn handle_samples(&mut self, _channel: Channel, samples: &[f64]) {
        self.storage.app.lock().unwrap().flip_flag();
        dbg!(samples);
        todo!("Do something with samples")
    }
}
