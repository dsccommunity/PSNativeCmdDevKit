# Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Development workflow

Use `build.ps1` for dependency restore, builds, tests, and quality checks:

```powershell
./build.ps1 -ResolveDependency -Tasks noop
./build.ps1 -Tasks build
./build.ps1 -Tasks test
./build.ps1 -Tasks hqrmtest
```

Run a focused Pester file through Sampler:

```powershell
./build.ps1 -Tasks test `
    -PesterPath 'tests/Unit/Invoke-NativeCommand.Tests.ps1' `
    -CodeCoverageThreshold 0
```

The module supports Windows PowerShell 5.1 and PowerShell 7 on Windows, Linux,
and macOS. Keep tests portable unless the behavior is explicitly
platform-specific.

## Security-sensitive changes

Native executable names and arguments must remain separate values. Do not
construct PowerShell source from caller-controlled strings or recompile
caller-provided script blocks. Review
`.github/instructions/wdac-language-mode.instructions.md` before changing
command invocation, sudo rules, module exports, nested modules, or signing.
