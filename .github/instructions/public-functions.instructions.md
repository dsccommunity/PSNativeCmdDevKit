---
description: 'Public PowerShell function instructions'
applyTo: 'source/Public/**/*.ps1'
---

# Public function guidelines

- Use `[CmdletBinding()]`.
- Use explicit parameter and output types where the contract is stable.
- Preserve Windows PowerShell 5.1 and cross-platform compatibility.
- Include `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and `.EXAMPLE` help.
- Keep executables and argument arrays structurally separate.
- Preserve native standard-output and standard-error behavior.
- Update the matching test under `tests\Unit` for every behavior change.
- Update `README.md` and `CHANGELOG.md` for user-visible changes.
