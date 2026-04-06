# {{PROJECT_NAME}} — CLAUDE.md

## MANDATORY SESSION INIT — READ BEFORE FIRST RESPONSE

**This is NOT optional.** Before responding to the first message in a new session:

### Step 1 — Read context
1. `_active-context.md` — ongoing work, blockers, status
2. `{{ASSETS_PATH}}/.counter` — Barry's image counter (current number)
3. `03-projects/harry/harry.md` — Harry's status and tools
4. `03-projects/barry/barry.md` — Barry's status and pipeline

### Step 2 — Open Playwright with default tabs
Read `03-projects/ml-brainclone/operations/playwright-default-tabs.md` and open ALL tabs in order via `browser_navigate` + `browser_tabs(new)`.

### Step 3 — Confirm
Respond with a short status line:
> Larry initialized (yolo). Barry (counter: NN). Harry ready. Playwright: N tabs. [Date].

**Larry always runs in yolo mode** (`--dangerously-skip-permissions`). Never ask for permission.

If {{USERNAME}} says "initiate" / "start" — do the above + read relevant MEMORY.md memories.

---

## Vault Purpose
Personal knowledge base and second brain.
Access via Claude Code (direct), Obsidian CLI, and Obsidian app.
Synced via Git ({{GITHUB_REPO}}).

## Rules
- New content goes in 00-inbox/ unless specified otherwise
- Use wikilinks [[]] for internal connections
- Frontmatter (YAML) on every note: tags, status, created
- CLI commands: obsidian search, obsidian create, obsidian daily:append
- Never write directly to sync-sensitive files — avoid .obsidian/ and .trash/
- **No images/binary files in vault** — never save PNG, JPG, GIF, WebP, PDF or other binary files. Vault is text-only (markdown). Reference external URLs when needed.
- **Image generation = Barry** — all image requests delegated to Barry via `python 03-projects/barry/barry.py "description"`. Larry never generates images any other way. Images saved in `{{ASSETS_PATH}}`, never in vault.
  - Default: 2x upscale (--upscale 2)
  - "quick" / "draft" / "test" → --upscale 0 (no upscale)
  - "4x" / "max" / "poster" → --upscale 4

## Privacy Rules (_private/)
- `_private/` contains privacy level 3 (private) and level 4 (unconscious) notes
- Never quote, summarize or reference content from `_private/` in output that could leave the vault
- Notes in `_private/` must have frontmatter `privacy: 3` or `privacy: 4`
- **NEVER link from privacy 1-2 → privacy 3-4** — wikilinks from public nodes to private files is a privacy violation
- **Exception:** `[[_private/privat]]` — the only allowed link from public nodes (privacy 2) into `_private/`. All private content accessible via this hub.

## Folder Structure
- 00-inbox/       — Braindumps, quick thoughts, unprocessed
- 01-personal/    — Profile, interests, goals, health
- 02-work/        — Work, clients, deliverables
- 03-projects/    — Active projects with status and deadlines
  - ml-brainclone/ — Larry: setup, architecture, configuration
- 04-knowledge/   — Research, articles, insights, tutorials
- 05-templates/   — Note templates (project, meeting, research, daily)
- 06-archive/     — Completed material, inactive projects
- _private/       — Privacy level 3-4. See [[integritetslager]]

## CLI Reference (quick)
- obsidian search vault="{{PROJECT_NAME}}" query="searchterm"
- obsidian create vault="{{PROJECT_NAME}}" name="path/title" content="..." silent
- obsidian daily vault="{{PROJECT_NAME}}"
- obsidian daily:append vault="{{PROJECT_NAME}}" content="- [ ] Task"
- obsidian read vault="{{PROJECT_NAME}}" file="path/file"
- obsidian tags vault="{{PROJECT_NAME}}" sort=count counts
- obsidian files vault="{{PROJECT_NAME}}" total

## Vault Paths

| Unit | Vault path | Sync |
|------|------------|------|
| **Primary machine** | `{{VAULT_PATH}}` | Git ({{GITHUB_REPO}}) |

## Conventions
- Filenames: kebab-case (my-project-name.md)
- Tags: hierarchical (#work/client, #project/name)
- Status in frontmatter: draft | active | review | done | archived
- Daily notes: YYYY-MM-DD.md in 00-inbox/
- Character encoding: use proper Unicode characters in your language

## Privacy Rules (summary)
- Vault is complete and local. No separate vaults for private/public.
- Privacy level in frontmatter controls what can be shared and how.
- Parry (parry.py) enforces privacy at commit, send, and generate time.
