# Copilot instructions for PSNativeCmdDevKit

## Git workflow

- Never run `git commit`, `git push`, or `git tag`. Leave commits and pushes to the user.
- Stage files only when explicitly asked.
- Summarize changed files and validation results for review with `git diff`.

## Build entrypoint

- Use `./build.ps1` for dependency restore, build, test, packaging, and quality checks.
- Bootstrap with `./build.ps1 -ResolveDependency -Tasks noop`.
- Build with `./build.ps1 -Tasks build`.
- Run focused tests with `./build.ps1 -Tasks test -PesterPath '<path>' -CodeCoverageThreshold 0`.
- Run the default suite with `./build.ps1 -Tasks test`.
- Run quality checks with `./build.ps1 -Tasks hqrmtest`.
- Do not call `Invoke-Pester`, `Build-Module`, or dependency resolvers directly from a fresh shell.
- Do not manually edit `PSModulePath` or copy files into `output\module`.

## Repository constraints

- Keep compatibility with Windows PowerShell 5.1 and PowerShell 7+.
- Keep native-command behavior cross-platform on Windows, Linux, and macOS.
- Treat `source\Public` as the public compatibility surface.
- Keep hand-authored GitHub wiki pages under `source\WikiSource`; generated wiki
  content belongs under `output\WikiContent`.
- Keep comment-based help and matching unit tests current for every public function.
- Add an `Unreleased` changelog entry for behavior, security, dependency, or pipeline changes.
- Preserve executable and argument boundaries. Never turn caller-controlled command data into PowerShell source.
- Strings do not retain caller language mode. When executable caller logic is
  required, accept and invoke the original caller-created scriptblock; never
  stringify or recreate it in trusted module code.

## Instruction files

- Follow `.github\instructions\*.instructions.md`.
- Use `.github\skills\validate-changes\SKILL.md` to choose validation scope.
