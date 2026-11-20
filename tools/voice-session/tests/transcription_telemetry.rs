use miilo_session_telemetry::Host;
use miilo_voice_session::adapters::transcription::Request;
use std::{
    fs,
    io::{Read, Write},
    net::TcpListener,
    os::unix::fs::PermissionsExt,
    process::Command,
    thread,
    time::{Duration, Instant},
};

#[test]
fn transcription_exports_metadata_without_audio_or_transcript() {
    if let Some(directory) = std::env::var_os("MIILO_TRANSCRIPTION_FIXTURE") {
        let directory = std::path::PathBuf::from(directory);
        let host = Host::load(&directory.join("telemetry.json"))
            .unwrap()
            .unwrap();
        let mut request = Request::start_traced(&[0; 1600], 7, Some(host.clone())).unwrap();
        let deadline = Instant::now() + Duration::from_secs(5);
        let transcript = loop {
            if let Some(text) = request.poll().unwrap() {
                break text;
            }
            assert!(Instant::now() < deadline, "transcription must finish");
            thread::sleep(Duration::from_millis(20));
        };
        assert_eq!(transcript, "private synthetic question");
        assert!(
            request.trace_parent.as_ref().is_some_and(|parent| {
                miilo_session_telemetry::carrier::parse(parent).is_some()
            })
        );
        drop(request);
        host.shutdown();
        return;
    }
    let directory = tempfile::tempdir().unwrap();
    let script = directory.path().join("superwhisper");
    fs::write(
        &script,
        r#"#!/bin/sh
case "$1" in
transcribe)
    test -s "$2" || exit 2
    touch "$MIILO_TRANSCRIPTION_FIXTURE/submitted"
    printf '%s\n' '{"session_id":42}'
    ;;
status)
    if test -f "$MIILO_TRANSCRIPTION_FIXTURE/submitted"; then
        printf '%s\n' '{"ready":true,"phase":"idle","session_id":42,"last":{"session_id":42,"text":"private synthetic question"}}'
    else
        printf '%s\n' '{"ready":true,"phase":"idle"}'
    fi
    ;;
*) exit 2 ;;
esac
"#,
    )
    .unwrap();
    fs::set_permissions(&script, fs::Permissions::from_mode(0o700)).unwrap();
    let receiver = TcpListener::bind("127.0.0.1:0").unwrap();
    receiver.set_nonblocking(true).unwrap();
    let endpoint = format!("http://{}/v1/traces", receiver.local_addr().unwrap());
    let configuration = directory.path().join("telemetry.json");
    fs::write(
        &configuration,
        serde_json::to_vec(
            &serde_json::json!({"enabled":true,"endpoint":endpoint,"tokenFile":null}),
        )
        .unwrap(),
    )
    .unwrap();
    fs::set_permissions(configuration, fs::Permissions::from_mode(0o600)).unwrap();
    let collector = thread::spawn(move || {
        let deadline = Instant::now() + Duration::from_secs(10);
        let mut socket = loop {
            match receiver.accept() {
                Ok((socket, _)) => break socket,
                Err(error) if error.kind() == std::io::ErrorKind::WouldBlock => {
                    assert!(Instant::now() < deadline, "expected an actual OTLP request");
                    thread::sleep(Duration::from_millis(10));
                }
                Err(error) => panic!("{error}"),
            }
        };
        socket
            .set_read_timeout(Some(Duration::from_secs(2)))
            .unwrap();
        let mut header = Vec::new();
        while !header.ends_with(b"\r\n\r\n") {
            let mut byte = [0];
            socket.read_exact(&mut byte).unwrap();
            header.push(byte[0]);
            assert!(header.len() < 8192);
        }
        let header = String::from_utf8(header).unwrap();
        let length: usize = header
            .lines()
            .find_map(|line| {
                let (key, value) = line.split_once(':')?;
                key.eq_ignore_ascii_case("content-length")
                    .then(|| value.trim().parse().unwrap())
            })
            .unwrap();
        assert!(length < 65536);
        let mut body = vec![0; length];
        socket.read_exact(&mut body).unwrap();
        socket
            .write_all(b"HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
            .unwrap();
        body
    });
    let mut paths = vec![directory.path().to_path_buf()];
    paths.extend(std::env::split_paths(
        &std::env::var_os("PATH").unwrap_or_default(),
    ));
    let output = Command::new(std::env::current_exe().unwrap())
        .args([
            "--exact",
            "transcription_exports_metadata_without_audio_or_transcript",
        ])
        .env("MIILO_TRANSCRIPTION_FIXTURE", directory.path())
        .env("PATH", std::env::join_paths(paths).unwrap())
        .output()
        .unwrap();
    assert!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stderr)
    );
    let body = collector.join().unwrap();
    let body = String::from_utf8_lossy(&body);
    assert!(body.contains("execute_tool transcribe"));
    assert!(!body.contains("private synthetic question"));
    assert!(!body.contains(&endpoint));
    assert!(!body.contains(".wav"));
}
