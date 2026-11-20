use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

#[derive(Clone, Default, Serialize, Deserialize)]
pub struct Frame {
    #[serde(default)]
    pub epoch: String,
    pub revision: String,
    pub health: String,
    pub entities: BTreeMap<String, String>,
    #[serde(default)]
    pub metrics: BTreeMap<String, Measurement>,
}
#[derive(Clone, Serialize, Deserialize)]
pub struct Measurement {
    pub value: f64,
    pub samples: u64,
}
#[derive(Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Rule {
    pub metric: String,
    pub above: bool,
    pub value: f64,
    pub margin: f64,
    pub consecutive: u8,
    pub min_samples: u64,
}
impl Rule {
    pub fn validate(&self) -> bool {
        !self.metric.is_empty()
            && self.metric.len() <= 256
            && self.value.is_finite()
            && self.margin.is_finite()
            && self.margin >= 0.0
            && (2..=20).contains(&self.consecutive)
            && self.min_samples >= 10
    }
}
#[derive(Clone, Serialize, Deserialize)]
pub struct Event {
    #[serde(default)]
    pub target: String,
    pub id: String,
    pub source: String,
    pub kind: String,
    pub at: u64,
}
#[derive(Default, Serialize, Deserialize)]
struct Crossing {
    count: u8,
    active: bool,
    #[serde(default)]
    last_samples: u64,
}
#[derive(Default, Serialize, Deserialize)]
pub struct Machine {
    #[serde(default)]
    last_seen: u64,
    initialized: bool,
    #[serde(default)]
    epoch: String,
    revision: String,
    states: BTreeMap<String, String>,
    health: String,
    stale_since: Option<u64>,
    connection_alerted: bool,
    serial: u64,
    rules: BTreeMap<String, Crossing>,
}
impl Machine {
    fn event(&mut self, source: &str, entity: &str, kind: &str, now: u64) -> Event {
        self.serial += 1;
        Event {
            target: entity.into(),
            id: format!("{source}:{entity}:{kind}:{}:{now}", self.serial),
            source: source.into(),
            kind: kind.into(),
            at: now,
        }
    }
    pub fn observe(&mut self, source: &str, frame: &Frame, rules: &[Rule], now: u64) -> Vec<Event> {
        let mut events = Vec::new();
        if self.last_seen > 0 && now.saturating_sub(self.last_seen) > 90_000 {
            events.push(self.event(source, "connection", "coverage_gap", now));
        }
        self.last_seen = now;
        let keys: Vec<_> = rules
            .iter()
            .filter_map(|r| serde_json::to_string(r).ok())
            .collect();
        self.rules.retain(|key, _| keys.contains(key));
        let healthy = ["healthy", "artifact"].contains(&frame.health.as_str());
        if !healthy {
            let since = *self.stale_since.get_or_insert(now);
            if !self.connection_alerted && now.saturating_sub(since) >= 30_000 {
                events.push(self.event(source, "connection", "connection_lost", now));
                self.connection_alerted = true;
            }
            if frame.health != "partial" {
                return events;
            }
        }
        if healthy && self.connection_alerted {
            events.push(self.event(source, "connection", "recovered", now));
        }
        if healthy {
            self.stale_since = None;
            self.connection_alerted = false;
        }
        if self.epoch != frame.epoch {
            self.initialized = false;
            self.states.clear();
            self.rules.clear();
            self.epoch = frame.epoch.clone();
        }
        if self.initialized && self.revision != frame.revision {
            for (id, state) in &frame.entities {
                {
                    let previous = self.states.get(id).cloned().unwrap_or_default();
                    let kind = match state.as_str() {
                        "failed" if previous != *state => Some("failed"),
                        "attention" if previous != *state => Some("attention"),
                        "completed"
                            if ["running", "queued", "starting"].contains(&previous.as_str()) =>
                        {
                            Some("completed")
                        }
                        _ => None,
                    };
                    if let Some(kind) = kind {
                        events.push(self.event(source, id, kind, now));
                    }
                }
            }
            for rule in rules.iter().filter(|r| r.validate()) {
                let key = serde_json::to_string(rule).unwrap_or_default();
                let Some(point) = frame.metrics.get(&rule.metric) else {
                    continue;
                };
                if !point.value.is_finite() || point.samples < rule.min_samples {
                    continue;
                }
                let crossing = self.rules.entry(key).or_default();
                if point.samples <= crossing.last_samples {
                    continue;
                }
                crossing.last_samples = point.samples;
                let beyond = if rule.above {
                    point.value > rule.value
                } else {
                    point.value < rule.value
                };
                let recovered = if rule.above {
                    point.value <= rule.value - rule.margin
                } else {
                    point.value >= rule.value + rule.margin
                };
                if !crossing.active {
                    crossing.count = if beyond {
                        crossing.count.saturating_add(1)
                    } else {
                        0
                    };
                    if crossing.count >= rule.consecutive {
                        crossing.active = true;
                        events.push(self.event(source, &rule.metric, "threshold", now));
                    }
                } else if recovered {
                    crossing.active = false;
                    crossing.count = 0;
                    events.push(self.event(source, &rule.metric, "threshold_recovered", now));
                }
            }
        }
        self.initialized = true;
        self.revision = frame.revision.clone();
        if frame.health == "partial" {
            self.states.extend(frame.entities.clone());
            if self.states.len() > 4096 {
                self.states
                    .retain(|key, _| frame.entities.contains_key(key));
            }
        } else {
            self.states = frame.entities.clone();
        }
        self.health = frame.health.clone();
        events
    }
}
