use super::{audio::Activity, recognizer::Recognizer};
use crate::{application::Session, domain::Config};
fn emit(value: serde_json::Value) {
    println!("{value}");
}
pub fn replay(
    recognizer: Recognizer,
    config: Config,
    wav: String,
    transcribe: bool,
) -> Result<(), String> {
    let mut reader = hound::WavReader::open(wav).map_err(|e| e.to_string())?;
    let spec = reader.spec();
    if spec.channels != 1 || spec.sample_rate != 16000 || spec.bits_per_sample != 16 {
        return Err("Use mono 16 kHz 16-bit PCM.".into());
    }
    if reader.duration() > 16000 * 40 {
        return Err("Fixture exceeds 40 seconds.".into());
    }
    let samples = reader
        .samples::<i16>()
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;
    let mut session = Session::new(recognizer, Activity::default(), config)?;
    session.unmute();
    let mut last_phase = session.phase;
    for frame in samples.as_chunks::<480>().0 {
        let turn = session.feed(frame)?;
        if last_phase != session.phase {
            emit(serde_json::json!({"type":"state","phase":session.phase}));
            last_phase = session.phase;
        }
        if let Some(audio) = turn {
            emit(serde_json::json!({"type":"turn","samples":audio.len()}));
            if transcribe {
                let mut job = super::transcription::Request::start(&audio, 0)?;
                loop {
                    if let Some(text) = job.poll()? {
                        emit(serde_json::json!({"type":"transcript","text":text}));
                        break;
                    }
                    std::thread::sleep(std::time::Duration::from_millis(20));
                }
            }
            return Ok(());
        }
    }
    Err("No completed wake-and-question turn detected.".into())
}
