# Memory System — Architecture

Larry's memory system. Three layers that work together: file-based memories (MEMORY.md), semantic memory (MemPalace/Milla), and active context. Persistent across sessions — making Larry a genuine second brain.

---

## Layer 1: File-Based Memories (MEMORY.md)

### Filesystem

```
~/.claude/projects/{{VAULT_SLUG}}/memory/
├── MEMORY.md          ← Master index: all memories linked here
├── user/              ← Facts about the user
├── feedback/          ← Learned preferences and behavioral rules
├── project/           ← Active project memories
└── reference/         ← Technical reference memories
```

`{{VAULT_SLUG}}` is the path-to-slug of your vault (e.g., `D--01-Larry` on Windows or `Users--you--vault` on Mac).

### MEMORY.md — Index

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

### Categories

#### user/ — Facts About the User

Stable information about the person:
- Physical data and appearance
- Home address and location
- Relationships (names, context, how to communicate)
- Subscriptions and tools
- Environment descriptions (home, workspace)
- Online profiles

Updated rarely. Stable factual base.

#### feedback/ — Learned Preferences

How Larry should behave, based on corrections and feedback:
- Tool choices (e.g., always use X CLI, never Y MCP plugin)
- Communication style (e.g., no pleasantries, no goodbyes)
- Barry rules (upscale only on request, QA before download)
- Harry rules (voice selection, TTS style)
- Privacy rules (vault-first, content separation)
- Workflow rules (robust over quick, clean up temp files)

Updated every time the user corrects behavior.

#### project/ — Project Memories

Active context about ongoing projects:
- Agent ecosystem design
- Product/feature statuses
- Partnership and business contexts
- Ongoing research

Updated when project status changes.

#### reference/ — Technical References

Stable technical configuration:
- Browser setup (persistent profile, default tabs)
- Shell aliases and functions
- Email/calendar rules
- External tool configurations

---

## Layer 2: Semantic Memory (MemPalace / Milla)

MemPalace provides meaning-based search over the entire vault. Instead of text-matching with grep, Larry can search by meaning — "why did we change the auth flow?" finds relevant context even if those exact words never appear.

**MCP server** — 19 tools available in Claude Code. See [mempalace-setup.md](mempalace-setup.md) for installation.

### Search Rules

**MANDATORY: `mempalace_search` BEFORE Glob/Grep** for open-ended questions. Glob/Grep = only for exact searches (filenames, function names, literal strings).

**Room strategy:** The `daily` room is automatically excluded from semantic search. Use `room="daily"` explicitly ONLY for timeline questions ("what happened on X?", "what did we work on last week?").

**Fallback flow** for unknown persons/topics:
1. `mempalace_search` — no hit
2. Glob/Grep vault — no/thin hit
3. WebSearch — look up the person/topic
4. Create note in `01-personal/` (person) or `04-knowledge/` (topic)
5. Tell user what was saved

### Graph Navigation

For deeper exploration beyond simple search:

| Tool | When to use |
|------|------------|
| `mempalace_traverse` | Exploring a topic — see side context and connections. Max 2 hops normally, 3 for broad research. |
| `mempalace_find_tunnels` | Cross-domain questions — "how does X connect to Y?" Returns bridge rooms between two wings. |
| `mempalace_list_rooms` | Orientation — "what topics exist in area X?" |
| `mempalace_get_taxonomy` | Full palace structure overview. |

### Knowledge Graph (KG)

KG is Milla's long-term factual memory. Stored as subject-predicate-object triples.

**Principle:** If you don't update KG when facts change, Milla forgets. Update immediately, in the session it happens.

#### Mandatory triggers — run `kg_add` immediately:

