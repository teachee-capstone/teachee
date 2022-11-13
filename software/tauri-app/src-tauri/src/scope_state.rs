use crate::scope_channel::ScopeChannel;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ScopeState {
    pub flag: bool,
    pub channel1: ScopeChannel,
}

impl Default for ScopeState {
    fn default() -> Self {
        ScopeState {
            flag: false,
            channel1: ScopeChannel::Off,
        }
    }
}
