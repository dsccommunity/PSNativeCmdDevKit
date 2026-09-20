# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- GitVersion yaml configuration.
- Copilot repository guidance, targeted WDAC language-mode review rules, and a
  validation skill.
- Sampler WikiSource generation, packaging, and GitHub wiki deployment.
- Unit coverage for native command invocation, output parsing, sudo rule
  lifecycle, and constrained-language behavior.

### Security

- Removed dynamic PowerShell source generation from `Invoke-NativeCommand`.
- Stopped recompiling sudo preference filter strings and require filters to be
  script blocks or the `*` wildcard.

### Fixed

- Updated the Sampler bootstrap and pinned `Sampler` to
  `0.121.0-preview0001`.
- Replaced retired Azure Pipelines images and artifact tasks with supported
  hosted images and pipeline artifacts.
- Corrected sudo preference output so `Invoke-NativeCommand` receives `Sudo`
  and `SudoAs`.
- Corrected replacement of the first sudo rule and removal of multiple matches.
- Prevented continuation lines for discarded properties from accessing a
  missing extra-properties collection.

### Changed

- Migrated the test configuration to Pester 5-style settings with an 80 percent
  coverage target and a Windows PowerShell/PowerShell 7 cross-platform matrix.
- Updated contributor and user documentation for the Sampler workflow and WDAC
  trust boundary.

## [v0.1.0] - 2020-07-12

### Added
- `Invoke-NativeCommand` helper, supporting sudo preference & error handling.
- Commands to manage sudo preferences.
- `Get-PropertyHashFromListOutput` to parse `Key: value` from STDOUT int a hashtable.
- Adding readme details.

### Changed
- Updated azure pipeline config to add hqrmtest.
