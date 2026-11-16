use super::speech_config;
use std::{
    io::{Read, Seek, Write},
    process::{Command, Stdio},
    time::Duration,
};

fn state(phase: &str) {
    println!("{}", serde_json::json!({"type":"state","phase":phase}));
    let _ = std::io::stdout().flush();
}
pub fn command(args: &[String]) -> Result<bool, String> {
    match args.first().map(String::as_str) {
        Some("playback-status") => {
            println!(
                "{}",
                serde_json::json!({"ready":speech_config::load().is_ok()})
            );
        }
        Some("configure-playback") => {
            let value = read_input(8192)?;
            speech_config::save(
                serde_json::from_slice(&value).map_err(|_| "Invalid speech settings.")?,
            )?;
            println!("{{\"ready\":true}}");
        }
        Some("speak") => {
            #[derive(serde::Deserialize)]
            #[serde(deny_unknown_fields)]
            struct Input {
                text: String,
            }
            let input: Input = serde_json::from_slice(&read_input(100_000)?)
                .map_err(|_| "Invalid spoken reply.")?;
            speak(&input.text)?;
        }
        _ => return Ok(false),
    }
    Ok(true)
}
fn read_input(limit: u64) -> Result<Vec<u8>, String> {
    let mut bytes = Vec::new();
    std::io::stdin()
        .lock()
        .take(limit + 1)
        .read_to_end(&mut bytes)
        .map_err(|_| "Cannot read speech request.")?;
    if bytes.len() as u64 > limit {
        return Err("Speech request exceeds its limit.".into());
    }
    Ok(bytes)
}
pub fn speak(text: &str) -> Result<(), String> {
    if text.trim().is_empty() || text.chars().count() > 16000 {
        return Err("Spoken reply is empty or too long; read the text reply.".into());
    }
    let settings = speech_config::load()?;
    state("preparing_playback");
    let client = reqwest::blocking::Client::builder()
        .no_proxy()
        .redirect(reqwest::redirect::Policy::none())
        .timeout(Duration::from_secs(45))
        .connect_timeout(Duration::from_secs(5))
        .build()
        .map_err(|_| "Speech transport unavailable.")?;
    let mut request=client.post(format!("{}/audio/speech",settings.base_url.trim_end_matches('/')))
        .json(&serde_json::json!({"model":settings.model,"voice":settings.voice,"input":crate::domain::spoken_reply(text),"response_format":"wav"}));
    if let Some(token) = settings.token()? {
        request = request.bearer_auth(token);
    }
    let response = request
        .send()
        .map_err(|_| "Speech endpoint unavailable; reply remains as text.")?;
    if !response.status().is_success() {
        return Err("Speech endpoint rejected playback; reply remains as text.".into());
    }
    let mut bytes = Vec::new();
    response
        .take(16_000_001)
        .read_to_end(&mut bytes)
        .map_err(|_| "Speech download interrupted.")?;
    if bytes.len() > 16_000_000 {
        return Err("Speech response is too large.".into());
    }
    validate_wav(&bytes)?;
    let mut file = tempfile::tempfile().map_err(|_| "Cannot prepare speech playback.")?;
    file.write_all(&bytes)
        .map_err(|_| "Cannot prepare speech playback.")?;
    file.rewind()
        .map_err(|_| "Cannot prepare speech playback.")?;
    let mut command = Command::new("pw-play");
    command
        .arg("-")
        .stdin(Stdio::from(file))
        .stdout(Stdio::null())
        .stderr(Stdio::null());
    #[cfg(target_os = "linux")]
    {
        use std::os::unix::process::CommandExt;
        unsafe {
            command.pre_exec(|| {
                if libc::prctl(libc::PR_SET_PDEATHSIG, libc::SIGKILL) < 0 || libc::getppid() == 1 {
                    return Err(std::io::Error::last_os_error());
                }
                Ok(())
            });
        }
    }
    let mut child = command
        .spawn()
        .map_err(|_| "Cannot start PipeWire playback.")?;
    state("speaking");
    let deadline = std::time::Instant::now() + Duration::from_secs(125);
    loop {
        if let Some(status) = child.try_wait().map_err(|_| "Cannot check playback.")? {
            if !status.success() {
                return Err("Speech playback was interrupted.".into());
            }
            break;
        }
        if std::time::Instant::now() > deadline {
            let _ = child.kill();
            let _ = child.wait();
            return Err("Speech playback timed out.".into());
        }
        std::thread::sleep(Duration::from_millis(20));
    }
    state("done");
    Ok(())
}
pub fn validate_wav(bytes: &[u8]) -> Result<(), String> {
    let reader = hound::WavReader::new(std::io::Cursor::new(bytes))
        .map_err(|_| "Speech endpoint returned invalid WAV audio.")?;
    let spec = reader.spec();
    if !(1..=2).contains(&spec.channels)
        || !(8000..=96000).contains(&spec.sample_rate)
        || reader.duration() == 0
        || reader.duration() as u64 > spec.sample_rate as u64 * 120
    {
        return Err("Unsupported speech audio.".into());
    }
    Ok(())
}
