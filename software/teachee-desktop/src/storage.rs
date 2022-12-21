#[derive(Debug, Default, Clone)]
pub struct Storage {
    // TODO: Add buffer and other shared data
    flag: bool,
}

impl Storage {
    pub fn read_flag(&self) -> bool {
        self.flag
    }
    pub fn flip_flag(&mut self) {
        self.flag = !self.flag;
    }
}
