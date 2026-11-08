use crate::domain::{Event, Frame, Machine, Rule};

pub trait ObservationPort {
    fn read(&mut self) -> Result<Frame, String>;
}
pub trait NotificationPort {
    fn deliver(&mut self, events: &[Event]) -> Result<(), String>;
}

pub fn sample(
    source: &str,
    observer: &mut impl ObservationPort,
    machine: &mut Machine,
    rules: &[Rule],
    now: u64,
) -> (Frame, Vec<Event>) {
    let frame = observer.read().unwrap_or_else(|_| Frame {
        health: "unavailable".into(),
        ..Frame::default()
    });
    let events = machine.observe(source, &frame, rules, now);
    (frame, events)
}
