# Selected-session visibility

Selected transcript sessions remain visible for twelve hours inclusive after
last observed activity. Idle sessions appear as resting robots. Pending decisions
and active work remain visible; persistent remote providers retain their existing
behavior. The collector supplies `dev.miilo.session.recentlyActive`; the UI does
not calculate recency or invent execution state. Expiration follows snapshot
refresh rather than an exact wall-clock alarm. Transcript history is retained.

Codex uses source timestamps. Timestamp-free Cursor bootstrap uses transcript
file modification time; subsequent activity uses receipt time. Enrollment and
collector restart do not establish fresh activity. Missing, malformed and future
timestamps do not establish recency.

## Controls and navigation

The systems menu begins collapsed and closes when the native surface reactivates.
An All control appears while a system filter is selected and clears that filter.
The former inactive-session toggle and its persisted preference are removed.

Compact presents the robot fleet; Detail includes task rows. The stored view
values remain `quiet` and `orbit` for configuration compatibility. Both use the
same observed state and selected systems. Compact has a maximum of four columns
and creates additional rows as space permits.

Selecting a robot or an animated system tile opens that system's task list.
Selecting a task opens its details, notes, evidence, file changes and advertised
actions. Inspection records its entry mode separately from saved appearance
preferences. Back restores that entry mode, including after nested task details.
Navigation never issues provider actions.

## Updating the installed desktop

Update the collector and native UI together when changing visibility policy:

```sh
bash tools/dev-relaunch.sh --rebuild
systemctl --user restart miilo-local-desktop.service
```

Restart an existing manually launched collector instead of starting a second
collector against the same configuration. A UI-only update uses
`bash tools/dev-relaunch.sh` without rebuilding or restarting the collector.
The shared OWL asset does not replace the native plugin lifecycle or installer.

## Validation

Rust reader and application tests cover activity timestamps, idle retention and
invalid timestamps. Generated-renderer tests cover system isolation, zero/one/many
tasks, saved preferences, inspection origin and nested Back navigation. Native
asset regression checks cover matching behavior and source provenance. Offscreen
Qt pointer tests establish that task-row activation does not also activate its
parent tile. These checks do not establish installed Omarchy shell acceptance.

On the installed host, verify:

- Systems menu stays collapsed until selected, including after reopening.
- Recently active selected sessions become sleeping robots when idle.
- Expired idle sessions disappear after a fresh snapshot; observed new activity
  restores visibility. Pending decisions remain available.
- All clears a selected system filter; no inactive-session toggle appears.
- Compact and Detail preserve appearance settings and restore their inspection
  origin through task details and Back.
- Updating preserves existing connections, selected sessions and transcripts.

Use explicitly selected disposable sessions for validation. Discovery does not
launch agent tasks, enroll unchecked sessions or prune history. Record host
versions, installed binary hashes and observed results separately from portable
source checks.
