use crate::scope_channel::ScopeChannel;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub enum UiEvent {
    SetChannel1(ScopeChannel),
}
