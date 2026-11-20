use std::{
    fs,
    io::{Cursor, Read, Write},
    net::TcpListener,
    os::unix::fs::PermissionsExt,
    process::Command,
    thread,
};

fn wav() -> Vec<u8> {
    let mut bytes = Cursor::new(Vec::new());
    let mut writer = hound::WavWriter::new(
        &mut bytes,
        hound::WavSpec {
            channels: 1,
            sample_rate: 22050,
            bits_per_sample: 16,
            sample_format: hound::SampleFormat::Int,
        },
    )
    .unwrap();
    for _ in 0..2205 {
        writer.write_sample(0i16).unwrap();
    }
    writer.finalize().unwrap();
    bytes.into_inner()
}
#[test]
fn actual_speech_request_plays_validated_wav_without_named_audio_files() {
    let temp = tempfile::tempdir().unwrap();
    let config = temp.path().join("miilo");
    fs::create_dir(&config).unwrap();
    let listener = TcpListener::bind("127.0.0.1:0").unwrap();
    listener.set_nonblocking(true).unwrap();
    let endpoint = format!("http://{}/v1", listener.local_addr().unwrap());
    let credential = temp.path().join("key");
    fs::write(&credential, "synthetic-speech-key").unwrap();
    fs::set_permissions(&credential, fs::Permissions::from_mode(0o600)).unwrap();
    let settings = config.join("playback.json");
    fs::write(&settings,serde_json::to_vec(&serde_json::json!({"base_url":endpoint,"model":"speech-fixture","voice":"fixture","api_key_file":credential})).unwrap()).unwrap();
    fs::set_permissions(settings, fs::Permissions::from_mode(0o600)).unwrap();
    let peer = temp.path().join("pw-play");
    fs::write(
        &peer,
        "#!/bin/sh\ntest \"$1\" = - || exit 2\ncat > /dev/null\ntouch \"$MIILO_PLAYED_MARKER\"\n",
    )
    .unwrap();
    fs::set_permissions(&peer, fs::Permissions::from_mode(0o700)).unwrap();
    let server = thread::spawn(move || {
        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(10);
        let mut socket = loop {
            match listener.accept() {
                Ok((s, _)) => break s,
                Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                    assert!(std::time::Instant::now() < deadline);
                    thread::sleep(std::time::Duration::from_millis(10));
                }
                Err(e) => panic!("{e}"),
            }
        };
        socket.set_nonblocking(false).unwrap();
        socket
            .set_read_timeout(Some(std::time::Duration::from_secs(3)))
            .unwrap();
        let mut header = Vec::new();
        while !header.ends_with(b"\r\n\r\n") {
            let mut byte = [0];
            socket.read_exact(&mut byte).unwrap();
            header.push(byte[0]);
            assert!(header.len() < 8192);
        }
        let header = String::from_utf8(header).unwrap();
        assert!(header.starts_with("POST /v1/audio/speech "));
        assert!(
            header
                .to_ascii_lowercase()
                .contains("authorization: bearer synthetic-speech-key")
        );
        let length: usize = header
            .lines()
            .find_map(|l| {
                let (k, v) = l.split_once(':')?;
                k.eq_ignore_ascii_case("content-length")
                    .then(|| v.trim().parse().unwrap())
            })
            .unwrap();
        assert!(length < 100_000);
        let mut body = vec![0; length];
        socket.read_exact(&mut body).unwrap();
        let value: serde_json::Value = serde_json::from_slice(&body).unwrap();
        assert_eq!(value["input"], "A private synthetic reply.");
        assert_eq!(value["response_format"], "wav");
        assert_eq!(value.as_object().unwrap().len(), 4);
        let audio = wav();
        write!(socket,"HTTP/1.1 200 OK\r\nContent-Type: audio/wav\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",audio.len()).unwrap();
        socket.write_all(&audio).unwrap();
    });
    let marker = temp.path().join("played");
    let mut paths = vec![temp.path().to_path_buf()];
    paths.extend(std::env::split_paths(
        &std::env::var_os("PATH").unwrap_or_default(),
    ));
    let mut child = Command::new(env!("CARGO_BIN_EXE_miilo-voice-session"))
        .arg("speak")
        .env("XDG_CONFIG_HOME", temp.path())
        .env("MIILO_PLAYED_MARKER", &marker)
        .env("PATH", std::env::join_paths(paths).unwrap())
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .unwrap();
    child
        .stdin
        .take()
        .unwrap()
        .write_all(b"{\"text\":\"A private synthetic reply.\"}")
        .unwrap();
    let output = child.wait_with_output().unwrap();
    server.join().unwrap();
    assert!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stdout)
    );
    assert!(marker.exists());
    let output = String::from_utf8(output.stdout).unwrap();
    assert!(output.contains("speaking"));
    assert!(!output.contains("private synthetic reply"));
    assert!(!output.contains("synthetic-speech-key"));
    assert!(
        !fs::read_dir(temp.path()).unwrap().any(|p| p
            .unwrap()
            .path()
            .extension()
            .is_some_and(|e| e == "wav"))
    );
}
#[test]
fn rejects_invalid_audio_and_insecure_endpoints() {
    use miilo_voice_session::adapters::{speech::validate_wav, speech_config::Settings};
    assert!(validate_wav(b"not audio").is_err());
    assert!(validate_wav(&wav()).is_ok());
    assert_eq!(
        miilo_voice_session::domain::spoken_reply("Miilo One, miilo!"),
        "Milo One, Milo!"
    );
    assert_eq!(
        miilo_voice_session::domain::spoken_reply("Miilophone"),
        "Miilophone"
    );
    for base_url in [
        "http://example.com/v1",
        "https://name:secret@example.com/v1",
        "https://example.com/v1?key=secret",
    ] {
        assert!(
            Settings {
                base_url: base_url.into(),
                model: "speech".into(),
                voice: "fixture".into(),
                api_key_file: None
            }
            .validate()
            .is_err()
        );
    }
}
