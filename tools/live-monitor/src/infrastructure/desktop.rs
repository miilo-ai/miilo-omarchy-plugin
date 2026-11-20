use super::store;
use crate::{application::NotificationPort, domain::Event};
use std::{
    io::Read,
    path::PathBuf,
    process::{Command, Stdio},
    sync::atomic::{AtomicUsize, Ordering},
    thread,
    time::{Duration, Instant},
};
static WAITERS: AtomicUsize = AtomicUsize::new(0);
pub struct Desktop {
    pub app: String,
    pub root: PathBuf,
}
impl NotificationPort for Desktop {
    fn deliver(&mut self, events: &[Event]) -> Result<(), String> {
        if events.is_empty() {
            return Ok(());
        }
        let urgent = events
            .iter()
            .any(|e| ["failed", "attention"].contains(&e.kind.as_str()));
        let summary = if events.len() > 1 {
            format!("{} updates need a look", events.len())
        } else {
            match events[0].kind.as_str() {
                "failed" => "Work failed",
                "attention" => "Work needs you",
                "completed" => "Work completed",
                "connection_lost" => "Observation unavailable",
                "recovered" => "Observation recovered",
                "coverage_gap" => "Monitoring resumed after a gap",
                "threshold" => "A configured threshold was crossed",
                _ => "A configured threshold recovered",
            }
            .into()
        };
        if WAITERS.load(Ordering::SeqCst) >= 4 {
            return Err("notification action queue is full".into());
        }
        let entry = if self.app == "Miilo One" {
            "miilo-one"
        } else {
            "miilo-bench"
        };
        let mut child = Command::new("notify-send")
            .args([
                "--app-name",
                &self.app,
                "--icon",
                "miilo-face",
                "--urgency",
                if urgent { "normal" } else { "low" },
                "--hint",
                &format!("string:desktop-entry:{entry}"),
                "--action=default=Open",
                "--wait",
                "--expire-time=10000",
                "--",
                &summary,
                "Open Miilo to inspect the current evidence.",
            ])
            .stdin(Stdio::null())
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .spawn()
            .map_err(|_| "notification service unavailable")?;
        WAITERS.fetch_add(1, Ordering::SeqCst);
        let root = self.root.clone();
        let source = events[0].source.clone();
        let target = if ["failed", "completed", "attention"].contains(&events[0].kind.as_str()) {
            events[0].target.clone()
        } else {
            String::new()
        };
        thread::spawn(move || {
            let start = Instant::now();
            let successful = loop {
                match child.try_wait() {
                    Ok(Some(status)) => break status.success(),
                    Err(_) => break false,
                    _ => {}
                }
                if start.elapsed() > Duration::from_secs(120) {
                    let _ = child.kill();
                    let _ = child.wait();
                    break false;
                }
                thread::sleep(Duration::from_millis(100));
            };
            let mut output = String::new();
            if successful && let Some(stdout) = child.stdout.take() {
                let _ = stdout.take(1024).read_to_string(&mut output);
            }
            let _ = store::save(
                &root.join("delivery.json"),
                &serde_json::json!({"failed":!successful}),
            );
            if successful && output.lines().any(|s| s.trim() == "default") {
                let _ = store::save(
                    &root.join("open.json"),
                    &serde_json::json!({"source":source,"target":target}),
                );
                let _ = Command::new("gtk-launch")
                    .arg(entry)
                    .stdin(Stdio::null())
                    .stdout(Stdio::null())
                    .stderr(Stdio::null())
                    .spawn();
            }
            WAITERS.fetch_sub(1, Ordering::SeqCst);
        });
        Ok(())
    }
}
