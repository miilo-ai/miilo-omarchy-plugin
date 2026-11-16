use serde::{Deserialize, Serialize};
use std::{io::Write, path::PathBuf};

#[derive(Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Settings {
    pub base_url: String,
    pub model: String,
    pub voice: String,
    pub api_key_file: Option<PathBuf>,
}
pub fn path() -> PathBuf {
    std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            PathBuf::from(std::env::var_os("HOME").unwrap_or_default()).join(".config")
        })
        .join("miilo/playback.json")
}
impl Settings {
    pub fn validate(&self) -> Result<(), String> {
        let url = url::Url::parse(&self.base_url).map_err(|_| "Invalid speech URL.")?;
        if !matches!(url.scheme(), "https" | "http")
            || url.host_str().is_none()
            || (url.scheme() == "http"
                && !matches!(url.host_str(), Some("127.0.0.1" | "localhost" | "[::1]")))
            || !url.username().is_empty()
            || url.password().is_some()
            || url.query().is_some()
            || url.fragment().is_some()
            || !url.path().trim_end_matches('/').ends_with("/v1")
            || [&self.model, &self.voice].iter().any(|value| {
                value.trim().is_empty() || value.len() > 200 || value.chars().any(char::is_control)
            })
            || self
                .api_key_file
                .as_ref()
                .is_some_and(|path| !path.is_absolute())
        {
            return Err(
                "Use an HTTPS /v1 speech endpoint (HTTP only on loopback), model and voice.".into(),
            );
        }
        self.token()?;
        Ok(())
    }
    pub fn token(&self) -> Result<Option<String>, String> {
        let Some(path) = &self.api_key_file else {
            return Ok(None);
        };
        let bytes = miilo_session_telemetry::config::private_bytes(path)
            .map_err(|_| "Cannot read private speech credential.")?;
        let value = String::from_utf8(bytes).map_err(|_| "Invalid speech credential.")?;
        let token = value.trim();
        if token.is_empty() || token.len() > 4096 || !token.bytes().all(|b| (33..=126).contains(&b))
        {
            return Err("Invalid speech credential.".into());
        }
        Ok(Some(token.into()))
    }
}
pub fn load() -> Result<Settings, String> {
    let bytes = miilo_session_telemetry::config::private_bytes(&path())
        .map_err(|_| "Configure speech playback first.")?;
    let value: Settings = serde_json::from_slice(&bytes).map_err(|_| "Invalid speech settings.")?;
    value.validate()?;
    Ok(value)
}
pub fn save(value: Settings) -> Result<(), String> {
    value.validate()?;
    let path = path();
    let directory = path.parent().ok_or("Invalid speech settings path.")?;
    std::fs::create_dir_all(directory).map_err(|_| "Cannot create speech settings directory.")?;
    let mut file =
        tempfile::NamedTempFile::new_in(directory).map_err(|_| "Cannot save speech settings.")?;
    file.write_all(&serde_json::to_vec(&value).map_err(|_| "Invalid speech settings.")?)
        .map_err(|_| "Cannot save speech settings.")?;
    file.persist(path)
        .map_err(|_| "Cannot save speech settings.")?;
    Ok(())
}
