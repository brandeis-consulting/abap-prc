# Changelog

All notable changes to ABAP-PRC are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **While the major version is 0, minor releases may contain breaking changes.**
> Read the `Breaking changes` section of every version between your current one and
> the target before upgrading.

## [Unreleased]

### Breaking changes

### Added

### Changed

### Fixed

### Removed

## [0.1.0] - 2026-09-20

First public beta release.

### Added
- Process definition and execution runtime
- Monitoring of running and completed processes, down to step and message level per object.
- Retry: automatic retry job for lock and race-condition errors, manual resume on the
  failed step after the root cause has been fixed.
- Installation via abapGit.

### Known limitations

- The public API is not stable. Expect breaking changes in `0.2.0`.
- No migration path between 0.x versions.
  
<!-- Comparison links. -->
[Unreleased]: https://github.com/brandeis-consulting/abap-prc/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/brandeis-consulting/abap-prc/releases/tag/v0.1.0
