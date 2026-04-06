# Privacy Architecture

Four levels. One vault. One gatekeeper.

---

## Core Principle

The vault is complete and local. No separate vaults for private vs public — that would break the knowledge graph. Instead, frontmatter tagging and folder structure control what can be shared and how.

---

## Privacy Levels

| Level | Name | Content | Location | Synced to GitHub |
|-------|------|---------|----------|-----------------|
| **L1** | Open | Public info, work content, knowledge | Vault root | Yes (private repo) |
| **L2** | Personal | Private but not sensitive. Personal notes. | Vault root | Yes |
| **L3** | Private | Sensitive: health, finance, relationships | `_private/` | Yes (private repo) |
| **L4** | Subconscious | Deeply personal, AI observations, the unsaid | `_private/` | Yes (private repo) |

**Important:** The GitHub repo is private. L3-4 is not publicly exposed — but should be treated as if it could be, for future-proofing.

---

## Folder Structure (_private/)

```
_private/
├── hub.md              <- ONLY allowed public → private wikilink hub
├── secrets/            <- API keys, deploy guides (ROTATE YOUR KEYS!)
├── clients/            <- Confidential client research
├── personal-context/   <- Personal instructions, context
└── ...                 <- Your own categories as needed
```

---

## Frontmatter

All notes should have a `privacy` field:

```yaml
---
privacy: 1   # Open
privacy: 2   # Personal
privacy: 3   # Private (_private/ required)
privacy: 4   # Subconscious (_private/ required)
---
```

Files in `_private/` without `privacy: 3` or `privacy: 4` are flagged as violations by Parry.

---

## Wikilink Rules

**Core rule:** L1-2 files must NEVER wikilink to L3-4 files.

```markdown
# ALLOWED:
[[_private/hub]]       <- The one exception: the hub node

# FORBIDDEN:
[[_private/clients/clientname]]
[[_private/personal/something]]

# Correct alternative:
See (_private/clients/) for client info.
```

Wikilinks from `_private/` to other `_private/` files are OK.

---

## Parry — Gatekeeper Agent

`parry.py` is the privacy enforcement layer. Middleware that checks content at:

| Trigger | Parry check |
|---------|-------------|
| `git commit` | Privacy scan of staged changes |
| Email send | Tone + privacy + attachments |
| Image generation | QA + privacy-level tagging |
| Audio generation | Privacy level + voice selection |
| Note creation | Frontmatter + tags + privacy |

### Parry Modes

| Mode | Symbol | Behavior |
|------|--------|---------|
| **off** | Red | Completely off. Zero filtering. |
| **balanced** | Yellow | Default. Schedule-based (work hours vs evening/night). |
| **strict** | Green | Everything reviewed. Good before client meetings. |

```bash
parry off        # Turn off
parry on         # Balanced (default)
parry strict     # Strict mode
parry status     # Show current mode
parry scan <file> # Scan a file
parry audit      # Scan entire vault
```

### Balanced Schedule

- **Weekdays 07-17 (work hours):** Privacy scan active. Sensitive content flagged. Tone check on professional channels.
- **Evenings and weekends:** Only hard violations (L3/L4 → public channels) blocked.
- **Night 00-06:** Like evenings, but extra careful with L4 content.

---

## API Key Scanning

Parry always scans for leaked keys:

| Pattern | Type |
|---------|------|
| `sk-[A-Za-z0-9_-]{20,}` | OpenAI API key |
| `ghp_[A-Za-z0-9]{36,}` | GitHub personal access token |
| `AIza[A-Za-z0-9_-]{35}` | Google API key |
| `AKIA[A-Z0-9]{16}` | AWS access key |
| `sk-ant-[A-Za-z0-9_-]{20,}` | Anthropic API key |

Detected keys should be rotated immediately.

---

## Nightly Automation and Privacy

The nightly batch jobs (running on Haiku) operate with these hard rules:
- Write ONLY to `00-inbox/`
- NEVER write to `_private/`
- Never delete, never modify existing files
- Exclude L3-4 content from monitoring
- NEVER wikilink to privacy 3-4 from generated reports

---

## Tone Profiles per Channel

Parry can enforce tone per output channel:

| Channel | Formality | Rules |
|---------|-----------|-------|
| linkedin | High | No profanity, max 2 emojis |
| email-work | Medium-high | No profanity, max 1 emoji |
| email-personal | Low | No restrictions |
| social | Low | Max 3 emojis |
| vault | None | Completely free |

Recipient profiles for specific contacts can further adjust tone.

---

## See Also

- [architecture-overview.md](architecture-overview.md) — System overview
- [larry-setup.md](larry-setup.md) — Larry configuration
- [memory-system.md](memory-system.md) — Memory architecture
