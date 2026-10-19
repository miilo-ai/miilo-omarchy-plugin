# Automatic source releases

Merging a new stable manifest version into main runs source checks, verifies the
required CLI and widget releases exist, creates the matching immutable tag, and
explicitly dispatches the source release workflow. The release workflow checks
again before publishing its archive and checksums. Existing version tags are never
moved. A merge with an already tagged version does not release.

Set the repository variable MIILO_RELEASE_ENABLED=false to pause automatic tagging.
No opt-in variable is required. Configured release-environment approval rules still
apply. Failed checks or unavailable required runtime releases fail the workflow;
merge/release CLI, then widgets, then this plugin. Missing external publication
credentials must not be treated as a successful publication.

A tag created before a release failure can be retried through Source release with
that existing tag and publish=true. Verify the published archive, not only a green
source check. Marketplace submission remains separate.
