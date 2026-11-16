use miilo_voice_session::adapters::speech_stream::read_turn;
use std::io::Cursor;
#[test]
fn only_completed_valid_protocol_delivers_ordered_phrases() {
    let mut phrases = Vec::new();
    read_turn(Cursor::new(b"{\"type\":\"text\",\"text\":\"First.\"}\n{\"type\":\"text\",\"text\":\"Second.\"}\n{\"type\":\"done\"}\n"), |s| {
        phrases.push(s.to_owned()); Ok(())
    }).unwrap();
    assert_eq!(phrases, ["First.", "Second."]);
    for input in [
        "",
        "{\"type\":\"text\",\"text\":\"partial\"}\n",
        "{\"type\":\"text\",\"text\":\"\"}\n",
        "{\"type\":\"done\",\"extra\":true}\n",
    ] {
        assert!(read_turn(Cursor::new(input), |_| Ok(())).is_err());
    }
    let huge = serde_json::json!({"type":"text","text":"x".repeat(16001)}).to_string() + "\n";
    assert!(
        read_turn(Cursor::new(huge), |_| panic!(
            "oversized content must never reach synthesis"
        ))
        .is_err()
    );
    assert!(read_turn(Cursor::new("x".repeat(100001)), |_| Ok(())).is_err());
}
#[test]
fn downstream_failure_stops_reading_following_phrases() {
    let mut count = 0;
    assert!(read_turn(Cursor::new(b"{\"type\":\"text\",\"text\":\"First\"}\n{\"type\":\"text\",\"text\":\"Second\"}\n"), |_| {
        count += 1; Err("Cancelled".into())
    }).is_err());
    assert_eq!(count, 1);
}
