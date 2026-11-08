use serde_json::{Value, json};
use std::io::{self, Read, Write};
use std::{env, fs, process, thread, time::Duration};

fn main() {
    let action = env::args().nth(1).unwrap_or_default();
    if action == "snapshot" || action == "refresh" {
        if action == "refresh" {
            thread::sleep(Duration::from_secs(9));
        }
        println!(
            "{}",
            json!({"status":"ready","configured":true,"errors":[],"snapshot":{"providers":[{"id":"synthetic"}],"actors":[],"workItems":[],"attention":[]}})
        );
        return;
    }
    if action == "chat" {
        let mut input = String::new();
        io::stdin().read_to_string(&mut input).unwrap();
        let request: Value = serde_json::from_str(&input).unwrap();
        for (sequence, event) in [
            json!({"type":"context","status":"complete","omitted":0,"references":[]}),
            json!({"type":"text_delta","text":"Synthetic answer"}),
            json!({"type":"done"}),
        ]
        .into_iter()
        .enumerate()
        {
            if sequence == 2 && request["text"] == "Slow fixture" {
                thread::sleep(Duration::from_secs(2));
            }
            let mut event = event;
            event["sequence"] = json!(sequence);
            event["protocolVersion"] = json!("0.1");
            event["requestId"] = request["requestId"].clone();
            println!("{event}");
            io::stdout().flush().unwrap();
        }
        return;
    }
    let path = env::var("MIILO_DICTATION_TEST_STATE").expect("test state");
    let mut state: Value = serde_json::from_slice(&fs::read(&path).expect("fixture")).unwrap();
    if action.is_empty() {
        if state["unconfigured"] == true {
            process::exit(1);
        }
        println!("superwhisper");
        return;
    }
    if state["hang"] == true {
        thread::sleep(Duration::from_secs(3));
    }
    if state["invalid"] == true {
        println!("not json");
        return;
    }
    if action == "status" {
        println!(
            "{}",
            json!({"ready":state["ready"].as_bool().unwrap_or(true),"phase":state["phase"].as_str().unwrap_or("idle"),"last":{"createdAt":state["last"].as_str().unwrap_or("")}})
        );
        return;
    }
    let mut commands = state["commands"].as_array().cloned().unwrap_or_default();
    commands.push(json!(action));
    state["commands"] = json!(commands);
    if state["fail_action"] == action {
        fs::write(path, serde_json::to_vec(&state).unwrap()).unwrap();
        println!("{{\"error\":\"synthetic command failure\"}}");
        return;
    }
    match action.as_str() {
        "start" => state["phase"] = json!("recording"),
        "stop" => {
            state["phase"] = json!("idle");
            state["last"] = json!("new-fixture");
        }
        "cancel" => state["phase"] = json!("idle"),
        "settings" => (),
        _ => process::exit(2),
    }
    fs::write(path, serde_json::to_vec(&state).unwrap()).unwrap();
    println!("{{}}");
}
