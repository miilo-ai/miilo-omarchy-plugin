use crate::{application::ObservationPort, domain::Frame, infrastructure::store::Source};
use sha2::{Digest, Sha256};
use std::{
    io::Read,
    process::{Command, Stdio},
    thread,
    time::{Duration, Instant},
};
pub fn digest(value: &str) -> String {
    format!("{:x}", Sha256::digest(value.as_bytes()))
}
pub fn bounded(command: &mut Command) -> Result<Vec<u8>, String> {
    let mut child = command
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|_| "cannot start observer")?;
    let stdout = child.stdout.take().ok_or("missing observer output")?;
    let (send, receive) = std::sync::mpsc::sync_channel(1);
    thread::spawn(move || {
        let mut bytes = Vec::new();
        let result = stdout.take(1048577).read_to_end(&mut bytes).map(|_| bytes);
        let _ = send.send(result);
    });
    let started = Instant::now();
    loop {
        if started.elapsed() > Duration::from_secs(8) {
            let _ = child.kill();
            let _ = child.wait();
            return Err("observer timeout".into());
        }
        if let Some(status) = child.try_wait().map_err(|_| "cannot inspect observer")? {
            let bytes = receive
                .recv_timeout(Duration::from_secs(1))
                .map_err(|_| "observer output timeout")?
                .map_err(|_| "cannot read observer")?;
            if !status.success() || bytes.len() > 1048576 {
                return Err("observer failed or exceeded limit".into());
            }
            return Ok(bytes);
        }
        thread::sleep(Duration::from_millis(20));
    }
}
impl ObservationPort for Source {
    fn read(&mut self) -> Result<Frame, String> {
        if !self.validate() {
            return Err("invalid observer source".into());
        }
        let mut command = Command::new(&self.program);
        if self.kind == "one" {
            command.arg("snapshot");
        } else if self.kind == "local-job" {
            command
                .arg("job-status")
                .arg(self.config.as_ref().ok_or("missing job directory")?);
        } else if self.kind == "ray-job" {
            command
                .arg("--config")
                .arg(self.config.as_ref().ok_or("missing compute config")?)
                .arg("ray-sync")
                .arg(self.job.as_ref().ok_or("missing job identity")?)
                .arg("--output")
                .arg(
                    self.output
                        .as_ref()
                        .ok_or("missing observation directory")?,
                );
        } else {
            command
                .arg("--config")
                .arg(self.config.as_ref().ok_or("missing study")?)
                .arg("live-status");
        }
        let value: serde_json::Value =
            serde_json::from_slice(&bounded(&mut command)?).map_err(|_| "invalid observer JSON")?;
        let mut frame = if self.kind == "bench" {
            serde_json::from_value(value).map_err(|_| "invalid live status")?
        } else if self.kind.ends_with("job") {
            Frame {
                health: "healthy".into(),
                entities: std::collections::BTreeMap::from([(
                    "job".into(),
                    value["status"].as_str().ok_or("missing job state")?.into(),
                )]),
                ..Frame::default()
            }
        } else {
            let mut frame = Frame {
                health: if value["status"] == "failed" {
                    "unavailable"
                } else if value["status"] == "partial" {
                    "partial"
                } else {
                    "healthy"
                }
                .into(),
                ..Frame::default()
            };
            let work = value["snapshot"]["workItems"]
                .as_array()
                .ok_or("missing snapshot")?;
            if work.len() > 2048 {
                return Err("too many work items".into());
            }
            for item in work {
                let id = item["_key"].as_str().ok_or("missing work identity")?;
                let state = if item["lifecycle"] == "failed" {
                    "failed"
                } else if item["attention"].as_str().is_some_and(|s| s != "none") {
                    "attention"
                } else {
                    match item["lifecycle"].as_str().unwrap_or("unknown") {
                        "active" => "running",
                        "succeeded" | "completed" => "completed",
                        other => other,
                    }
                };
                if id.len() > 1024 {
                    return Err("work identity exceeds limit".into());
                }
                frame.entities.insert(id.into(), state.into());
            }
            frame
        };
        if frame.entities.len() > 2048 || frame.metrics.len() > 256 {
            return Err("live status exceeds limits".into());
        }
        frame.revision = digest(
            &serde_json::to_string(&(&frame.entities, &frame.metrics))
                .map_err(|_| "invalid live frame")?,
        );
        Ok(frame)
    }
}
