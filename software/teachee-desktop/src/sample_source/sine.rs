use std::{
    thread,
    time::{Duration, Instant},
};

use super::{Channel, Result, SampleSource};

const SAMPLE_DELAY_SEC: f64 = 1.0 / 10_000.0;
const CHUNK_DELAY_SEC: f64 = 1.0 / 100.0;

const SINE_PERIOD_SEC: f64 = 1.0 / 60.0;
const SINE_AMPLITUDE: f64 = 1.0;

/// A sample source that outputs a sine wave on one channel
pub struct SineSampleSource {
    start: Instant,
    last_read: Instant,
}

impl SampleSource for SineSampleSource {
    fn try_init() -> Result<Self> {
        let now = Instant::now();
        Ok(Self {
            start: now,
            last_read: now,
        })
    }

    fn read_samples(&mut self, samples: &mut [f64]) -> Result<(usize, Channel)> {
        // sleep to emulate blocking read
        thread::sleep(Duration::from_secs_f64(CHUNK_DELAY_SEC));

        let now = Instant::now();
        let num_samples = ((now - self.last_read).as_secs_f64() / SAMPLE_DELAY_SEC) as usize;
        let mut t = (now - self.start).as_secs_f64() % SINE_PERIOD_SEC;

        for sample in samples.iter_mut().take(num_samples) {
            t = (t + SAMPLE_DELAY_SEC) % SINE_PERIOD_SEC;
            *sample = SINE_AMPLITUDE * (t * SINE_PERIOD_SEC).sin();
        }

        Ok((num_samples, Channel::VoltageA))
    }
}
