use serde::{Deserialize, Serialize};

pub const RATE: usize = 16_000;
pub const FRAME: usize = 480;
#[derive(Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Config {
    pub wake_phrase: String,
    pub silence_ms: u32,
}
impl Config {
    pub fn validate(&self) -> Result<(), String> {
        let words = self.wake_phrase.split_whitespace().count();
        if !(2..=6).contains(&words)
            || self.wake_phrase.len() > 80
            || !self
                .wake_phrase
                .chars()
                .all(|c| c.is_ascii_alphabetic() || c == ' ')
        {
            return Err("Use a wake phrase of two to six English words.".into());
        }
        if !(700..=2500).contains(&self.silence_ms) {
            return Err("The silence delay must be between 700 and 2500 milliseconds.".into());
        }
        Ok(())
    }
    pub fn detector_phrase(&self) -> String {
        self.phrase()
            .split_whitespace()
            .map(|word| if word == "miilo" { "milo" } else { word })
            .collect::<Vec<_>>()
            .join(" ")
    }
    pub fn phrase(&self) -> String {
        self.wake_phrase
            .split_whitespace()
            .map(str::to_ascii_lowercase)
            .collect::<Vec<_>>()
            .join(" ")
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Phase {
    Muted,
    Waiting,
    Listening,
    Transcribing,
    Paused,
}
#[derive(Debug, PartialEq, Eq)]
pub enum Decision {
    None,
    Complete,
    Discard,
}
pub struct Turn {
    pub frames: usize,
    voiced: usize,
    silence: usize,
    end_silence: usize,
}
impl Turn {
    pub fn new(silence_ms: u32) -> Self {
        Self {
            frames: 0,
            voiced: 0,
            silence: 0,
            end_silence: silence_ms.div_ceil(30) as usize,
        }
    }
    pub fn feed(&mut self, speech: bool) -> Decision {
        self.frames += 1;
        if speech {
            self.voiced += 1;
            self.silence = 0;
        } else {
            self.silence += 1;
        }
        if self.frames >= 1000 || (self.voiced == 0 && self.frames >= 167) {
            return Decision::Discard;
        }
        if self.voiced >= 8 && self.silence >= self.end_silence {
            Decision::Complete
        } else {
            Decision::None
        }
    }
}
#[derive(Default)]
pub struct Gate {
    pub muted: bool,
    pub paused: bool,
    pub generation: u64,
}
impl Gate {
    pub fn invalidate(&mut self) {
        self.generation += 1;
    }
    pub fn mute(&mut self) {
        self.muted = true;
        self.invalidate();
    }
    pub fn accepts(&self, generation: u64) -> bool {
        !self.muted && !self.paused && self.generation == generation
    }
}
