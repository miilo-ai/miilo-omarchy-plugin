use crate::{
    domain::{FRAME, RATE},
    ports::ActivityDetector,
};
use std::{
    io::{self, Read},
    os::fd::AsRawFd,
    process::{Child, ChildStdout, Command, Stdio},
};
use webrtc_vad::{SampleRate, Vad, VadMode};

pub struct Capture {
    child: Child,
    stdout: ChildStdout,
    pending: Vec<u8>,
}
impl Capture {
    pub fn start() -> Result<Self, String> {
        let mut command = Command::new("pw-record");
        command
            .args([
                "--raw",
                "--rate",
                "16000",
                "--channels",
                "1",
                "--format",
                "s16",
                "-",
            ])
            .stdin(Stdio::null())
            .stdout(Stdio::piped())
            .stderr(Stdio::null());
        #[cfg(target_os = "linux")]
        {
            use std::os::unix::process::CommandExt;
            // Only async-signal-safe libc calls run between fork and exec.
            unsafe {
                command.pre_exec(|| {
                    if libc::prctl(libc::PR_SET_PDEATHSIG, libc::SIGKILL) < 0
                        || libc::getppid() == 1
                    {
                        return Err(io::Error::last_os_error());
                    }
                    Ok(())
                });
            }
        }
        let mut child = command
            .spawn()
            .map_err(|_| "Cannot open the PipeWire microphone.".to_string())?;
        let stdout = child.stdout.take().ok_or("No audio stream.")?;
        // The descriptor belongs to this capture and remains alive until Drop.
        if unsafe { libc::fcntl(stdout.as_raw_fd(), libc::F_SETFL, libc::O_NONBLOCK) } < 0 {
            let _ = child.kill();
            let _ = child.wait();
            return Err("Cannot configure the microphone stream.".into());
        }
        Ok(Self {
            child,
            stdout,
            pending: Vec::new(),
        })
    }
    pub fn read(&mut self) -> Result<Vec<[i16; FRAME]>, String> {
        let mut bytes = [0; FRAME * 2 * 8];
        match self.stdout.read(&mut bytes) {
            Ok(0) => return Err("The microphone disconnected.".into()),
            Ok(n) => self.pending.extend_from_slice(&bytes[..n]),
            Err(e) if e.kind() == io::ErrorKind::WouldBlock => {}
            Err(_) => return Err("Cannot read the microphone.".into()),
        }
        let count = self.pending.len() / (FRAME * 2);
        let mut frames = Vec::with_capacity(count);
        for bytes in self.pending[..count * FRAME * 2]
            .as_chunks::<{ FRAME * 2 }>()
            .0
        {
            let mut frame = [0; FRAME];
            for (sample, pair) in frame.iter_mut().zip(bytes.as_chunks::<2>().0) {
                *sample = i16::from_le_bytes([pair[0], pair[1]]);
            }
            frames.push(frame);
        }
        self.pending.drain(..count * FRAME * 2);
        Ok(frames)
    }
}
impl Drop for Capture {
    fn drop(&mut self) {
        let _ = self.child.kill();
        let _ = self.child.wait();
    }
}
pub struct Activity(Vad);
impl Default for Activity {
    fn default() -> Self {
        Self(Vad::new_with_rate_and_mode(
            SampleRate::Rate16kHz,
            VadMode::Aggressive,
        ))
    }
}
impl ActivityDetector for Activity {
    fn speech(&mut self, frame: &[i16; FRAME]) -> Result<bool, String> {
        debug_assert_eq!(RATE, 16000);
        self.0
            .is_voice_segment(frame)
            .map_err(|_| "Invalid voice activity frame.".into())
    }
}
