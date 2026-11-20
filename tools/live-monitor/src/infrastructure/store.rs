use crate::domain::{Event, Frame, Machine, Rule};
use fs2::FileExt;
use serde::{Deserialize, Serialize, de::DeserializeOwned};
use std::{
    fs,
    io::Read,
    path::{Path, PathBuf},
};

#[derive(Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Source {
    pub id: String,
    pub kind: String,
    pub program: PathBuf,
    pub config: Option<PathBuf>,
    #[serde(default)]
    pub job: Option<String>,
    #[serde(default)]
    pub output: Option<PathBuf>,
    #[serde(default)]
    pub rules: Vec<Rule>,
}
#[derive(Serialize, Deserialize)]
pub struct Config {
    #[serde(default = "full_motion")]
    pub motion: String,
    #[serde(default)]
    pub enabled: bool,
    #[serde(default)]
    pub completions: bool,
    #[serde(default)]
    pub quiet: bool,
    #[serde(default)]
    pub sources: Vec<Source>,
}
fn full_motion() -> String {
    "full".into()
}
impl Default for Config {
    fn default() -> Self {
        Self {
            motion: full_motion(),
            enabled: false,
            completions: false,
            quiet: false,
            sources: Vec::new(),
        }
    }
}
#[derive(Default, Serialize, Deserialize)]
pub struct Poll {
    pub failures: u8,
    pub next: u64,
}
#[derive(Default, Serialize, Deserialize)]
pub struct State {
    #[serde(default)]
    pub polls: std::collections::BTreeMap<String, Poll>,
    #[serde(default)]
    pub machines: std::collections::BTreeMap<String, Machine>,
    #[serde(default)]
    pub frames: std::collections::BTreeMap<String, Frame>,
    #[serde(default)]
    pub events: Vec<Event>,
    #[serde(default)]
    pub attempted: Vec<String>,
    #[serde(default)]
    pub delivery_error: bool,
    #[serde(default)]
    pub pending: Vec<Event>,
    #[serde(default)]
    pub last_delivery: u64,
    #[serde(default)]
    pub updated_at: u64,
}
pub fn directory(root: &Path) -> Result<(), String> {
    if !root.is_absolute() {
        return Err("state directory must be absolute".into());
    }
    fs::create_dir_all(root).map_err(|_| "cannot create state directory")?;
    if fs::symlink_metadata(root)
        .map_err(|_| "cannot inspect state directory")?
        .file_type()
        .is_symlink()
    {
        return Err("state directory must not be a symlink".into());
    }
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(root, fs::Permissions::from_mode(0o700))
            .map_err(|_| "cannot restrict state directory")?;
    }
    Ok(())
}
pub fn load<T: DeserializeOwned + Default>(path: &Path) -> Result<T, String> {
    if !path.exists() {
        return Ok(T::default());
    }
    let meta = fs::symlink_metadata(path).map_err(|_| "cannot inspect state")?;
    if !meta.is_file() || meta.len() > 4 * 1024 * 1024 {
        return Err("invalid state file".into());
    }
    let mut data = Vec::new();
    fs::File::open(path)
        .map_err(|_| "cannot read state")?
        .take(4 * 1024 * 1024 + 1)
        .read_to_end(&mut data)
        .map_err(|_| "cannot read state")?;
    if data.len() > 4 * 1024 * 1024 {
        return Err("state exceeds byte limit".into());
    }
    serde_json::from_slice(&data).map_err(|_| "invalid state JSON".into())
}
pub fn save<T: Serialize>(path: &Path, value: &T) -> Result<(), String> {
    let root = path.parent().ok_or("invalid state path")?;
    directory(root)?;
    if fs::symlink_metadata(path).is_ok_and(|m| m.file_type().is_symlink()) {
        return Err("state file must not be a symlink".into());
    }
    let data = serde_json::to_vec(value).map_err(|_| "cannot encode state")?;
    if data.len() > 4 * 1024 * 1024 {
        return Err("state exceeds byte limit".into());
    }
    let mut temporary = tempfile::NamedTempFile::new_in(root).map_err(|_| "cannot stage state")?;
    use std::io::Write;
    temporary
        .write_all(&data)
        .map_err(|_| "cannot write state")?;
    temporary
        .as_file()
        .sync_all()
        .map_err(|_| "cannot sync state")?;
    temporary.persist(path).map_err(|_| "cannot commit state")?;
    Ok(())
}
pub fn lock(root: &Path, name: &str) -> Result<fs::File, String> {
    directory(root)?;
    let path = root.join(name);
    if fs::symlink_metadata(&path).is_ok_and(|m| m.file_type().is_symlink()) {
        return Err("lock must not be a symlink".into());
    }
    let file = fs::OpenOptions::new()
        .create(true)
        .truncate(false)
        .read(true)
        .write(true)
        .open(path)
        .map_err(|_| "cannot open lock")?;
    file.try_lock_exclusive().map_err(|_| "monitor is busy")?;
    Ok(file)
}
impl Source {
    pub fn validate(&self) -> bool {
        !self.id.is_empty()
            && self.id.len() <= 80
            && self
                .id
                .bytes()
                .all(|c| c.is_ascii_alphanumeric() || c == b'-')
            && ["one", "bench", "local-job", "ray-job"].contains(&self.kind.as_str())
            && self.program.is_absolute()
            && self.program.is_file()
            && (self.kind == "one" || self.config.as_ref().is_some_and(|p| p.is_absolute()))
            && (self.kind != "ray-job"
                || (self.job.as_ref().is_some_and(|id| {
                    !id.is_empty()
                        && id.len() <= 128
                        && id
                            .bytes()
                            .all(|c| c.is_ascii_alphanumeric() || c == b'-' || c == b'_')
                }) && self.output.as_ref().is_some_and(|p| p.is_absolute())))
            && self.rules.len() <= 16
            && self.rules.iter().all(Rule::validate)
    }
}
