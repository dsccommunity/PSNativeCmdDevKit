---
name: validate-changes
description: Run focused PSNativeCmdDevKit validation first, then widen for source, build, or security changes.
argument-hint: Which files changed and what validation depth is required?
---

# Validate changes

## Mandatory rule

Run every validation command through `./build.ps1`.

```powershell
./build.ps1 -ResolveDependency -Tasks noop
./build.ps1 -Tasks build
./build.ps1 -Tasks test
./build.ps1 -Tasks hqrmtest
```

## Decision flow

1. For one function or test file, run:

```powershell
./build.ps1 -Tasks test -PesterPath 'tests/Unit/<File>.Tests.ps1' -CodeCoverageThreshold 0
```

2. For public source changes, run the focused test and then the default test workflow.
3. For `build.ps1`, `build.yaml`, dependency, or pipeline changes, restore dependencies and run build plus the default test workflow.
4. For command invocation, script-block, signing, or nested-module changes, also run the constrained-language regression tests and inspect the built `.psm1` for dynamic evaluation APIs.
5. Before release, run `./build.ps1 -Tasks hqrmtest`.

## Completion checks

- The selected workflows pass through `build.ps1`.
- Coverage meets the configured threshold.
- The built module contains no caller-controlled dynamic PowerShell compilation.
- Documentation and `CHANGELOG.md` describe user-visible changes.
