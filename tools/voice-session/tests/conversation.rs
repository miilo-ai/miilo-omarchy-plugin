use miilo_voice_session::{
    application::Session,
    domain::{Config, FRAME, Phase},
    ports::{ActivityDetector, WakeDetector},
};

struct OneWake(usize);
impl WakeDetector for OneWake {
    fn feed(&mut self, _: &[i16]) -> Result<Option<usize>, String> {
        self.0 += 1;
        Ok((self.0 == 2).then_some(FRAME * 2))
    }
    fn reset(&mut self) {}
}
struct Speech;
impl ActivityDetector for Speech {
    fn speech(&mut self, frame: &[i16; FRAME]) -> Result<bool, String> {
        Ok(frame[0] != 0)
    }
}
fn session() -> Session<OneWake, Speech> {
    let mut session = Session::new(
        OneWake(0),
        Speech,
        Config {
            wake_phrase: "hey miilo".into(),
            silence_ms: 1000,
        },
    )
    .unwrap();
    session.unmute();
    session.feed(&[1; FRAME]).unwrap();
    session.feed(&[1; FRAME]).unwrap();
    assert_eq!(session.phase, Phase::Listening);
    session
}
fn question(session: &mut Session<OneWake, Speech>) {
    for _ in 0..8 {
        assert!(session.feed(&[100; FRAME]).unwrap().is_none());
    }
    for _ in 0..33 {
        assert!(session.feed(&[0; FRAME]).unwrap().is_none());
    }
    assert!(session.feed(&[0; FRAME]).unwrap().is_some());
    assert_eq!(session.phase, Phase::Transcribing);
}
#[test]
fn follow_up_needs_no_wake_or_click_after_reply() {
    let mut session = session();
    question(&mut session);
    session.completed();
    for _ in 0..100 {
        assert!(session.feed(&[100; FRAME]).unwrap().is_none());
    }
    assert_eq!(session.phase, Phase::Paused);
    session.pause(false);
    assert_eq!(session.phase, Phase::Listening);
    question(&mut session);
    session.completed();
    session.pause(false);
    question(&mut session);
}
#[test]
fn quiet_gaps_do_not_end_conversation_but_mute_requires_wake_again() {
    let mut session = session();
    for _ in 0..400 {
        assert!(session.feed(&[0; FRAME]).unwrap().is_none());
    }
    assert_eq!(session.phase, Phase::Listening);
    question(&mut session);
    session.completed();
    session.mute();
    session.pause(false);
    assert_eq!(session.phase, Phase::Muted);
    session.unmute();
    for _ in 0..100 {
        assert!(session.feed(&[100; FRAME]).unwrap().is_none());
    }
    assert_eq!(session.phase, Phase::Waiting);
}
