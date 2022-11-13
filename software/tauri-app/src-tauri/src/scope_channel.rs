use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub enum ScopeChannel {
    Off,
    TriangleWave,
}

impl ScopeChannel {
    pub fn to_points(&self, width: u64, height: u64) -> Vec<(u64, u64)> {
        match self {
            ScopeChannel::Off => Vec::new(),
            ScopeChannel::TriangleWave => {
                let mut result = Vec::with_capacity(width as usize);
                for (i, x) in (0..=width).step_by(10).enumerate() {
                    let y = if i % 2 == 0 {
                        height / 2
                    } else {
                        height / 3 * 2
                    };
                    result.push((x, y))
                }
                result
            }
        }
    }
}
