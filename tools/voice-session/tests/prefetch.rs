use std::{
    fs,
    io::{Read, Write},
    net::TcpListener,
    os::unix::fs::PermissionsExt,
    process::{Command, Stdio},
    thread,
    time::{Duration, Instant},
};
#[test]
fn second_synthesis_arrives_while_first_audio_is_still_playing() {
    let temp = tempfile::tempdir().unwrap();
    fs::create_dir(temp.path().join("miilo")).unwrap();
    let listener = TcpListener::bind("127.0.0.1:0").unwrap();
    listener.set_nonblocking(true).unwrap();
    let endpoint = format!("http://{}/v1", listener.local_addr().unwrap());
    fs::write(
        temp.path().join("miilo/playback.json"),
        serde_json::json!({"base_url":endpoint,"model":"fixture","voice":"fixture"}).to_string(),
    )
    .unwrap();
    fs::set_permissions(
        temp.path().join("miilo/playback.json"),
        fs::Permissions::from_mode(0o600),
    )
    .unwrap();
    let player = temp.path().join("pw-play");
    fs::write(&player,"#!/bin/sh\ncat > /dev/null\ntouch \"$MIILO_TEST_DIR/playing\"\ni=0\nwhile ! test -f \"$MIILO_TEST_DIR/release\"; do\n i=$((i+1)); test $i -lt 150 || exit 1; sleep 0.02\ndone\n").unwrap();
    fs::set_permissions(&player, fs::Permissions::from_mode(0o700)).unwrap();
    let directory = temp.path().to_path_buf();
    let server = thread::spawn(move || {
        let mut inputs = Vec::new();
        for index in 0..2 {
            let deadline = Instant::now() + Duration::from_secs(5);
            let mut socket = loop {
                match listener.accept() {
                    Ok((socket, _)) => break socket,
                    Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                        assert!(Instant::now() < deadline);
                        thread::sleep(Duration::from_millis(10));
                    }
                    Err(e) => panic!("{e}"),
                }
            };
            socket
                .set_read_timeout(Some(Duration::from_secs(3)))
                .unwrap();
            let mut header = Vec::new();
            while !header.ends_with(b"\r\n\r\n") {
                let mut b = [0];
                socket.read_exact(&mut b).unwrap();
                header.push(b[0]);
                assert!(header.len() < 8192);
            }
            let header = String::from_utf8(header).unwrap();
            let length = header
                .lines()
                .find_map(|l| {
                    let (k, v) = l.split_once(':')?;
                    k.eq_ignore_ascii_case("content-length")
                        .then(|| v.trim().parse::<usize>().unwrap())
                })
                .unwrap();
            assert!(length < 8192);
            let mut body = vec![0; length];
            socket.read_exact(&mut body).unwrap();
            inputs.push(
                serde_json::from_slice::<serde_json::Value>(&body).unwrap()["input"]
                    .as_str()
                    .unwrap()
                    .to_owned(),
            );
            if index == 1 {
                // The player cannot finish until the second synthesis request arrives.
                while !directory.join("playing").exists() {
                    assert!(Instant::now() < deadline);
                    thread::sleep(Duration::from_millis(10));
                }
                fs::write(directory.join("release"), b"ready").unwrap();
            }
            let mut wav = std::io::Cursor::new(Vec::new());
            {
                let mut writer = hound::WavWriter::new(
                    &mut wav,
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
            }
            let bytes = wav.into_inner();
            write!(socket,"HTTP/1.1 200 OK\r\nContent-Type: audio/wav\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",bytes.len()).unwrap();
            socket.write_all(&bytes).unwrap();
        }
        inputs
    });
    let paths = std::iter::once(temp.path().to_path_buf())
        .chain(std::env::split_paths(&std::env::var_os("PATH").unwrap()))
        .collect::<Vec<_>>();
    let mut child = Command::new(env!("CARGO_BIN_EXE_miilo-voice-session"))
        .arg("speak-stream")
        .env("XDG_CONFIG_HOME", temp.path())
        .env("MIILO_TEST_DIR", temp.path())
        .env("PATH", std::env::join_paths(paths).unwrap())
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .unwrap();
    child.stdin.take().unwrap().write_all(b"{\"type\":\"text\",\"text\":\"First.\"}\n{\"type\":\"text\",\"text\":\"Second.\"}\n{\"type\":\"done\"}\n").unwrap();
    let output = child.wait_with_output().unwrap();
    assert!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stdout)
    );
    assert_eq!(server.join().unwrap(), ["First.", "Second."]);
    assert_eq!(
        String::from_utf8(output.stdout)
            .unwrap()
            .matches("\"speaking\"")
            .count(),
        2
    );
}
