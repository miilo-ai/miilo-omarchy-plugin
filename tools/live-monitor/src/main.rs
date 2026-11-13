mod cli;
use clap::Parser;
use cli::{Action, Cli};
use miilo_live_monitor::{
    domain::Rule,
    infrastructure::{
        service,
        source::digest,
        store::{self, Config, Source, State},
    },
};
use std::io::Read;
fn run() -> Result<(), String> {
    let cli = Cli::parse();
    store::directory(&cli.root)?;
    if !["Miilo One", "Miilo Bench"].contains(&cli.app.as_str()) {
        return Err("invalid app".into());
    }
    if matches!(cli.action, Action::Run) {
        let _lock = store::lock(&cli.root, "daemon.lock")?;
        loop {
            service::tick(&cli.root, &cli.app, false)?;
            std::thread::sleep(std::time::Duration::from_secs(2));
        }
    }
    if let Action::Tick { dry_run } = cli.action {
        return service::tick(&cli.root, &cli.app, dry_run);
    }
    if let Action::Focus { active } = cli.action {
        return store::save(
            &cli.root.join("focus.json"),
            &serde_json::json!({"at":if active{service::now()}else{0}}),
        );
    }
    if matches!(cli.action, Action::Ack) {
        let state: State = store::load(&cli.root.join("state.json"))?;
        return store::save(
            &cli.root.join("read.json"),
            &serde_json::json!({"ids":state.events.iter().map(|e|&e.id).collect::<Vec<_>>()}),
        );
    }
    if matches!(cli.action, Action::AckOpen) {
        return store::save(
            &cli.root.join(if matches!(cli.action, Action::Ack) {
                "read.json"
            } else {
                "open.json"
            }),
            &serde_json::json!({"at":service::now()}),
        );
    }
    let _lock = store::lock(&cli.root, "config.lock")?;
    let mut config: Config = store::load(&cli.root.join("config.json"))?;
    match cli.action {
        Action::Status => {
            let state: State = store::load(&cli.root.join("state.json"))?;
            let read: serde_json::Value = store::load(&cli.root.join("read.json"))?;
            let unread = state
                .events
                .iter()
                .filter(|e| {
                    !read["ids"]
                        .as_array()
                        .is_some_and(|ids| ids.iter().any(|id| id == &e.id))
                })
                .count();
            println!(
                "{}",
                serde_json::json!({"config":config,"state":state,"unread":unread})
            );
            return Ok(());
        }
        Action::Enable { enabled } => {
            if enabled && config.sources.is_empty() {
                return Err("select an observation source first".into());
            }
            config.enabled = enabled;
            store::save(&cli.root.join("config.json"), &config)?;
            let result = if enabled {
                service::install(&cli.root, &cli.app)
            } else {
                service::ctl(&["disable", "--now", &service::unit(&cli.root)])
            };
            if enabled && result.is_err() {
                config.enabled = false;
                store::save(&cli.root.join("config.json"), &config)?;
            }
            return result;
        }
        Action::Preferences {
            completions,
            quiet,
            motion,
        } => {
            if let Some(mode) = motion {
                if !["full", "reduced", "off"].contains(&mode.as_str()) {
                    return Err("invalid motion preference".into());
                }
                config.motion = mode;
            }
            config.completions = completions;
            config.quiet = quiet;
        }
        Action::Add {
            kind,
            program,
            config: study,
            job,
            output,
        } => {
            let id = digest(&format!(
                "{kind}:{}:{}:{job:?}:{output:?}",
                program.display(),
                study
                    .as_deref()
                    .unwrap_or(std::path::Path::new(""))
                    .display()
            ));
            if !config.sources.iter().any(|s| s.id == id) {
                if config.sources.len() >= 16 {
                    return Err("monitor at most 16 selected sources".into());
                }
                let source = Source {
                    id,
                    kind,
                    program,
                    config: study,
                    job,
                    output,
                    rules: Vec::new(),
                };
                if !source.validate() {
                    return Err(
                        "invalid source; select an absolute trusted helper and study path".into(),
                    );
                }
                config.sources.push(source);
            }
        }
        Action::Remove { id } => {
            config.sources.retain(|s| s.id != id);
        }
        Action::Rule { id } => {
            let mut input = String::new();
            std::io::stdin()
                .take(65537)
                .read_to_string(&mut input)
                .map_err(|_| "cannot read rules")?;
            if input.len() > 65536 {
                return Err("rules exceed limit".into());
            }
            let rules: Vec<Rule> = serde_json::from_str(&input).map_err(|_| "invalid rules")?;
            if rules.len() > 16 || !rules.iter().all(Rule::validate) {
                return Err("invalid thresholds: require finite values, 2–20 updates and at least 10 samples".into());
            }
            config
                .sources
                .iter_mut()
                .find(|s| s.id == id)
                .ok_or("unknown source")?
                .rules = rules;
        }
        _ => return Err("unsupported command".into()),
    }
    store::save(&cli.root.join("config.json"), &config)?;
    println!("{{\"ok\":true}}");
    Ok(())
}
fn main() {
    if let Err(error) = run() {
        eprintln!("{error}");
        std::process::exit(1);
    }
}
