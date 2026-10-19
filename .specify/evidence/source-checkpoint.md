# Source checkpoint

> Historical validation record. Results apply only to the revision and environment recorded below; they do not describe current release readiness.


Prepared on macOS from the source revision in `sources.lock.json`. No Git history
from widgets was copied. Root entry points and local assets are self-contained;
miilo-owl and miilo-local are explicit external dependencies.

Portable validation checks manifest/layout, symlink/path safety, provenance hashes,
single-shell constraints and attributed runtime files. Native Omarchy manifest
validation, qmllint, rendering and interactions remain pending on the test host.
No release has been made. No marketplace registration was submitted.

Executed: `make check` passed manifest/import/hash checks, six package-safety
regressions and native-script syntax validation. `make check-native` stopped
with missing OMARCHY_PATH as expected on macOS; no native success is claimed.

The presentation layout was reorganized and onboarding split into small modules.
Portable checks include authored UI size/import/asset checks and JavaScript
controller behavior. No Qt/Quickshell rendering has been claimed on macOS.
