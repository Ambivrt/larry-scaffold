# Obsidian Bases

Built-in Obsidian feature (v1.9.10+). Live database views on top of vault frontmatter. No plugin required.

---

## What it does

`.base` files query YAML frontmatter across your vault and render the results as table or card views. Views update automatically when frontmatter changes.

Faster and simpler than Dataview. No query language to learn. Edit via UI or raw YAML.

---

## Quick syntax reference

```yaml
# .base file structure (YAML)

filters:              # Global — applies to all views
  and:
    - 'file.path.contains("03-projects")'
    - 'file.ext == "md"'
    - 'status != "archived"'

properties:           # Column display names
  status:
    displayName: Status
  updated:
    displayName: Updated

views:
  - type: table       # or: card
    name: Active projects
    groupBy:
      property: status
      direction: ASC   # or: DESC
    limit: 50
    order:             # Column order
      - file.name
      - status
      - updated
    filters:           # View-specific filter (stacks on global)
      and:
        - 'status == "active"'
```

---

## Available file properties

| Property | Type | Description |
|----------|------|-------------|
| `file.name` | String | Filename with extension |
| `file.path` | String | Full vault path |
| `file.folder` | String | Parent folder path |
| `file.ext` | String | Extension (no dot) |
| `file.size` | Number | Size in bytes |
| `file.ctime` | Date | Created |
| `file.mtime` | Date | Modified |
| `file.tags` | List | All tags |
| `file.links` | List | Outgoing wikilinks |
| `file.backlinks` | List | Incoming links |

Note frontmatter properties are accessed as `status`, `tags`, `created`, etc. (shorthand) or `note.status`, `note.tags`.

---

## String methods in filters

```yaml
- 'file.path.contains("03-projects")'      # Substring match
- 'file.name.startsWith("2026-")'          # Prefix match
- 'file.name.endsWith("-spec")'            # Suffix match
- 'tags.contains("daily")'                 # List contains value
- 'note["my-prop"] != ""'                  # Hyphenated property name
```

---

## The `this` object (Dynamic Links)

When a base is embedded in a note or in the sidebar, `this` refers to the currently active file:

```yaml
filters:
  and:
    - 'file.folder == this.file.folder'   # Notes in same folder as active file
```

This enables sidebar panels that update dynamically based on what you're reading.

---

## Relationship to the AI assistant

| | Bases | AI (Claude Code) |
|---|---|---|
| **Answers** | "Show all active projects" | "What connects these projects?" |
| **Queries** | Explicit frontmatter (tagged, structured) | Semantic content (implicit relationships) |
| **Updates** | Automatic (reads live frontmatter) | On request (via search, KG, memory) |

Bases cover structured retrieval. The AI covers semantic understanding. They complement each other.

---

## Included starter bases

| File | Queries | Views |
|------|---------|-------|
| `projects-active.base` | `03-projects/**` | Table + card, grouped by status |
| `inbox-triage.base` | `00-inbox/**` | Triage, daily notes |
| `knowledge-base.base` | `04-knowledge/**` | Research, grouped by status |

Customize by editing the YAML or using Obsidian's visual filter builder.

---

## Official docs

https://help.obsidian.md/bases/syntax
