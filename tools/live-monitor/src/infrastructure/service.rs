use super::{
    desktop::Desktop,
    source::digest,
    store::{self, Config, State},
};
use crate::{
    application::{NotificationPort, sample},
    domain::Event,
};
use std::{
    collections::BTreeMap,
    fs,
    path::Path,
    process::Command,
    time::{SystemTime, UNIX_EPOCH},
};
pub fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as u64
}
pub fn unit(root: &Path) -> String {
    format!(
        "miilo-observer-{}.service",
        &digest(&root.to_string_lossy())[..16]
    )
}
pub fn install(root: &Path, app: &str) -> Result<(), String> {
    if !["Miilo One", "Miilo Bench"].contains(&app) {
        return Err("invalid app".into());
    }
    let executable = std::env::current_exe().map_err(|_| "cannot locate monitor")?;
    let quote = |s: &str| -> Result<String, String> {
        if s.chars().any(char::is_control) {
            return Err("invalid service path".into());
        }
        Ok(format!(
            "\"{}\"",
            s.replace('\\', "\\\\")
                .replace('"', "\\\"")
                .replace('%', "%%")
        ))
    };
    let home = std::env::var("HOME").map_err(|_| "HOME unavailable")?;
    let directory = Path::new(&home).join(".config/systemd/user");
    fs::create_dir_all(&directory).map_err(|_| "cannot create user unit directory")?;
    let text = format!(
        "[Unit]\nDescription={app} selected observation monitor\nAfter=graphical-session.target\nPartOf=graphical-session.target\n[Service]\nType=exec\nExecStart={} --root {} --app {} run\nRestart=on-failure\nRestartSec=5\nUMask=0077\nNoNewPrivileges=yes\n[Install]\nWantedBy=graphical-session.target\n",
        quote(&executable.to_string_lossy())?,
        quote(&root.to_string_lossy())?,
        quote(app)?
    );
    let path = directory.join(unit(root));
    if fs::symlink_metadata(&path).is_ok_and(|m| m.file_type().is_symlink()) {
        return Err("service unit must not be a symlink".into());
    }
    fs::write(path, text).map_err(|_| "cannot write user unit")?;
    ctl(&["daemon-reload"])?;
    ctl(&["enable", &unit(root)])?;
    ctl(&["restart", &unit(root)])
}
pub fn ctl(args: &[&str]) -> Result<(), String> {
    if Command::new("systemctl")
        .arg("--user")
        .args(args)
        .status()
        .map_err(|_| "user service manager unavailable")?
        .success()
    {
        Ok(())
    } else {
        Err("user service command failed".into())
    }
}
pub fn tick(root: &Path, app: &str, dry: bool) -> Result<(), String> {
    let _lock = store::lock(root, "state.lock")?;
    let config: Config = store::load(&root.join("config.json"))?;
    if !config.enabled {
        return Ok(());
    }
    if config.sources.len() > 16 || !config.sources.iter().all(|s| s.validate()) {
        return Err("invalid selected observation sources".into());
    }
    let mut state: State = store::load(&root.join("state.json"))?;
    let stamp = now();
    let sources = config
        .sources
        .iter()
        .map(|s| s.id.clone())
        .collect::<Vec<_>>();
    state.machines.retain(|id, _| sources.contains(id));
    state.frames.retain(|id, _| sources.contains(id));
    state.polls.retain(|id, _| sources.contains(id));
    let mut events = Vec::<Event>::new();
    for mut source in config.sources.clone() {
        store::save(
            &root.join("heartbeat.json"),
            &serde_json::json!({"at":now()}),
        )?;
        let id = source.id.clone();
        let poll = state.polls.entry(id.clone()).or_default();
        if !dry && stamp < poll.next {
            continue;
        }
        let rules = source.rules.clone();
        let (frame, mut changes) = sample(
            &id,
            &mut source,
            state.machines.entry(id.clone()).or_default(),
            &rules,
            stamp,
        );
        let healthy = ["healthy", "artifact"].contains(&frame.health.as_str());
        poll.failures = if healthy {
            0
        } else {
            poll.failures.saturating_add(1).min(4)
        };
        let terminal = source.kind.ends_with("job")
            && frame
                .entities
                .values()
                .all(|s| ["completed", "failed", "cancelled", "succeeded"].contains(&s.as_str()));
        poll.next = stamp
            + if terminal {
                30_000
            } else {
                2_000_u64.saturating_mul(1 << poll.failures).min(30_000)
            };
        state.frames.insert(source.id, frame);
        events.append(&mut changes);
    }
    state.events.extend(events.clone());
    if state.events.len() > 256 {
        state.events.drain(..state.events.len() - 256);
    }
    let stamp = now();
    let focus: BTreeMap<String, u64> = store::load(&root.join("focus.json"))?;
    let focused = focus
        .get("at")
        .is_some_and(|at| stamp >= *at && stamp - *at < 12_000);
    let pending = events
        .into_iter()
        .filter(|e| {
            (!config.quiet && !focused)
                && (config.completions || e.kind != "completed")
                && !state.attempted.contains(&e.id)
        })
        .collect::<Vec<_>>();
    if focused || config.quiet {
        state.pending.clear();
    } else {
        state.pending.extend(pending);
    }
    if state.pending.len() > 32 {
        state.pending.drain(..state.pending.len() - 32);
    }
    let outgoing = if stamp.saturating_sub(state.last_delivery) >= 10_000 {
        std::mem::take(&mut state.pending)
    } else {
        Vec::new()
    };
    if !outgoing.is_empty() {
        state.last_delivery = stamp;
    }
    state
        .attempted
        .extend(outgoing.iter().map(|e| e.id.clone()));
    if state.attempted.len() > 256 {
        state.attempted.drain(..state.attempted.len() - 256);
    }
    state.updated_at = stamp;
    store::save(&root.join("state.json"), &state)?;
    if !dry && !outgoing.is_empty() {
        state.delivery_error = Desktop {
            app: app.into(),
            root: root.into(),
        }
        .deliver(&outgoing)
        .is_err();
        store::save(&root.join("state.json"), &state)?;
    }
    Ok(())
}
