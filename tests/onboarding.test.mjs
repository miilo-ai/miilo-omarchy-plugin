import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import test from 'node:test';
import assert from 'node:assert/strict';

// Execute the authored controller's JavaScript functions, not a rewritten model.
// Native QML bindings, focus and processes are qualified separately on Omarchy.
const source = readFileSync(new URL('../ui/components/onboarding/OnboardingController.qml', import.meta.url), 'utf8');
function controller() {
  const calls = [];
  const context = vm.createContext({
    grouped: [], collapsed: {}, rows: [], selected: [], groups: [], sessions: [],
    pendingGroups: null, draft: {}, project: '/tmp', error: '', mode: '', busy: false,
    groupsDirty: false, groupsLoaded: false, fingerprint: '', reply: {}, editIndex: -1,
    commands: { importing: false, regroup: () => calls.push('groups'), discover: () => calls.push('discover'), dismiss: () => calls.push('dismiss'), enroll: () => calls.push('import') },
  });
  for (const match of source.matchAll(/\bfunction\s+\w+\([^)]*\)\s*\{/g)) {
    let compiled;
    for (let end = match.index + match[0].length; end < source.length; end++) {
      if (source[end] !== '}') continue;
      try { compiled = new vm.Script(source.slice(match.index, end + 1)); } catch { continue; }
      break;
    }
    assert.ok(compiled, 'controller function must parse as JavaScript');
    compiled.runInContext(context);
  }
  return { state: context, calls };
}

test('new group never opts into future enrollment and edit uses a separate draft', () => {
  const { state } = controller();
  state.editGroup(-1);
  assert.equal(state.draft.future, false);
  assert.equal(state.mode, 'group');
  state.groups = [{ name: 'Work', folder: '/tmp', pattern: '*', kind: 'all', future: true }];
  state.editGroup(0);
  state.draft.name = 'Unsaved';
  assert.equal(state.groups[0].name, 'Work');
  state.editGroup(-1);
  assert.equal(state.draft.future, false);
  assert.equal(state.draft.name, '');
});

test('group selection excludes unsupported sessions and toggles back', () => {
  const { state } = controller();
  state.grouped = [{ name: 'Agents', sessions: [{ kind: 'codex', id: 'one', observable: true }, { kind: 'other', id: 'two', observable: false }] }];
  state.rebuildRows();
  assert.equal(state.rows.length, 3);
  state.activateRow(0);
  assert.deepEqual(Array.from(state.selected), ['codex:one']);
  state.activateRow(2);
  assert.deepEqual(Array.from(state.selected), ['codex:one']);
  state.collapseGroup(0, true);
  assert.equal(state.rows.length, 1);
  state.activateRow(0);
  assert.equal(state.selected.length, 0);
});

test('empty selection cannot import; selected import clears old reply', () => {
  const { state, calls } = controller();
  state.importSelected();
  assert.equal(calls.length, 0);
  state.selected = ['codex:one'];
  state.reply = { status: 'connected' };
  state.importSelected();
  assert.equal(state.mode, 'importing');
  assert.equal(state.reply.status, undefined);
  assert.deepEqual(calls, ['import']);
});

test('saving group only requests preview; cancellation clears unsaved state', () => {
  const { state, calls } = controller();
  state.editGroup(-1);
  state.saveGroup({ name: 'Work', folder: '/tmp', kind: 'all', future: false });
  assert.equal(state.groups.length, 0);
  assert.equal(state.pendingGroups.length, 1);
  assert.deepEqual(calls, ['groups']);
  state.fingerprint = 'detected'; state.groupsDirty = true;
  state.dismiss();
  assert.equal(state.mode, '');
  assert.equal(state.groupsDirty, false);
  assert.deepEqual(calls, ['groups', 'dismiss']);
});
