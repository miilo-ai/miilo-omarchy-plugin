import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import test from 'node:test';

const api = vm.createContext({});
vm.runInContext(readFileSync(new URL('../ui/components/chat/StreamState.js', import.meta.url), 'utf8'), api);
function turn(id = 'one') {
  const state = api.create();
  api.begin(state, id, 'What needs attention?');
  return state;
}
function emit(state, type, fields = {}, sequence = state.sequence, id = state.requestId) {
  return api.receive(state, id, JSON.stringify({protocolVersion: '0.1', requestId: id, sequence, type, ...fields}));
}
function context(state) { emit(state, 'context', {status: 'partial', omitted: 2, references: [{workKey:'w', revisionKey:'r', title:'Review'}]}); }
function complete(state, text = 'Review the evidence.') {
  context(state);
  emit(state, 'text_delta', {text});
  emit(state, 'done');
}

test('renders deltas immediately with separate context and commits only completed history', () => {
  const s = turn(); context(s);
  emit(s, 'text_delta', {text:'Review '});
  assert.equal(s.answer, 'Review ');
  assert.equal(s.history.length, 0);
  assert.equal(s.context.status, 'partial');
  assert.equal(s.context.omitted, 2);
  emit(s, 'text_delta', {text:'the evidence.'}); emit(s, 'done');
  assert.equal(s.phase, 'done');
  assert.equal(s.history[1].text, s.answer);
});

test('cancel invalidates output before process termination; old malformed output and exits cannot poison retry', () => {
  const s = turn(); context(s); emit(s, 'text_delta', {text:'Partial'});
  api.cancel(s);
  assert.equal(s.phase, 'incomplete'); assert.equal(s.history.length, 0);
  api.begin(s, 'two', 'Retry');
  assert.equal(api.receive(s, 'one', 'not JSON'), false);
  api.exited(s, 'one');
  assert.equal(s.phase, 'streaming'); complete(s);
  assert.equal(s.phase, 'done');
});

test('target revision changes clear history; selected target is copied into the request', () => {
  const s = turn(); complete(s);
  const focus = {workKey:'w', revisionKey:'r'};
  assert.equal(api.select(s, focus), true);
  const request = api.begin(s, 'two', 'Explain'); focus.revisionKey = 'mutated';
  assert.equal(request.focus.revisionKey, 'r');
  assert.equal(request.history.length, 0);
  api.select(s, {workKey:'w', revisionKey:'new'});
  assert.equal(s.phase, 'idle'); assert.equal(s.answer, '');
  api.exited(s, 'two'); assert.equal(s.phase, 'idle');
});

test('errors, missing terminal events, duplicates and gaps leave partial text incomplete', () => {
  for (const finish of [
    s => emit(s, 'error', {code:'unavailable', message:'private remote body'}),
    s => api.exited(s, 'one'),
    s => emit(s, 'done', {}, 1),
    s => emit(s, 'done', {}, 9),
    s => api.receive(s, 'one', '{}'),
  ]) {
    const s = turn(); context(s); emit(s, 'text_delta', {text:'Partial'}); finish(s);
    // An unrelated envelope is ignored; process EOF must still fail the turn.
    api.exited(s, 'one');
    assert.equal(s.phase, 'incomplete'); assert.equal(s.answer, 'Partial');
    assert.equal(s.history.length, 0); assert.ok(!s.error.includes('private'));
  }
});

test('bounds input/output and history without silently truncating evidence', () => {
  const s = api.create();
  assert.throws(() => api.begin(s, 'id', 'x'.repeat(4001)));
  for (let n = 0; n < 6; n++) { api.begin(s, String(n), 'Question'); complete(s); }
  assert.equal(s.history.length, 8);
  api.begin(s, 'long', 'Question'); complete(s, 'x'.repeat(4001));
  assert.equal(s.answer.length, 4001); assert.equal(s.history.length, 0);
  api.begin(s, 'huge', 'Question'); context(s);
  emit(s, 'text_delta', {text:'x'.repeat(64001)});
  assert.equal(s.phase, 'incomplete'); assert.equal(s.answer, '');
});

test('rejects malformed context, unknown events, text before context and empty success', () => {
  for (const run of [
    s => emit(s, 'context', {status:'ok', omitted:-1, references:[]}),
    s => emit(s, 'tool_call', {}),
    s => emit(s, 'text_delta', {text:'Ungrounded'}),
    s => { context(s); emit(s, 'done'); },
    s => api.receive(s, 'one', 'null'),
    s => api.receive(s, 'one', '{'),
  ]) { const s = turn(); run(s); assert.equal(s.phase, 'incomplete'); }
});
