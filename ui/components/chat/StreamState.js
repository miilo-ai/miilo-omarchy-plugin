// Session-only presentation state. The host owns process start/termination.
// Plain JavaScript so the same event handling can be exercised without a shell.
function create() {
    return { focus: null, history: [], requestId: '', sequence: 0,
        phase: 'idle', question: '', answer: '', context: null, error: '' };
}

function bounded(value, max) {
    return typeof value === 'string' && value.trim().length > 0
        && Array.from(value).length <= max;
}

function select(state, focus) {
    if (focus !== null && (!focus || !bounded(focus.workKey, 128)
            || !bounded(focus.revisionKey, 128)))
        throw new Error('Invalid chat target');
    if (JSON.stringify(state.focus) === JSON.stringify(focus)) return false;
    Object.assign(state, create());
    state.focus = focus === null ? null
        : { workKey: focus.workKey, revisionKey: focus.revisionKey };
    return true; // Caller must terminate any previously owned process.
}

function begin(state, requestId, text) {
    if (state.phase === 'streaming') throw new Error('Chat is already running');
    if (!bounded(requestId, 80) || !bounded(text, 4000))
        throw new Error('Invalid or oversized chat request');
    var request = { protocolVersion: '0.1', requestId: requestId, text: text,
        history: state.history.map(function (m) { return { role: m.role, text: m.text }; }) };
    if (state.focus) request.focus = Object.assign({}, state.focus);
    Object.assign(state, { requestId: requestId, sequence: 0, phase: 'streaming',
        question: text, answer: '', context: null, error: '' });
    return request;
}

function fail(state, message) {
    state.phase = 'incomplete';
    state.error = message;
    state.requestId = '';
    return false;
}

function cancel(state) {
    if (state.phase === 'streaming') fail(state, 'Response cancelled.');
    // Invalidate before the host terminates the process: queued output is stale.
    state.requestId = '';
}

function receive(state, requestId, line) {
    if (state.phase !== 'streaming' || requestId !== state.requestId) return false;
    if (typeof line !== 'string' || line.length > 262144)
        return fail(state, 'Chat stream exceeded the limit.');
    var event;
    try { event = JSON.parse(line); }
    catch (_) { return fail(state, 'Invalid chat stream.'); }
    if (!event || typeof event !== 'object') return fail(state, 'Invalid chat stream.');
    if (event.requestId !== state.requestId) return false;
    if (event.protocolVersion !== '0.1' || !Number.isSafeInteger(event.sequence)
            || event.sequence !== state.sequence)
        return fail(state, 'Chat stream is out of order.');
    if (event.type === 'context') {
        if (state.context || event.sequence !== 0 || typeof event.status !== 'string'
                || !Number.isSafeInteger(event.omitted) || event.omitted < 0
                || !Array.isArray(event.references) || event.references.length > 256
                || event.references.some(function (r) {
                    return !r || !bounded(r.workKey, 128)
                        || !bounded(r.revisionKey, 128) || !bounded(r.title, 4000);
                })) return fail(state, 'Invalid chat context.');
        state.context = { status: event.status, omitted: event.omitted,
            references: event.references };
    } else if (event.type === 'text_delta') {
        if (!state.context || typeof event.text !== 'string'
                || state.answer.length + event.text.length > 64000)
            return fail(state, 'Invalid or oversized chat answer.');
        state.answer += event.text;
    } else if (event.type === 'done') {
        if (!state.context || !state.answer.trim())
            return fail(state, 'Chat returned no answer.');
        // SDK history messages allow 4,000 characters. Keep full text on screen;
        // omit oversized turns from subsequent requests instead of truncating facts.
        if (Array.from(state.answer).length <= 4000) {
            state.history = state.history.concat([
                { role: 'user', text: state.question },
                { role: 'assistant', text: state.answer }
            ]).slice(-8);
        } else state.history = [];
        state.phase = 'done';
        state.requestId = '';
    } else if (event.type === 'error') {
        // Never surface arbitrary remote/generic failure bodies through this port.
        if (!bounded(event.code, 128) || typeof event.message !== 'string')
            return fail(state, 'Invalid chat error.');
        return fail(state, 'Chat could not complete. Check setup and retry.');
    } else return fail(state, 'Unsupported chat event.');
    state.sequence += 1;
    return true;
}

function exited(state, requestId) {
    if (state.phase === 'streaming' && requestId === state.requestId)
        fail(state, 'Chat ended before completing.');
}
