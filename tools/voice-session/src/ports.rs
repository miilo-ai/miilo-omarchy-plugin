use crate::domain::FRAME;
pub trait WakeDetector {
    fn feed(&mut self, samples: &[i16]) -> Result<Option<usize>, String>;
    fn reset(&mut self);
}
pub trait ActivityDetector {
    fn speech(&mut self, samples: &[i16; FRAME]) -> Result<bool, String>;
}
