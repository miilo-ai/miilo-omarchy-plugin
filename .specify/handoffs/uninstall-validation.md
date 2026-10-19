# Native uninstall acceptance handoff

> Retained design record. Unchecked historical milestones are not a current release checklist. See docs/release-status.md for current scope and outstanding validation.


Implementation scope: Omarchy integration removal only. Shared helper/CLI binaries,
private settings, credentials, backups and independent collectors are retained.
No purge or automatic observer-unit deletion is implemented. Do not claim full
device removal from a successful integration removal.

## Prepare

1. Use a disposable Omarchy profile/VM and the feature branch under review.
   Preserve the real work host. Record exact source revision and shell version.
2. Run `make check` and `make check-native`. Source tests use a fake manager;
   they do not establish native shell unload/removal behavior.
3. Install through `omarchy plugin add` from the reviewed branch, or the existing
   native development installer. The latter now includes uninstall.sh.
4. Configure synthetic observations and a second unrelated bar widget. Use no
   real provider mutation, credentials, project transcripts or production service.
5. Record plugin list, shell process count and the selected helper/request PIDs.
   Add a separate collector fixture only when testing shared-resource retention.

## Execute on the disposable host

- Run `bash uninstall.sh` from the installed checkout: preview only; no UI/service
  change. Confirm the retained-resource warning and expected plugin ID.
- Open the dashboard, then run `bash uninstall.sh --confirm` in a separate terminal.
  The wrapper disables first, uses the manager's removal, and verifies inventory.
- Verify dashboard/bar disappearance and owned transient requests exit. Reopen or
  restart the shell and confirm no retry/reappearance. Other widgets must survive.
- Git installs should be removed. Hand-copied installs may be backed up by Omarchy;
  record that intentional leftover and do not call it a data purge.
- An independent collector/helper/settings must survive UI-only removal. Confirm
  that the warning accurately describes any remaining background observation.
- Reinstall and confirm retained connection/display settings are restored.
- Copy uninstall.sh to a disposable path before removal if testing a second run;
  it should report already absent without changing other registrations.
- Before clean Git removal, add a synthetic unpublished commit and ignored file.
  Confirm the printed private `checkout.tar` survives removal; extract into a new
  disposable directory and verify both the commit and file contents. Backup
  directories must be mode 0700 and archives 0600. A failed archive write or a
  state path resolving inside the checkout must stop before disable/remove.
- With inventory absent but an install directory or dangling link still present,
  verify removal reports incomplete state instead of successful absence.
- Edit an installed Git checkout and confirm removal refuses until edits are
  preserved. The wrapper must not discard local modifications.
- Check a manager failure, unavailable shell inventory and failed disable: report
  incomplete removal, never silently delete files or print unconditional success.

## Recovery and separate removals

If uninstall.sh is already gone, the supported manager path remains:
`omarchy plugin remove io.miilo.bar`. Manage shared software through its original
package channel. Stop an owned collector separately only after inspecting its
user unit and deciding that every client using it may lose observation.
Local credential deletion is not upstream revocation.

## Evidence to return

Record commands/exit codes, versions, installation shape, retained file hashes,
process/request counts and sanitized before/after/reinstall captures. No tokens,
private hostnames or transcript data. State whether Git and hand-copied installs
were each exercised. Leave unsupported cases open; Android tests do not qualify
Omarchy lifecycle. Do not submit to the marketplace until this native gate passes.
