---
description: 'WDAC and PowerShell language-mode security instructions'
applyTo: '{source/**/*.ps1,source/**/*.psm1,source/**/*.psd1,RequiredModules.psd1,build.yaml}'
---

# WDAC PowerShell language-mode safety

## Prohibited patterns

- Never pass caller-controlled strings to `[scriptblock]::Create()`, `Invoke-Expression`, `AddScript()`, or equivalent dynamic PowerShell evaluation.
- Never concatenate an executable, username, option, or argument into PowerShell source text.
- Never stringify a caller-provided script block and recompile it.
- Never assume input is trusted because the containing module is signed.
- Never sign or redistribute copied PowerShell source without reviewing its exported trust boundary.

## Required implementation patterns

- Invoke native commands with the call operator and splatted argument arrays:

```powershell
& $Executable @Parameters 2>&1
```

- Pass `sudo`, `-u`, usernames, executables, and arguments as separate array elements.
- If script blocks are part of the public API, retain and invoke the original script block object so its language mode is preserved.
- A plain string has no caller language-mode or execution-context metadata.
  Trusted code cannot reconstruct the caller's language mode from text.
- `[scriptblock]::Create()` has no public language-mode parameter. Calling it
  inside trusted code compiles in the trusted execution context.
- Do not accept a caller-supplied language-mode value as proof of provenance.
- A separately constrained runspace is a new isolation context, not the
  caller's original context.
- If executable caller logic is required, accept a caller-created
  `[scriptblock]`, retain the exact object, and invoke it directly.
- If an API receives only text, treat it as data, parse it with a deliberately
  limited non-PowerShell grammar, or reject it.
- Prefer structured data rules over executable predicates.
- Consider `[ValidateTrustedData()]` when a trusted function must reject values originating from constrained callers.

## Review procedure

1. Search source and built artifacts for `ScriptBlock.Create`, `Invoke-Expression`, `AddScript`, command strings, and call-operator use.
2. Trace every value entering those APIs to determine whether a constrained caller controls it.
3. Inspect nested modules and the final signed package, not only source files.
4. Verify which child manifests can be imported directly and which functions they export.
5. Test from a `ConstrainedLanguage` runspace and assert that caller-provided script blocks remain constrained.
6. Verify that no code path converts a caller scriptblock to text and recreates
   it, and that no string parameter is treated as recoverable caller code.
7. Test metacharacters and PowerShell expressions in executable and argument parameters and assert they remain inert data.
8. Re-run the search against the merged `.psm1` under `output\module`.
