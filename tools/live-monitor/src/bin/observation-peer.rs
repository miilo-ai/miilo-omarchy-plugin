fn main() {
    let invocation = std::env::args().next().unwrap_or_default();
    let name = std::path::Path::new(&invocation)
        .file_name()
        .and_then(|s| s.to_str())
        .unwrap_or("");
    if ["notify-send", "gtk-launch"].contains(&name) {
        let path =
            std::env::var("MIILO_TEST_NOTIFICATION_RECORD").expect("inert notification record");
        let args = std::env::args().skip(1).collect::<Vec<_>>();
        std::fs::write(format!("{path}-{name}"), serde_json::to_vec(&args).unwrap()).unwrap();
        if name == "notify-send" {
            println!("default");
        }
        return;
    }
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.first().is_some_and(|s| s == "--notification-probe") {
        use miilo_live_monitor::{
            application::NotificationPort, domain::Event, infrastructure::desktop::Desktop,
        };
        let root = std::path::PathBuf::from(&args[1]);
        Desktop {
            app: "Miilo Bench".into(),
            root: root.clone(),
        }
        .deliver(&[Event {
            id: "event".into(),
            source: "selected-source".into(),
            target: "private-work-identity".into(),
            kind: "failed".into(),
            at: 1,
        }])
        .unwrap();
        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        while !root.join("open.json").exists() {
            assert!(std::time::Instant::now() < deadline);
            std::thread::sleep(std::time::Duration::from_millis(20));
        }
        std::thread::sleep(std::time::Duration::from_millis(200));
        return;
    }
    if args.first().is_some_and(|s| s == "--oversize") {
        use std::io::Write;
        let _ = std::io::stdout().write_all(&vec![b'x'; 1_100_000]);
        return;
    }
    let path = args
        .windows(2)
        .find(|a| a[0] == "--config")
        .expect("fixture path")[1]
        .clone();
    println!("{}", std::fs::read_to_string(path).expect("fixture"));
}
