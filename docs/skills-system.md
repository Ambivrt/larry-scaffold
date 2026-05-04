# Skills System

Skills are markdown files your agent discovers and loads on-demand. Three layers:

1. **Discovery** — Agent reads `skills/INDEX.md` (list + triggers + paths)
2. **Metadata** — Agent inspects skill frontmatter (without reading the full file)
3. **Load** — Agent reads the full skill file on-demand

This is progressive disclosure — you pay context cost only for skills you actually use.

## Skill Frontmatter

Add a `skill:` block on top of existing vault frontmatter:

```yaml
---
tags: [reference, tool]
status: active
created: 2026-04-22
privacy: 1
skill:
  name: vault-ingest
  description: Convert documents (PDF/DOCX/PPTX/XLSX) to vault Markdown
  version: 1.0
  when_to_load:
    - "convert file to markdown"
    - "import document into vault"
    - "put PDF/Word/PowerPoint into inbox"
  requires: []
  provides: [file-to-markdown, vault-inbox-pipeline, document-conversion]
---
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | str | yes | kebab-case, globally unique |
| `description` | str | yes | One sentence, what the skill does |
| `version` | float | yes | Bump on breaking change |
| `when_to_load` | list[str] | yes | Triggers the agent matches against the task |
| `requires` | list[str] | no | Other `skill.name` values this depends on |
| `provides` | list[str] | no | Sub-capabilities for granular discovery |

## Discovery Flow

```
1. User gives agent a task
2. Agent reads CLAUDE.md (auto)
3. If task matches potential skill -> Read skills/INDEX.md
4. INDEX lists skill with trigger + path
5. Agent inspects skill frontmatter (Read with limit=20)
6. If match -> Read full skill
```

## INDEX.md Format

Organize skills into categories with trigger keywords per category. The agent scans category headers and triggers — only loads the skill file on match. This keeps the discovery step cheap on context.

```markdown
## Categories

### System & Agents
Trigger: build agent, new daemon, Python/Bash code, debug, refactor, bus integration, convert document

| Skill | Path |
|-------|------|
| `agent-development` | [[agent-development]] |
| `system-coding` | [[system-coding]] |
| `vault-ingest` | [[vault-ingest]] |

### Image & Audio
Trigger: image, prompt, diffusion, upscale, TTS, STT, music, SFX

| Skill | Path |
|-------|------|
| `image-prompts` | [[image-guide]] |
| `audio-skills` | [[audio-skills]] |

### Business & Strategy
Trigger: business plan, budget, sales, negotiation, legal, SEO

| Skill | Path |
|-------|------|
| `business-planning` | [[business-planning]] |
| `financial-reasoning` | [[financial-reasoning]] |
| `sales-thinking` | [[sales-thinking]] |
```

**Why categories?** A flat table of 20+ skills forces the agent to scan every row. Categories let it skip entire groups ("this task has nothing to do with Business & Strategy") and zoom into the right cluster. Same progressive disclosure principle, applied one level earlier.

## When to Create a Skill

- Recurring work with a stable pattern
- You notice the agent rediscovering the same approach repeatedly
- A long note only needed in a specific context (lazy load instead of always-on)

## When NOT to Create a Skill

- One-off research
- Personal notes
- Index/meta-notes

## Self-Patch

When the user corrects agent output based on a skill, or the agent rediscovers the same fix more than twice, propose a patch to the skill file.
