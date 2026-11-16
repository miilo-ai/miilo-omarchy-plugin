// Sentence-level synthesis runs ahead of playback by at most two audio files.
// Files are anonymous and never retain transcript content or credentials.
use super::speech;
use serde::Deserialize;
use std::io::{BufRead, Read};
use std::sync::mpsc::sync_channel;

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Input {
    #[serde(rename = "type")]
    kind: String,
    text: Option<String>,
}
pub fn run() -> Result<(), String> {
    speech::state("preparing_playback");
    let (sender, receiver) = sync_channel(1);
    std::thread::spawn(move || {
        let result = produce(|text| {
            let audio = speech::synthesize(text)?;
            sender
                .send(Ok(audio))
                .map_err(|_| "Playback stopped.".into())
        });
        if let Err(error) = result {
            let _ = sender.send(Err(error));
        }
    });
    for audio in receiver {
        speech::play(audio?)?;
    }
    Ok(())
}
fn produce(mut synthesize: impl FnMut(&str) -> Result<(), String>) -> Result<(), String> {
    read_turn(std::io::stdin().lock(), &mut synthesize)
}
pub fn read_turn(
    mut reader: impl BufRead,
    mut accept: impl FnMut(&str) -> Result<(), String>,
) -> Result<(), String> {
    let mut total = 0;
    let mut count = 0;
    loop {
        let mut line = Vec::new();
        reader
            .by_ref()
            .take(100_001)
            .read_until(b'\n', &mut line)
            .map_err(|_| "Cannot read speech stream.")?;
        if line.is_empty() || line.len() > 100_000 {
            return Err("Speech stream ended without completion or exceeded its limit.".into());
        }
        let input: Input = serde_json::from_slice(&line).map_err(|_| "Invalid speech stream.")?;
        match (input.kind.as_str(), input.text) {
            ("text", Some(text)) => {
                total += text.chars().count();
                count += 1;
                if total > 16000 || count > 128 || text.trim().is_empty() {
                    return Err("Speech stream exceeded its limit.".into());
                }
                accept(&text)?;
            }
            ("done", None) => return Ok(()),
            _ => return Err("Invalid speech stream.".into()),
        }
    }
}