| Event | Subject | Predicate | Object |
|-------|---------|-----------|--------|
| Barry generates image | `Barry` | `counter_is` | `<new number>` |
| Project changes status | `ProjectName` | `version_is` | `v1.0 live` |
| New person mentioned | `PersonName` | `role_is` / `relation_to` | description |
| User mentions new preference | `{{USERNAME}}` | `preference_is` | description |
| Project ends/paused | invalidate old, add new | `status_is` | `archived` / `paused` |
| Deadlines change | `ProjectName` | `deadline_is` | new date |
| New blocker arises | `ProjectName` | `blocker_is` | description |

#### Flow on fact change:
1. `mempalace_kg_query(entity)` — check what already exists
2. `mempalace_kg_invalidate(triple_id)` — invalidate old fact if exists
3. `mempalace_kg_add(subject, predicate, object)` — add new

**Rule:** `mempalace_kg_query` ALWAYS before asserting anything about an entity. Never guess — verify.

#### Session-init KG sync (Step 1b):
After hook runs — check if `00-inbox/kg-updates-*.md` exists (created by night shift). If yes: read and apply the suggested `kg_add`/`kg_invalidate` calls.

### Diary (Session Continuity)

The diary bridges sessions — what happened last time, what was decided, what's pending.

- **`mempalace_diary_read`** — Run at session init (Step 2 in CLAUDE.md). Always read 5 most recent entries.
- **`mempalace_diary_write`** — Run when session ends OR after a large task. Format: AAAK compressed.
  - Example: `SESSION:2026-04-09|USR.asked:milla.integration|implemented.diary+kg+traverse|+++`
- Never write diary mid-task — only at natural completion points.

### Indexing

| Agent | Integration |
|-------|-----------|
| **Larry** | MCP server (19 tools) + CLAUDE.md search rules |
| **Barry** | Pre-generation search + post-generation indexing |
| **Harry** | STT transcript indexing after transcription |
| **Night shift** | `mempalace mine` incrementally every night (step 0) |

**Check duplicates:** Always run `mempalace_check_duplicate` before manual `mempalace_add_drawer`.
**Re-mine:** `python -m mempalace mine "{{VAULT_PATH}}"` when needed.

---

## Layer 3: Active Context

### _active-context.md

Different from MEMORY.md: `_active-context.md` is the **current session status** — what's happening right now, blockers, what was done last.

Updated by Larry at the end of each session (or when status changes).

---

## How the Layers Work Together

| Layer | Purpose | Technology | Access |
|-------|---------|------------|--------|
| **MEMORY.md** | Curated, structured memories (user prefs, feedback, project state) | Markdown files | Automatic at session start |
| **MemPalace** | Semantic retrieval over entire vault + KG facts + diary continuity | ChromaDB + ONNX embeddings + MCP | 19 tools in Claude Code |
| **_active-context.md** | Working memory — current session state | Markdown file | Read at session start (hook) |
| **Vault** | All other knowledge | Markdown files | Search when needed |

- MEMORY.md for precise, curated knowledge
- MemPalace for broad semantic search when you don't know which file has what you need
- KG for factual assertions that must stay current
- Diary for session-to-session continuity
- _active-context.md for "what am I doing right now"

---

## How Memories Are Created

1. User corrects Larry's behavior -> Larry creates feedback memory
2. Larry observes a fact about the user -> Larry creates user memory (careful with L4)
3. New project status -> Larry updates project memory
4. New technical configuration -> Larry creates reference memory
5. Fact changes -> Larry updates KG (query, invalidate, add)
6. Session ends -> Larry writes diary entry
7. Larry always updates MEMORY.md index

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

## Privacy in Memories

- `user/` and `feedback/` may contain L2-3 information (personal)
- L4 content (unconscious, deeply personal) stored with extra care
- Memories never referenced in output that could leave the vault
- Feedback memories about NSFW behavior: privacy 3

---

## Implementation Notes

- Memory files are plain markdown — no special format required
- Larry creates and updates them via normal file write operations
- MEMORY.md must be kept in sync with actual memory files
- Stale memories should be archived or updated, not left outdated
- User can request memory cleanup: "clean up old memories"
