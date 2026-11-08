use miilo_live_monitor::infrastructure::{service, store};
use std::{
    fs,
    path::Path,
    process::Command,
    time::{Duration, Instant},
};
fn invoke(binary: &Path, root: &Path, args: &[&str]) -> Result<(), String> {
    let status = Command::new(binary)
        .arg("--root")
        .arg(root)
        .args(["--app", "Miilo Bench"])
        .args(args)
        .status()
        .map_err(|_| "cannot start monitor")?;
    if status.success() {
        Ok(())
    } else {
        Err("monitor command failed".into())
    }
}
fn run() -> Result<(), String> {
    let bin = std::env::current_exe().map_err(|_| "missing executable")?;
    let dir = bin.parent().ok_or("missing executable directory")?;
    let monitor = dir.join("miilo-live-monitor");
    let peer = dir.join("observation-peer");
    let fixture = tempfile::tempdir().map_err(|_| "cannot create fixture")?;
    let root = fixture.path().join("monitor");
    let data = fixture.path().join("frame.json");
    let frame = |s: &str| serde_json::json!({"epoch":"synthetic-notification-qualification","revision":"","health":"artifact","entities":{"synthetic-run":s},"metrics":{}});
    fs::write(&data, frame("running").to_string()).map_err(|_| "cannot write fixture")?;
    invoke(
        &monitor,
        &root,
        &[
            "add",
            "--kind",
            "bench",
            "--program",
            peer.to_str().ok_or("invalid peer")?,
            "--config",
            data.to_str().ok_or("invalid fixture")?,
        ],
    )?;
    let result = (|| {
        invoke(&monitor, &root, &["enable", "--enabled", "true"])?;
        let deadline = Instant::now() + Duration::from_secs(30);
        while !root.join("state.json").exists() {
            if Instant::now() > deadline {
                return Err("monitor baseline timeout".into());
            }
            std::thread::sleep(Duration::from_millis(100));
        }
        std::thread::sleep(Duration::from_secs(3));
        fs::write(&data, frame("failed").to_string()).map_err(|_| "cannot update fixture")?;
        while !root.join("delivery.json").exists() {
            if Instant::now() > deadline {
                return Err("native notification delivery timeout".into());
            }
            std::thread::sleep(Duration::from_millis(100));
        }
        let delivery: serde_json::Value = store::load(&root.join("delivery.json"))?;
        let state: store::State = store::load(&root.join("state.json"))?;
        if delivery["failed"] != false
            || state.events.len() != 1
            || state.events[0].kind != "failed"
        {
            return Err("notification receipt or incident mismatch".into());
        }
        println!(
            "PASS: selected synthetic observation → user service → one persisted failure → native desktop notification"
        );
        Ok(())
    })();
    let cleanup = invoke(&monitor, &root, &["enable", "--enabled", "false"]);
    if let Ok(home) = std::env::var("HOME") {
        let _ = fs::remove_file(
            Path::new(&home)
                .join(".config/systemd/user")
                .join(service::unit(&root)),
        );
        let _ = service::ctl(&["daemon-reload"]);
    }
    result.and(cleanup)
}
fn main() {
    if let Err(e) = run() {
        eprintln!("FAIL: {e}");
        std::process::exit(1);
    }
}
