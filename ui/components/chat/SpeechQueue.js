// Ordered, bounded sentence delivery. Incomplete text stays local until a boundary.
function create() { return { pending: "", queue: [], total: 0, closed: false }; }
function append(state, delta, final) {
    if (state.closed) throw Error("Speech turn is closed");
    if (typeof delta !== "string" || state.total + delta.length > 16000)
        throw Error("Speech turn exceeds its limit");
    state.total += delta.length;
    state.pending += delta;
    var boundary;
    // Wait for whitespace after punctuation, including across provider deltas.
    while ((boundary = /[.!?]["”')\]]*\s+|\n+/.exec(state.pending))) {
        var end = boundary.index + boundary[0].length;
        push(state, state.pending.slice(0, end));
        state.pending = state.pending.slice(end);
    }
    // Long unpunctuated answers cannot delay speech indefinitely.
    while (state.pending.length > 240) {
        var end = state.pending.lastIndexOf(" ", 240);
        if (end < 80) throw Error("Speech phrase exceeds its limit");
        push(state, state.pending.slice(0, end));
        state.pending = state.pending.slice(end + 1);
    }
    if (final) { push(state, state.pending); state.pending = ""; state.closed = true; }
}
function push(state, text) {
    if (!text.trim()) return;
    if (state.queue.length >= 64) throw Error("Speech queue exceeds its limit");
    state.queue.push(text.trim());
}
