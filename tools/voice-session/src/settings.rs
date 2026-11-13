use crate::domain::Config;
use std::{fs, io::Write, path::PathBuf};
pub fn settings(config: Config, save: bool) -> Result<Config, String> {
    let base = std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            PathBuf::from(std::env::var_os("HOME").unwrap_or_default()).join(".config")
        });
    let directory = base.join("miilo");
    let path = directory.join("voice.json");
    if save {
        config.validate()?;
        fs::create_dir_all(&directory).map_err(|_| "Cannot create voice settings.")?;
        let mut file = tempfile::NamedTempFile::new_in(directory).map_err(|e| e.to_string())?;
        write!(
            file,
            "{}",
            serde_json::json!({"wake_phrase":config.phrase(),"silence_ms":config.silence_ms})
        )
        .map_err(|e| e.to_string())?;
        file.persist(path).map_err(|e| e.to_string())?;
        Ok(config)
    } else {
        match fs::read(&path) {
            Ok(bytes) if bytes.len() <= 4096 => {
                let saved: Config =
                    serde_json::from_slice(&bytes).map_err(|_| "Invalid saved voice settings.")?;
                saved.validate()?;
                Ok(saved)
            }
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(config),
            _ => Err("Cannot read voice settings.".into()),
        }
    }
}
