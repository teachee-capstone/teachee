#[derive(Debug)]
pub struct Storage {
    pub samples: Vec<f64>,
}

impl Default for Storage {
    fn default() -> Self {
        Self {
            samples: vec![0.0; 1000],
        }
    }
}
