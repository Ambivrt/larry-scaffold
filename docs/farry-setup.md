# Farry Setup — Universal Interpreter

Farry is Larry's translation and interpretation skill. Unlike Parry and Tarry, Farry is **not a separate process** — it is built into Larry as an inline skill, invoked on demand.

- **Larry** — thinks, plans, orchestrates
- **Barry** — sees (images)
- **Harry** — hears and speaks (audio)
- **Parry** — guards, filters, judges
- **Tarry** — remembers when
- **Farry** — understands all languages

---

## What Farry Does

| Domain | Function |
|--------|----------|
| Human languages | Real-time translation between any natural language pair |
| Machine→human | Explains API responses, log output, error messages in plain language |
| Code↔code | Converts code between programming languages |
| Agent↔agent | Bridges format and protocol mismatches between agents or external services |
| Domain glossaries | Maintains personal vocabulary files per domain (medical, legal, technical, etc.) |

---

## Architecture

Farry is a **Larry skill** — no separate process, no startup, no heartbeat. It activates when Larry invokes it.

```
User request (Telegram: /f ...)
        │
        ▼
Larry receives message
        │
        ▼
Farry skill loaded (03-projects/ml-brainclone/skills/farry.md)
        │
        ▼
Translation / interpretation performed inline
        │
        ▼
Result returned to user
```

Because Farry runs inside Larry's context window, it has full access to vault content, memory, and the active conversation — useful for translating personal notes or interpreting domain-specific content.

---

## Telegram Commands

| Command | Action |
|---------|--------|
| `/f <text>` | Translate or interpret the text (Farry auto-detects language and intent) |
| `/farry <text>` | Same as `/f`, full command name |
| `/f explain <text>` | Force machine→human explanation mode |
| `/f <lang> <text>` | Translate to a specific language (e.g. `/f english Hej världen`) |

Examples:

```
/f Bonjour, comment allez-vous?
/f english Det verkar som att sessionen har avbrutits
/f explain {"error":"ECONNREFUSED","code":111}
/f python def greet(name): print(f"Hello {name}")  # convert to JS
```

---

## Installation

Farry requires no installation beyond copying the skill file.

1. Copy `farry.md` to `03-projects/ml-brainclone/skills/farry.md` in your vault.
2. Add `farry` to the skills index: `03-projects/ml-brainclone/skills/INDEX.md`.
3. Configure Telegram routing to forward `/f` and `/farry` commands to Larry.

No Python script, no service, no scheduler entry needed.

---

## Language Reference Files

Farry stores personal glossaries and domain vocabularies in:

```
01-personal/sprak/
├── glossary-tech.md          — Technical / software terms
├── glossary-medical.md       — Medical vocabulary
├── glossary-legal.md         — Legal and contract terms
└── glossary-<domain>.md      — Add as needed
```

Format (plain markdown, one term per line):

```markdown
## EN → SV

- **API rate limit** → API-hastighetsgräns
- **throughput** → genomströmning
- **idempotent** → idempotent (oförändrat resultat vid upprepning)
```

Farry reads these files when translating in the relevant domain to preserve your preferred terminology.

---

## Supported Translation Modes

| Mode | Trigger | Example |
|------|---------|---------|
| Auto-detect | `/f <text>` | Detects source + target automatically |
| Explicit target | `/f <lang> <text>` | `/f svenska Here is the report` |
| Explain (machine→human) | `/f explain <text>` | Parses JSON, logs, stack traces |
| Code convert | `/f <target-lang> <code>` | `/f javascript def greet(): ...` |
| Agent bridge | Internal Larry call | Translates between agent message schemas |

For ambiguous input, Farry asks a single clarifying question before proceeding.

---

## Privacy

Farry runs inside Larry's process with full vault access. It respects the standard privacy levels:

- Translated content is never sent to external services — translation uses the same model (Claude) already processing the conversation.
- If the source text contains L3/L4 content, the output inherits that privacy level.
- Glossary files in `01-personal/sprak/` should be tagged `privacy: 2` (personal but not sensitive).

---

## See Also

- [larry-setup.md](larry-setup.md) — Larry (Claude Code) configuration
- [tarry-setup.md](tarry-setup.md) — Tarry temporal daemon
- [agent-capabilities.md](agent-capabilities.md) — Capability matrix for all agents
- [architecture-overview.md](architecture-overview.md) — Agent ecosystem overview
