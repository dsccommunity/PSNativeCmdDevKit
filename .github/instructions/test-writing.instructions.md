---
description: 'Pester test instructions'
applyTo: 'tests/**/*.tests.ps1'
---

# Pester test guidelines

- Use Pester 5-compatible syntax.
- Start new or modernized `It` descriptions with `Should`.
- Use `BeforeDiscovery` for generated test cases.
- Put setup and mocks in the smallest practical scope.
- Cover success, validation, failure, and platform-specific branches.
- Wrap pipeline results in `@()` before using `.Count` or indexing for Windows PowerShell 5.1 compatibility.
- Prefer the built module for exported behavior. Dot-source source files only
  when source-level coverage or isolated language-mode setup requires it.
- Add constrained-language regression tests for code that accepts commands, arguments, expressions, or script blocks.
- Run focused tests through:

```powershell
./build.ps1 -Tasks test -PesterPath 'tests/Unit/<File>.Tests.ps1' -CodeCoverageThreshold 0
```

- Run `./build.ps1 -Tasks test` after focused tests pass.
