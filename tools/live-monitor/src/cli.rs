use clap::{Parser, Subcommand};
use std::path::PathBuf;
#[derive(Parser)]
#[command(version)]
pub struct Cli {
    #[arg(long)]
    pub root: PathBuf,
    #[arg(long, default_value = "Miilo Bench")]
    pub app: String,
    #[command(subcommand)]
    pub action: Action,
}
#[derive(Subcommand)]
pub enum Action {
    Status,
    Focus {
        #[arg(long, action=clap::ArgAction::Set)]
        active: bool,
    },
    Enable {
        #[arg(long, action=clap::ArgAction::Set)]
        enabled: bool,
    },
    Preferences {
        #[arg(long)]
        motion: Option<String>,
        #[arg(long, action=clap::ArgAction::Set)]
        completions: bool,
        #[arg(long, action=clap::ArgAction::Set)]
        quiet: bool,
    },
    Add {
        #[arg(long)]
        kind: String,
        #[arg(long)]
        program: PathBuf,
        #[arg(long)]
        config: Option<PathBuf>,
        #[arg(long)]
        job: Option<String>,
        #[arg(long)]
        output: Option<PathBuf>,
    },
    Remove {
        id: String,
    },
    Rule {
        id: String,
    },
    Ack,
    AckOpen,
    Tick {
        #[arg(long)]
        dry_run: bool,
    },
    Run,
}
