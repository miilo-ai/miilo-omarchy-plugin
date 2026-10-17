# Marketplace registration

Reviewed 2026-10-16. Authoritative references:
- [Development guide](https://plugins.omarchy.org/develop.html)
- [Publishing guide](https://plugins.omarchy.org/publish.html)
- [Shell reference](https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md)
- [Submission form](https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml)

The marketplace needs a public repository, valid root manifest, README, license
and safe installation/removal. Submission goes through its GitHub issue form and
maintainer review. A listing is not a security certification.

## Release gates

- [x] Independent repository and root manifest for `io.miilo.bar`.
- [x] Entry-point files, source provenance and licenses included.
- [x] Portable source checks and GitHub Actions defined.
- [ ] Omarchy agent runs native validation, QML lint and interaction tests.
- [ ] Attach sanitized screenshots from the real shell, not a mock preview.
- [ ] Verify qualified helper/CLI artifacts are accessible with exact install steps.
- [ ] Owner makes the intended repositories public after qualification.
- [ ] Tag a tested revision and write its release notes.
- [ ] Owner authorizes submission of the repository URL, category and tags.
- [ ] Maintainer approves the listing; record the actual marketplace URL.

Do not claim registration until approval. No marketplace submission, visibility
change, GitHub release, AUR registration or package publication was performed.
If an optional credential is missing, skip publication and say:
**No release has been made**. Private source validation needs no publishing token.

The repo's one supported marketplace entry is the bar widget. Its dashboard is
nested behind that entry, not a separate declared panel. Additional shell entry
points require an intentional manifest/lifecycle design and new acceptance tests.
