# PSNativeCmdDevKit Wiki

PSNativeCmdDevKit provides PowerShell helpers for invoking native commands,
processing their output, and applying configurable sudo preferences.

## Command reference

The documentation build generates wiki pages for the module's public commands:

- `Add-SudoPreferenceRule`
- `Get-PropertyHashFromListOutput`
- `Get-SudoPreference`
- `Get-SudoPreferenceRule`
- `Invoke-NativeCommand`
- `Remove-SudoPreferenceRule`

## Security model

Native executable paths and arguments remain separate values. Trusted or signed
module code must not compile caller-controlled strings into PowerShell
scriptblocks, because doing so can create a FullLanguage execution path in a
WDAC-enforced host.

Caller-provided sudo filters must be scriptblocks created by the caller or the
literal `*` wildcard. The module retains and invokes those scriptblocks without
recompiling their text, preserving their original language mode.

## Development

The repository uses Sampler for dependency restoration, module builds, tests,
documentation generation, packaging, and deployment. Hand-authored wiki pages
belong in `source/WikiSource`; generated command pages and `_Sidebar.md` are
created under `output/WikiContent`.
