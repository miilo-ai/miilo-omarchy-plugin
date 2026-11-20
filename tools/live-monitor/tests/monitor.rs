use miilo_live_monitor::infrastructure::{
    service,
    source::bounded,
    store::{self, Config, Source, State},
};
use std::{fs, process::Command};
#[test]
fn readonly_observation_persists_one_incident_across_restart_and_keeps_private_permissions() {
    let root = tempfile::tempdir().unwrap();
    let source_file = root.path().join("fixture.json");
    let frame = |state: &str| serde_json::json!({"epoch":"fixture","revision":"","health":"artifact","entities":{"run":state},"metrics":{}});
    fs::write(&source_file, frame("running").to_string()).unwrap();
    let source = Source {
        id: "fixture".into(),
        kind: "bench".into(),
        program: env!("CARGO_BIN_EXE_observation-peer").into(),
        config: Some(source_file.clone()),
        job: None,
        output: None,
        rules: vec![],
    };
    let config = Config {
        enabled: true,
        quiet: true,
        sources: vec![source],
        ..Config::default()
    };
    store::save(&root.path().join("config.json"), &config).unwrap();
    service::tick(root.path(), "Miilo Bench", true).unwrap();
    fs::write(&source_file, frame("failed").to_string()).unwrap();
    service::tick(root.path(), "Miilo Bench", true).unwrap();
    service::tick(root.path(), "Miilo Bench", true).unwrap();
    let state: State = store::load(&root.path().join("state.json")).unwrap();
    assert_eq!(state.events.len(), 1);
    assert_eq!(state.events[0].kind, "failed");
    assert!(state.pending.is_empty());
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        assert_eq!(
            fs::metadata(root.path().join("state.json"))
                .unwrap()
                .permissions()
                .mode()
                & 0o777,
            0o600
        );
        assert_eq!(
            fs::metadata(root.path()).unwrap().permissions().mode() & 0o777,
            0o700
        );
    }
    assert_eq!(
        fs::read_to_string(source_file).unwrap(),
        frame("failed").to_string()
    );
}
#[test]
fn oversized_process_output_is_rejected() {
    let result = bounded(Command::new(env!("CARGO_BIN_EXE_observation-peer")).arg("--oversize"));
    assert!(result.is_err());
}
#[test]
fn symlinked_state_is_refused_and_unit_name_is_stable() {
    let root = tempfile::tempdir().unwrap();
    let data = root.path().join("state.json");
    #[cfg(unix)]
    {
        std::os::unix::fs::symlink(root.path().join("other"), &data).unwrap();
        assert!(store::save(&data, &serde_json::json!({})).is_err());
    }
    assert_eq!(service::unit(root.path()), service::unit(root.path()));
    assert!(!service::unit(root.path()).contains(root.path().to_str().unwrap()));
}

#[cfg(unix)]
#[test]
fn notification_click_routes_to_selected_source_without_disclosing_content() {
    let fixture = tempfile::tempdir().unwrap();
    let bin = fixture.path().join("bin");
    fs::create_dir(&bin).unwrap();
    for name in ["notify-send", "gtk-launch"] {
        std::os::unix::fs::symlink(env!("CARGO_BIN_EXE_observation-peer"), bin.join(name)).unwrap();
    }
    let root = fixture.path().join("state");
    let record = fixture.path().join("record");
    let status = Command::new(env!("CARGO_BIN_EXE_observation-peer"))
        .arg("--notification-probe")
        .arg(&root)
        .env("PATH", &bin)
        .env("MIILO_TEST_NOTIFICATION_RECORD", &record)
        .status()
        .unwrap();
    assert!(status.success());
    let args: Vec<String> = store::load(&fixture.path().join("record-notify-send")).unwrap();
    assert!(args.contains(&"--action=default=Open".into()));
    assert!(
        !args
            .iter()
            .any(|s| s.contains("private-work-identity") || s.contains("selected-source"))
    );
    let opening: serde_json::Value = store::load(&root.join("open.json")).unwrap();
    assert_eq!(opening["source"], "selected-source");
    assert_eq!(opening["target"], "private-work-identity");
    let launch: Vec<String> = store::load(&fixture.path().join("record-gtk-launch")).unwrap();
    assert_eq!(launch, vec!["miilo-bench"]);
}
