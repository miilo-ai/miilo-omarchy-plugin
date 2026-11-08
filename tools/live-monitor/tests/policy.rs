use miilo_live_monitor::domain::{Frame, Machine, Measurement, Rule};
use std::collections::BTreeMap;
fn frame(revision: &str, state: &str) -> Frame {
    Frame {
        epoch: "study-v1".into(),
        revision: revision.into(),
        health: "healthy".into(),
        entities: BTreeMap::from([("run".into(), state.into())]),
        ..Frame::default()
    }
}
#[test]
fn baseline_restart_duplicate_and_distinct_incidents() {
    let mut machine = Machine::default();
    assert!(
        machine
            .observe("a", &frame("1", "completed"), &[], 0)
            .is_empty()
    );
    assert!(
        machine
            .observe("a", &frame("2", "running"), &[], 1)
            .is_empty()
    );
    let first = machine.observe("a", &frame("3", "failed"), &[], 2);
    assert_eq!(first[0].kind, "failed");
    let mut machine: Machine =
        serde_json::from_str(&serde_json::to_string(&machine).unwrap()).unwrap();
    assert!(
        machine
            .observe("a", &frame("3", "failed"), &[], 3)
            .is_empty()
    );
    machine.observe("a", &frame("4", "running"), &[], 4);
    let second = machine.observe("a", &frame("5", "failed"), &[], 5);
    assert_ne!(first[0].id, second[0].id);
}
#[test]
fn thresholds_require_fresh_samples_and_recover_with_hysteresis() {
    let rule = Rule {
        metric: "run/accuracy".into(),
        above: true,
        value: 0.8,
        margin: 0.1,
        consecutive: 2,
        min_samples: 10,
    };
    let mut machine = Machine::default();
    let mut current = frame("0", "running");
    machine.observe("a", &current, std::slice::from_ref(&rule), 0);
    for (i, samples, value, count) in [
        (1, 10, 0.9, 0),
        (2, 10, 0.9, 0),
        (3, 11, 0.9, 1),
        (4, 12, 0.75, 0),
        (5, 13, 0.69, 1),
    ] {
        current.revision = i.to_string();
        current
            .metrics
            .insert(rule.metric.clone(), Measurement { samples, value });
        assert_eq!(
            machine
                .observe("a", &current, std::slice::from_ref(&rule), i)
                .len(),
            count
        );
    }
    current.metrics.clear();
    current.revision = "6".into();
    assert!(machine.observe("a", &current, &[rule], 6).is_empty());
}
#[test]
fn disconnect_grace_recovery_and_epoch_change() {
    let mut machine = Machine::default();
    machine.observe("a", &frame("1", "running"), &[], 0);
    let offline = Frame {
        health: "unavailable".into(),
        ..Frame::default()
    };
    assert!(machine.observe("a", &offline, &[], 1).is_empty());
    assert_eq!(
        machine.observe("a", &offline, &[], 30_001)[0].kind,
        "connection_lost"
    );
    assert!(machine.observe("a", &offline, &[], 31_000).is_empty());
    let mut other = frame("2", "completed");
    other.epoch = "different-study".into();
    let events = machine.observe("a", &other, &[], 32_000);
    assert_eq!(events.len(), 1);
    assert_eq!(events[0].kind, "recovered");
}
#[test]
fn burst_progress_is_not_an_alert_stream() {
    let mut machine = Machine::default();
    for i in 0..10000 {
        assert!(
            machine
                .observe("a", &frame(&i.to_string(), "running"), &[], i)
                .is_empty()
        );
    }
    let result = machine.observe("a", &frame("10001", "completed"), &[], 10001);
    assert_eq!(result.len(), 1);
    assert_eq!(result[0].kind, "completed");
    assert!(serde_json::to_vec(&machine).unwrap().len() < 2048);
}

#[test]
fn resume_discloses_coverage_gap_and_removed_rules_do_not_accumulate() {
    let mut machine = Machine::default();
    let frame = Frame {
        epoch: "fixture".into(),
        revision: "one".into(),
        health: "artifact".into(),
        ..Frame::default()
    };
    assert!(machine.observe("source", &frame, &[], 1).is_empty());
    let events = machine.observe("source", &frame, &[], 100_000);
    assert_eq!(events.len(), 1);
    assert_eq!(events[0].kind, "coverage_gap");
    assert!(machine.observe("source", &frame, &[], 100_001).is_empty());
    assert!(serde_json::to_string(&machine).unwrap().len() < 1024);
}

#[test]
fn partial_coverage_preserves_observed_incidents_without_inventing_missing_completions() {
    let mut machine = Machine::default();
    let mut frame = Frame {
        epoch: "fixture".into(),
        revision: "one".into(),
        health: "healthy".into(),
        entities: std::collections::BTreeMap::from([
            ("a".into(), "running".into()),
            ("b".into(), "running".into()),
        ]),
        ..Frame::default()
    };
    assert!(machine.observe("source", &frame, &[], 1).is_empty());
    frame.health = "partial".into();
    frame.revision = "two".into();
    frame.entities.remove("b");
    frame.entities.insert("a".into(), "failed".into());
    let events = machine.observe("source", &frame, &[], 2);
    assert_eq!(events.len(), 1);
    assert_eq!(events[0].target, "a");
    assert_eq!(events[0].kind, "failed");
    frame.health = "healthy".into();
    frame.revision = "three".into();
    frame.entities.insert("b".into(), "completed".into());
    let events = machine.observe("source", &frame, &[], 3);
    assert_eq!(events.len(), 1);
    assert_eq!(events[0].target, "b");
    assert_eq!(events[0].kind, "completed");
}
