use miilo_voice_session::{
    adapters::{
        audio::{Activity, Capture},
        recognizer::Recognizer,
        transcription::Request,
    },
    application::Session,
    domain::{Config, Phase},
};
use serde::Deserialize;
use std::{
    io::{self, BufRead, Read, Write},
    path::PathBuf,
    sync::mpsc,
    time::{Duration, Instant},
};

#[derive(Deserialize)]
#[serde(tag = "type", rename_all = "snake_case", deny_unknown_fields)]
enum Control {
    Heartbeat { paused: bool },
    Mute,
    Unmute,
    Stop,
}
fn emit(value: serde_json::Value) {
    println!("{value}");
    let _ = io::stdout().flush();
}
fn main() {
    if let Err(error) = run() {
        emit(serde_json::json!({"type":"error","message":error}));
        std::process::exit(1);
    }
}
fn run() -> Result<(), String> {
    let args: Vec<_> = std::env::args().skip(1).collect();
    if args.first().is_some_and(|s| s == "--version") {
        println!("miilo-voice-session 0.1.0");
        return Ok(());
    }
    let option = |name: &str| {
        args.windows(2)
            .find(|pair| pair[0] == name)
            .map(|pair| pair[1].clone())
    };
    let config = Config {
        wake_phrase: option("--phrase").unwrap_or("hey miilo".into()),
        silence_ms: option("--silence-ms")
            .unwrap_or("1000".into())
            .parse()
            .map_err(|_| "Invalid silence delay.")?,
    };
    config.validate()?;
    if args.first().is_some_and(|s| s == "settings") {
        let saved = miilo_voice_session::settings::settings(config, option("--phrase").is_some())?;
        emit(
            serde_json::json!({"type":"settings","wake_phrase":saved.phrase(),"silence_ms":saved.silence_ms}),
        );
        return Ok(());
    }

    let data = std::env::var_os("XDG_DATA_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            PathBuf::from(std::env::var_os("HOME").unwrap_or_default()).join(".local/share")
        });
    let base = data.join("miilo/voice");
    let library = option("--library")
        .map(PathBuf::from)
        .unwrap_or_else(|| base.join("libvosk.so"));
    let model = option("--model")
        .map(PathBuf::from)
        .unwrap_or_else(|| base.join("vosk-model-small-en-us-0.15"));
    let mut recognizer = Recognizer::load(&library, &model, &config.detector_phrase())?;
    if args.first().is_some_and(|s| s == "check") {
        emit(serde_json::json!({"type":"ready"}));
        return Ok(());
    }
    if args.first().is_some_and(|s| s == "replay") {
        recognizer.trace = args.iter().any(|s| s == "--trace");
        return miilo_voice_session::adapters::replay::replay(
            recognizer,
            config,
            option("--wav").ok_or("Supply a synthetic WAV file.")?,
            args.iter().any(|s| s == "--transcribe"),
        );
    }
    if args.first().is_none_or(|s| s != "run") {
        return Err("Use check, run or replay.".into());
    }
    let (tx, rx) = mpsc::sync_channel(16);
    std::thread::spawn(move || {
        let stdin = io::stdin();
        let mut input = stdin.lock();
        loop {
            let mut line = String::new();
            match (&mut input).take(8193).read_line(&mut line) {
                Ok(0) | Err(_) => break,
                Ok(_) if line.len() > 8192 => break,
                _ => {
                    if tx.send(serde_json::from_str::<Control>(&line)).is_err() {
                        return;
                    }
                }
            }
        }
        let _ = tx.send(Ok(Control::Stop));
    });
    let mut session = Session::new(recognizer, Activity::default(), config)?;
    let mut capture = None;
    let mut request: Option<Request> = None;
    let mut heartbeat = Instant::now();
    let mut active = false;
    let mut last_phase = None;
    emit(serde_json::json!({"type":"ready"}));
    loop {
        while let Ok(command) = rx.try_recv() {
            match command.map_err(|_| "Invalid voice-session control.")? {
                Control::Heartbeat { paused } => {
                    heartbeat = Instant::now();
                    session.pause(paused);
                    if !active {
                        active = true;
                        session.unmute();
                    }
                }
                Control::Mute => session.mute(),
                Control::Unmute => {
                    if active {
                        session.unmute();
                    }
                }
                Control::Stop => return Ok(()),
            }
        }
        if heartbeat.elapsed() > Duration::from_millis(1500) {
            return Err("Voice session paused because its safety heartbeat stopped.".into());
        }
        if session.gate.muted || session.gate.paused {
            capture = None;
            request = None;
        } else if session.phase == Phase::Transcribing {
            capture = None;
            if let Some(job) = &mut request
                && let Some(text) = job.poll()?
            {
                if session.gate.accepts(job.generation) {
                    emit(serde_json::json!({"type":"transcript","text":text}));
                }
                request = None;
                session.completed();
            }
        } else if active {
            if capture.is_none() {
                capture = Some(Capture::start()?);
            }
            if let Some(input) = &mut capture {
                for frame in input.read()? {
                    if let Some(audio) = session.feed(&frame)? {
                        request = Some(Request::start(&audio, session.gate.generation)?);
                        break;
                    }
                }
            }
        }
        if last_phase != Some(session.phase) {
            emit(serde_json::json!({"type":"state","phase":session.phase}));
            last_phase = Some(session.phase);
        }
        std::thread::sleep(Duration::from_millis(15));
    }
}
