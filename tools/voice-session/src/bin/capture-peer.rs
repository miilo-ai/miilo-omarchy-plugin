use std::{
    io::{self, Write},
    time::Duration,
};
fn main() -> io::Result<()> {
    let path = std::env::var_os("MIILO_CAPTURE_PEER_PID_FILE")
        .ok_or_else(|| io::Error::other("Supply a fixture PID path."))?;
    std::fs::write(path, std::process::id().to_string())?;
    let mut stdout = io::stdout().lock();
    loop {
        stdout.write_all(&[0; 960])?;
        stdout.flush()?;
        std::thread::sleep(Duration::from_millis(30));
    }
}
