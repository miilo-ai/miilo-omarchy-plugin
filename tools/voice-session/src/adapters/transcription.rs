use crate::domain::RATE;
use std::{
    io::{Read, Seek, SeekFrom},
    process::{Child, Command, Stdio},
    time::{Duration, Instant},
};
use tempfile::NamedTempFile;

pub struct Request {
    audio: NamedTempFile,
    output: NamedTempFile,
    child: Option<Child>,
    session: Option<u64>,
    preflight: bool,
    started: Instant,
    next_poll: Instant,
    pub generation: u64,
}
impl Request {
    pub fn start(samples: &[i16], generation: u64) -> Result<Self, String> {
        let audio = tempfile::Builder::new()
            .suffix(".wav")
            .tempfile()
            .map_err(|_| "Cannot prepare temporary voice audio.")?;
        let spec = hound::WavSpec {
            channels: 1,
            sample_rate: RATE as u32,
            bits_per_sample: 16,
            sample_format: hound::SampleFormat::Int,
        };
        let mut writer = hound::WavWriter::new(audio.as_file(), spec).map_err(|e| e.to_string())?;
        for sample in samples {
            writer.write_sample(*sample).map_err(|e| e.to_string())?;
        }
        writer.finalize().map_err(|e| e.to_string())?;
        let output = NamedTempFile::new().map_err(|e| e.to_string())?;
        let child = spawn(&output, &["status"])?;
        Ok(Self {
            audio,
            output,
            child: Some(child),
            session: None,
            preflight: true,
            started: Instant::now(),
            next_poll: Instant::now(),
            generation,
        })
    }
    pub fn poll(&mut self) -> Result<Option<String>, String> {
        if self.started.elapsed() > Duration::from_secs(45) {
            return Err("Transcription timed out. Try again.".into());
        }
        if let Some(child) = &mut self.child {
            let Some(status) = child.try_wait().map_err(|e| e.to_string())? else {
                return Ok(None);
            };
            self.child = None;
            if !status.success() {
                return Err("Superwhisper could not transcribe this turn.".into());
            }
            if self
                .output
                .as_file()
                .metadata()
                .map_err(|e| e.to_string())?
                .len()
                > 65536
            {
                return Err("Speech response is too large.".into());
            }
            self.output
                .as_file_mut()
                .seek(SeekFrom::Start(0))
                .map_err(|e| e.to_string())?;
            let mut text = String::new();
            self.output
                .as_file_mut()
                .read_to_string(&mut text)
                .map_err(|e| e.to_string())?;
            let value: serde_json::Value =
                serde_json::from_str(&text).map_err(|_| "Invalid Superwhisper response.")?;
            if self.preflight {
                if value["phase"] != "idle" || value["ready"] != true {
                    return Err("Superwhisper is already busy. Your turn was not submitted.".into());
                }
                self.preflight = false;
                self.output
                    .as_file_mut()
                    .set_len(0)
                    .map_err(|e| e.to_string())?;
                self.child = Some(spawn(
                    &self.output,
                    &[
                        "transcribe",
                        self.audio.path().to_str().ok_or("Invalid audio path.")?,
                    ],
                )?);
                return Ok(None);
            }
            if let Some(id) = self.session {
                if value["session_id"].as_u64() != Some(id) {
                    return Err("Another dictation session replaced this turn.".into());
                }
                if value["phase"] == "idle" && value["last"]["session_id"].as_u64() == Some(id) {
                    let text = value["last"]["text"]
                        .as_str()
                        .ok_or("No transcript returned.")?
                        .trim();
                    if text.is_empty() || text.len() > 4000 {
                        return Err("No usable transcript returned.".into());
                    }
                    return Ok(Some(text.to_string()));
                }
                if value["phase"] == "error" {
                    return Err("Superwhisper could not finish this turn.".into());
                }
            } else {
                self.session = Some(
                    value["session_id"]
                        .as_u64()
                        .ok_or("No transcription session returned.")?,
                );
            }
            self.next_poll = Instant::now() + Duration::from_millis(150);
        } else if Instant::now() >= self.next_poll {
            self.output
                .as_file_mut()
                .set_len(0)
                .map_err(|e| e.to_string())?;
            self.child = Some(spawn(&self.output, &["status"])?);
        }
        Ok(None)
    }
}
fn spawn(output: &NamedTempFile, args: &[&str]) -> Result<Child, String> {
    Command::new("superwhisper")
        .args(args)
        .stdin(Stdio::null())
        .stdout(output.reopen().map_err(|e| e.to_string())?)
        .stderr(Stdio::null())
        .spawn()
        .map_err(|_| "Cannot reach Superwhisper.".into())
}
impl Drop for Request {
    fn drop(&mut self) {
        if let Some(child) = &mut self.child {
            let _ = child.kill();
            let _ = child.wait();
        }
        let _ = &self.audio;
    }
}
