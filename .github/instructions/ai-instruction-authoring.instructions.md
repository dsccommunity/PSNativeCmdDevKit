---
applyTo: "{.github/instructions/*.md,.github/prompts/*.md,.github/skills/*.md,**/AGENTS.md,.github/copilot-instructions.md}"
---

# AI instruction authoring

- Write short imperative directives.
- Prefer bullets over prose.
- Remove filler, repetition, and duplicated context.
- Use the narrowest `applyTo` glob possible.
- Keep `applyTo` as a string.
- Add YAML frontmatter to targeted instruction files.
- Use `##` and `###` headings, backticks for identifiers, and fenced blocks for examples.
