use crate::{
    domain::{Config, Decision, FRAME, Gate, Phase, RATE, Turn},
    ports::{ActivityDetector, WakeDetector},
};
use std::collections::VecDeque;

pub struct Session<W, V> {
    pub gate: Gate,
    pub phase: Phase,
    wake: W,
    activity: V,
    config: Config,
    buffer: VecDeque<i16>,
    turn: Option<Turn>,
    samples: usize,
}
impl<W: WakeDetector, V: ActivityDetector> Session<W, V> {
    pub fn new(wake: W, activity: V, config: Config) -> Result<Self, String> {
        config.validate()?;
        Ok(Self {
            gate: Gate {
                muted: true,
                ..Gate::default()
            },
            phase: Phase::Muted,
            wake,
            activity,
            config,
            buffer: VecDeque::new(),
            turn: None,
            samples: 0,
        })
    }
    fn clear(&mut self) {
        self.buffer.clear();
        self.turn = None;
        self.samples = 0;
        self.wake.reset();
    }
    pub fn mute(&mut self) {
        self.gate.mute();
        self.clear();
        self.phase = Phase::Muted;
    }
    pub fn unmute(&mut self) {
        self.gate.muted = false;
        self.gate.invalidate();
        self.clear();
        self.phase = if self.gate.paused {
            Phase::Paused
        } else {
            Phase::Waiting
        };
    }
    pub fn pause(&mut self, paused: bool) {
        if self.gate.paused != paused {
            self.gate.paused = paused;
            self.gate.invalidate();
            self.clear();
            self.phase = if self.gate.muted {
                Phase::Muted
            } else if paused {
                Phase::Paused
            } else {
                Phase::Waiting
            };
        }
    }
    pub fn completed(&mut self) {
        self.clear();
        self.phase = Phase::Paused;
        self.gate.paused = true;
    }
    pub fn feed(&mut self, frame: &[i16; FRAME]) -> Result<Option<Vec<i16>>, String> {
        if self.gate.muted || self.gate.paused || self.phase == Phase::Transcribing {
            return Ok(None);
        }
        self.samples += FRAME;
        self.buffer.extend(frame);
        if self.phase == Phase::Waiting {
            while self.buffer.len() > RATE * 35 {
                self.buffer.pop_front();
            }
            if let Some(end) = self.wake.feed(frame)? {
                let start = self.samples.saturating_sub(self.buffer.len());
                if end < start || end > self.samples {
                    self.clear();
                    return Ok(None);
                }
                self.buffer.drain(..end - start);
                self.turn = Some(Turn::new(self.config.silence_ms));
                self.phase = Phase::Listening;
                let buffered: Vec<i16> = self.buffer.iter().copied().collect();
                for frame in buffered.as_chunks::<FRAME>().0 {
                    let speech = self.activity.speech(frame)?;
                    match self
                        .turn
                        .as_mut()
                        .ok_or("No active voice turn.")?
                        .feed(speech)
                    {
                        Decision::Complete => {
                            self.phase = Phase::Transcribing;
                            return Ok(Some(self.buffer.drain(..).collect()));
                        }
                        Decision::Discard => {
                            self.clear();
                            self.phase = Phase::Waiting;
                            return Ok(None);
                        }
                        Decision::None => {}
                    }
                }
            }
            return Ok(None);
        }
        let speech = self.activity.speech(frame)?;
        match self
            .turn
            .as_mut()
            .ok_or("No active voice turn.")?
            .feed(speech)
        {
            Decision::None => Ok(None),
            Decision::Discard => {
                self.clear();
                self.phase = Phase::Waiting;
                Ok(None)
            }
            Decision::Complete => {
                self.phase = Phase::Transcribing;
                Ok(Some(self.buffer.drain(..).collect()))
            }
        }
    }
}
