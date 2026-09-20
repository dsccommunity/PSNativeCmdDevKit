---
description: 'Build and pipeline instructions'
applyTo: '{build.ps1,build.yaml,RequiredModules.psd1,Resolve-Dependency.ps1,Resolve-Dependency.psd1,azure-pipelines.yml,GitVersion.yml}'
---

# Build and pipeline guidelines

- Use `build.ps1` as the only build entrypoint.
- Keep dependencies under `output\RequiredModules`.
- Keep `Sampler` pinned to the reviewed prerelease in `RequiredModules.psd1`.
- Prefer `PSResourceGet` through `Resolve-Dependency.psd1`.
- Configure workflows and Pester in `build.yaml`; do not embed build logic in Azure Pipelines.
- Keep WikiSource generation in the `docs` workflow and GitHub wiki deployment
  in the `publish` workflow.
- Use supported `*-latest` hosted images and pipeline artifacts.
- Test Windows PowerShell 5.1, PowerShell 7 on Windows, Linux, and macOS.
- Run `./build.ps1 -Tasks test` after build or pipeline changes.
- Run `./build.ps1 -Tasks hqrmtest` before release-related changes are considered complete.
