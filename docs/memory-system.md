# Memory System — Architecture

Larry's memory system. Persistent memories that survive sessions and make Larry a genuine second brain.

---

## Filesystem

```
~/.claude/projects/{{VAULT_SLUG}}/memory/
├── MEMORY.md          ← Master index: all memories linked here
├── user/              ← Facts about the user
├── feedback/          ← Learned preferences and behavioral rules
├── project/           ← Active project memories
└── reference/         ← Technical reference memories
```

`{{VAULT_SLUG}}` is the path-to-slug of your vault (e.g., `D--01-Larry` on Windows or `Users--you--vault` on Mac).

---

## MEMORY.md — Index

The master index read at session start. Structured as:

```markdown
## user/
- [Memory title](user/filename.md) — Short description

## feedback/
- [Memory title](feedback/filename.md) — Short description

## project/
- [Memory title](project/filename.md) — Short description

## reference/
- [Memory title](reference/filename.md) — Short description
```

Each entry links to the memory file and has a one-line summary. Larry reads MEMORY.md on init and knows what's available.

---

## Categories

### user/ — Facts About the User

Stable information about the person:
- Physical data and appearance
- Home address and location
- Relationships (names, context, how to communicate)
- Subscriptions and tools
- Environment descriptions (home, workspace)
- Online profiles

Updated rarely. Stable factual base.

### feedback/ — Learned Preferences

How Larry should behave, based on corrections and feedback:
- Tool choices (e.g., always use X CLI, never Y MCP plugin)
- Communication style (e.g., no pleasantries, no goodbyes)
- Barry rules (upscale only on request, QA before download)
- Harry rules (voice selection, TTS style)
- Privacy rules (vault-first, content separation)
- Workflow rules (robust over quick, clean up temp files)

Updated every time the user corrects behavior.

### project/ — Project Memories

Active context about ongoing projects:
- Agent ecosystem design
- Product/feature statuses
- Partnership and business contexts
- Ongoing research

Updated when project status changes.

### reference/ — Technical References

Stable technical configuration:
- Browser setup (persistent profile, default tabs)
- Shell aliases and functions
- Email/calendar rules
- External tool configurations

---

## How Memories Are Created

1. User corrects Larry's behavior → Larry creates feedback memory
2. Larry observes a fact about the user → Larry creates user memory (careful with L4)
3. New project status → Larry updates project memory
4. New technical configuration established → Larry creates reference memory
5. Larry always updates MEMORY.md index

**Memory file format:**
```markdown
# Memory Title

Short description of what this memory contains.

## Content

[The actual memory content]

## Created
YYYY-MM-DD

## Last updated
YYYY-MM-DD
```

---

## How Memories Are Used

1. At session start, hook `load-context.sh` reads relevant memories
2. MEMORY.md index is included in system-reminder (automatic context)
3. On "initiate" command: Larry reads relevant memories explicitly
4. During conversation: "always search vault (incl. _private/) before external search"

---

## Privacy in Memories

- `user/` and `feedback/` may contain L2-3 information (personal)
- L4 content (unconscious, deeply personal) stored with extra care
- Memories never referenced in output that could leave the vault
- Feedback memories about NSFW behavior: privacy 3

---

## Vault vs. Memory

| Location | What | Access |
|----------|------|--------|
| `~/.claude/.../memory/` | Larry's operational memories | Automatic at session start |
| `{{VAULT_PATH}}/_active-context.md` | Ongoing work, blockers | Read at session start (hook) |
| `{{VAULT_PATH}}/_private/` | Privacy 3-4 notes | Vault search when needed |
| Vault otherwise | All other knowledge | Vault search when needed |

---

## _active-context.md

Different from MEMORY.md: `_active-context.md` is the **current session status** — what's happening right now, blockers, what was done last.

Updated by Larry at the end of each session (or when status changes).

---

## Implementation Notes

- Memory files are plain markdown — no special format required
- Larry creates and updates them via normal file write operations
- MEMORY.md must be kept in sync with actual memory files
- Stale memories should be archived or updated, not left outdated
- User can request memory cleanup: "clean up old memories"
