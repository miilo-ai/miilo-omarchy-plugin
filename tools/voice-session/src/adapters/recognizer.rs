use crate::{domain::RATE, ports::WakeDetector};
use libloading::Library;
use std::{
    ffi::{CStr, CString, c_char, c_int, c_void},
    path::Path,
    ptr::NonNull,
};
type NewModel = unsafe extern "C" fn(*const c_char) -> *mut c_void;
type Free = unsafe extern "C" fn(*mut c_void);
type Find = unsafe extern "C" fn(*mut c_void, *const c_char) -> c_int;
type NewRecognizer = unsafe extern "C" fn(*mut c_void, f32, *const c_char) -> *mut c_void;
type Feed = unsafe extern "C" fn(*mut c_void, *const i16, c_int) -> c_int;
type ResultText = unsafe extern "C" fn(*mut c_void) -> *const c_char;
type Words = unsafe extern "C" fn(*mut c_void, c_int);
struct Api {
    _library: Library,
    free_model: Free,
    free_recognizer: Free,
    feed: Feed,
    partial: ResultText,
    result: ResultText,
    reset: Free,
}
pub struct Recognizer {
    api: Api,
    model: NonNull<c_void>,
    recognizer: NonNull<c_void>,
    phrase: String,
    samples: usize,
    origin: usize,
    pub trace: bool,
}
impl Recognizer {
    pub fn load(library: &Path, model_path: &Path, phrase: &str) -> Result<Self, String> {
        // Only the explicitly provisioned local runtime is loaded; no search-path fallback.
        unsafe {
            let library = Library::new(library)
                .map_err(|_| "Install the local wake-word runtime first.".to_string())?;
            let new_model: NewModel = *library
                .get(b"vosk_model_new\0")
                .map_err(|e| e.to_string())?;
            let free_model: Free = *library
                .get(b"vosk_model_free\0")
                .map_err(|e| e.to_string())?;
            let find: Find = *library
                .get(b"vosk_model_find_word\0")
                .map_err(|e| e.to_string())?;
            let new: NewRecognizer = *library
                .get(b"vosk_recognizer_new_grm\0")
                .map_err(|e| e.to_string())?;
            let words: Words = *library
                .get(b"vosk_recognizer_set_partial_words\0")
                .map_err(|e| e.to_string())?;
            let final_words: Words = *library
                .get(b"vosk_recognizer_set_words\0")
                .map_err(|e| e.to_string())?;
            let quiet: unsafe extern "C" fn(c_int) = *library
                .get(b"vosk_set_log_level\0")
                .map_err(|e| e.to_string())?;
            let api = Api {
                free_model,
                free_recognizer: *library
                    .get(b"vosk_recognizer_free\0")
                    .map_err(|e| e.to_string())?,
                feed: *library
                    .get(b"vosk_recognizer_accept_waveform_s\0")
                    .map_err(|e| e.to_string())?,
                partial: *library
                    .get(b"vosk_recognizer_partial_result\0")
                    .map_err(|e| e.to_string())?,
                result: *library
                    .get(b"vosk_recognizer_result\0")
                    .map_err(|e| e.to_string())?,
                reset: *library
                    .get(b"vosk_recognizer_reset\0")
                    .map_err(|e| e.to_string())?,
                _library: library,
            };
            quiet(-1);
            let path = CString::new(model_path.as_os_str().as_encoded_bytes())
                .map_err(|_| "Invalid model path.")?;
            let model = NonNull::new(new_model(path.as_ptr()))
                .ok_or("Cannot load the local wake-word model.")?;
            for word in phrase.split_whitespace() {
                let cword = CString::new(word).map_err(|_| "Invalid wake word.")?;
                if find(model.as_ptr(), cword.as_ptr()) < 0 {
                    free_model(model.as_ptr());
                    return Err(format!(
                        "The local model does not recognize '{word}'. Choose another wake phrase."
                    ));
                }
            }
            let grammar = CString::new(serde_json::json!([phrase, "[unk]"]).to_string())
                .map_err(|e| e.to_string())?;
            let Some(recognizer) = NonNull::new(new(model.as_ptr(), RATE as f32, grammar.as_ptr()))
            else {
                free_model(model.as_ptr());
                return Err("Cannot prepare wake detection.".into());
            };
            words(recognizer.as_ptr(), 1);
            final_words(recognizer.as_ptr(), 1);
            Ok(Self {
                api,
                model,
                recognizer,
                phrase: phrase.to_string(),
                samples: 0,
                origin: 0,
                trace: false,
            })
        }
    }
    fn hit(&self, text: &str) -> Result<Option<usize>, String> {
        let value: serde_json::Value =
            serde_json::from_str(text).map_err(|_| "Invalid local recognition result.")?;
        if self.trace {
            eprintln!("{value}");
        }
        let heard = value["partial"]
            .as_str()
            .or_else(|| value["text"].as_str())
            .unwrap_or("");
        if heard != self.phrase && !heard.starts_with(&(self.phrase.clone() + " ")) {
            return Ok(None);
        }
        let end = value["partial_result"]
            .as_array()
            .or_else(|| value["result"].as_array())
            .and_then(|words| words.get(self.phrase.split_whitespace().count() - 1))
            .and_then(|w| w["end"].as_f64());
        Ok(end
            .filter(|end| end.is_finite() && *end > 0.0)
            .map(|end| (end * RATE as f64) as usize))
    }
}
impl WakeDetector for Recognizer {
    fn feed(&mut self, samples: &[i16]) -> Result<Option<usize>, String> {
        // Vosk borrows samples only for this call; returned text is copied before another call.
        self.samples += samples.len();
        unsafe {
            let status = (self.api.feed)(
                self.recognizer.as_ptr(),
                samples.as_ptr(),
                samples.len() as c_int,
            );
            if status < 0 {
                return Err("Wake detection failed.".into());
            }
            let ptr = if status == 1 {
                (self.api.result)(self.recognizer.as_ptr())
            } else {
                (self.api.partial)(self.recognizer.as_ptr())
            };
            if ptr.is_null() {
                return Err("Wake detection returned no result.".into());
            }
            let result = self
                .hit(&CStr::from_ptr(ptr).to_string_lossy())
                .map(|hit| hit.map(|end| end + self.origin));
            if status == 1 && result.as_ref().is_ok_and(Option::is_none) {
                (self.api.reset)(self.recognizer.as_ptr());
                self.origin = self.samples;
            }
            result
        }
    }
    fn reset(&mut self) {
        unsafe {
            (self.api.reset)(self.recognizer.as_ptr());
        }
        self.samples = 0;
        self.origin = 0;
    }
}
impl Drop for Recognizer {
    fn drop(&mut self) {
        // Recognizer references the model and both must be freed before unloading the library.
        unsafe {
            (self.api.free_recognizer)(self.recognizer.as_ptr());
            (self.api.free_model)(self.model.as_ptr());
        }
    }
}
