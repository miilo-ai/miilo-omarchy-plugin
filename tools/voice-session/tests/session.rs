use miilo_voice_session::{
    application::Session,
    domain::{Config, Decision, FRAME, Gate, Phase, Turn},
    ports::{ActivityDetector, WakeDetector},
};
struct Wake {
    frames: usize,
    hit: bool,
}
impl WakeDetector for Wake {
    fn feed(&mut self, _: &[i16]) -> Result<Option<usize>, String> {
        self.frames += 1;
        Ok((self.hit && self.frames == 2).then_some(FRAME * 2))
    }
    fn reset(&mut self) {
        self.frames = 0;
    }
}
struct Voice(bool);
impl ActivityDetector for Voice {
    fn speech(&mut self, _: &[i16; FRAME]) -> Result<bool, String> {
        Ok(self.0)
    }
}
fn config() -> Config {
    Config {
        wake_phrase: "hey computer".into(),
        silence_ms: 1000,
    }
}
fn session(hit: bool) -> Session<Wake, Voice> {
    Session::new(Wake { frames: 0, hit }, Voice(true), config()).unwrap()
}
#[test]
fn silence_never_becomes_a_question() {
    let mut turn = Turn::new(1000);
    for _ in 0..166 {
        assert_eq!(turn.feed(false), Decision::None);
    }
    assert_eq!(turn.feed(false), Decision::Discard);
}
#[test]
fn silence_delay_follows_real_speech() {
    let mut turn = Turn::new(1000);
    for _ in 0..8 {
        assert_eq!(turn.feed(true), Decision::None);
    }
    for _ in 0..33 {
        assert_eq!(turn.feed(false), Decision::None);
    }
    assert_eq!(turn.feed(false), Decision::Complete);
}
#[test]
fn short_noise_is_not_a_turn() {
    let mut turn = Turn::new(1000);
    for _ in 0..3 {
        turn.feed(true);
    }
    for _ in 0..900 {
        assert_ne!(turn.feed(false), Decision::Complete);
    }
}
#[test]
fn maximum_turn_is_discarded_not_truncated_and_sent() {
    let mut turn = Turn::new(1000);
    for _ in 0..999 {
        assert_eq!(turn.feed(true), Decision::None);
    }
    assert_eq!(turn.feed(true), Decision::Discard);
}
#[test]
fn starts_muted_without_capture() {
    let mut s = session(true);
    for _ in 0..10 {
        assert!(s.feed(&[0; FRAME]).unwrap().is_none());
    }
    assert_eq!(s.phase, Phase::Muted);
}
#[test]
fn background_speech_without_wake_does_not_open_a_turn() {
    let mut s = session(false);
    s.unmute();
    for _ in 0..300 {
        assert!(s.feed(&[100; FRAME]).unwrap().is_none());
    }
    assert_eq!(s.phase, Phase::Waiting);
}
#[test]
fn wake_then_mute_discards_recording_and_stays_muted() {
    let mut s = session(true);
    s.unmute();
    s.feed(&[1; FRAME]).unwrap();
    s.feed(&[1; FRAME]).unwrap();
    assert_eq!(s.phase, Phase::Listening);
    s.mute();
    for _ in 0..200 {
        s.feed(&[1; FRAME]).unwrap();
    }
    assert_eq!(s.phase, Phase::Muted);
}
#[test]
fn pause_does_not_unmute() {
    let mut s = session(true);
    s.pause(true);
    s.pause(false);
    assert_eq!(s.phase, Phase::Muted);
}
#[test]
fn late_transcript_after_mute_cannot_send() {
    let mut gate = Gate::default();
    let generation = gate.generation;
    assert!(gate.accepts(generation));
    gate.mute();
    assert!(!gate.accepts(generation));
    gate.muted = false;
    assert!(!gate.accepts(generation));
}
#[test]
fn completed_turn_waits_for_explicit_resume() {
    let mut s = session(true);
    s.unmute();
    s.completed();
    assert_eq!(s.phase, Phase::Paused);
    s.feed(&[1; FRAME]).unwrap();
    assert_eq!(s.phase, Phase::Paused);
    s.pause(false);
    assert_eq!(s.phase, Phase::Waiting);
}
#[test]
fn configuration_is_bounded_and_not_shell_code() {
    for phrase in ["hi", "hey; computer", "hey $(id)", ""] {
        let mut c = config();
        c.wake_phrase = phrase.into();
        assert!(c.validate().is_err());
    }
    let mut c = config();
    c.silence_ms = 10;
    assert!(c.validate().is_err());
}
#[test]
fn branded_phrase_uses_explicit_phonetic_alias() {
    let mut c = config();
    c.wake_phrase = "Hey Miilo".into();
    assert_eq!(c.phrase(), "hey miilo");
    assert_eq!(c.detector_phrase(), "hey milo");
}
