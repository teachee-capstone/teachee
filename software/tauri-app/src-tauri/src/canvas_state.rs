use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone)]
pub struct CanvasState {
    pub channel1: Vec<(u64, u64)>,
}
