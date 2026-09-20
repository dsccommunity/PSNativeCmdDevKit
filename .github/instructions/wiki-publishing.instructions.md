---
description: 'GitHub wiki content and publishing instructions'
applyTo: 'source/WikiSource/**/*.md,build.yaml,azure-pipelines.yml'
---

# GitHub Wiki Publishing Guidelines

## Source of truth

- Keep hand-authored GitHub wiki pages under `source\WikiSource`.
- Treat `source\WikiSource` as canonical; do not edit generated files under
  `output\WikiContent`.
- Prefer stable page names so published wiki links do not churn.

## Build wiring

- Keep wiki generation and publishing wired through `build.yaml`.
- Keep `Copy_Source_Wiki_Folder` before `Generate_Wiki_Sidebar`.
- Keep `Package_Wiki_Content` in the `docs` workflow so `WikiContent.zip` is
  included in the pipeline artifact.
- Keep `Publish_GitHub_Wiki_Content` in the `publish` workflow. The Azure
  Pipelines deployment stage supplies the existing `GitHubToken`.

## Validation

- Validate generated content with `./build.ps1 -Tasks docs`.
- Validate release packaging with `./build.ps1 -Tasks pack`.
- Do not invoke the publishing task locally unless deployment was explicitly
  requested and an appropriate token is available.
