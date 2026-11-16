use std::{os::unix::fs::PermissionsExt, process::Command};

#[test]
fn hands_free_preference_preserves_phrase_and_delay_without_arming_capture() {
    let directory = tempfile::tempdir().unwrap();
    let run = |args: &[&str]| {
        let output = Command::new(env!("CARGO_BIN_EXE_miilo-voice-session"))
            .args(args)
            .env("XDG_CONFIG_HOME", directory.path())
            .output()
            .unwrap();
        assert!(output.status.success());
        serde_json::from_slice::<serde_json::Value>(&output.stdout).unwrap()
    };
    run(&[
        "settings",
        "--phrase",
        "hey computer",
        "--silence-ms",
        "1500",
    ]);
    let saved = run(&["settings", "--hands-free", "true"]);
    assert_eq!(saved["wake_phrase"], "hey computer");
    assert_eq!(saved["silence_ms"], 1500);
    assert_eq!(saved["hands_free"], true);
    let saved = run(&["settings", "--phrase", "hello computer"]);
    assert_eq!(saved["hands_free"], true);
    assert_eq!(saved["silence_ms"], 1500);
    let file = directory.path().join("miilo/voice.json");
    assert_eq!(
        std::fs::metadata(file).unwrap().permissions().mode() & 0o777,
        0o600
    );
}
