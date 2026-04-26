# Scarry Setup — Retroactive Procrastination Scanner

Scarry is Larry's backward-looking scanner. Where Tarry watches the future (reminders, deadlines), Scarry scans the past — through archives, conversation logs, and knowledge graph entries — and surfaces things that were mentioned but never acted on.

- **Larry** — thinks, plans, orchestrates
- **Barry** — sees (images)
- **Harry** — hears and speaks (audio)
- **Parry** — guards, filters, judges
- **Tarry** — remembers when (forward-looking)
- **Scarry** — scans what was forgotten (backward-looking)

---

## Core Principle

People don't procrastinate by deciding to. They procrastinate through silence. A task gets mentioned once, maybe twice, then disappears from context. Not completed. Not cancelled. Just... gone.

Scarry listens for that silence.

A dental checkup discussed in February. A bill mentioned in passing. A friend you said you'd email "next week" — three weeks ago. A project spec that was written but never built.

Tarry watches what you **asked** to be reminded about. Scarry finds what you **never asked about** but still need to do.

---

## What Scarry Does

Scarry scans five categories of procrastinated items:

| Category | What it looks for |
|----------|-------------------|
| Health | Appointments mentioned but never booked, recurring symptoms without follow-up, prescriptions expiring |
| Finance | Unpaid bills approaching due date, tax filings, subscriptions to cancel, savings goals without action |
| Relationships | Promises to contact someone that went stale, birthdays approaching, commitments to family |
| Projects | Active projects with no commits in 14+ days, specs without implementation, passed deadlines, unresolved blockers |
| Admin | Contracts to renew, insurance reviews, license/passport renewals, paperwork mentioned but not filed |

---

## Architecture

Scarry is a **script**, not a daemon. Unlike Tarry and Parry (which run continuously), Scarry runs on-demand or on schedule. The archive doesn't change faster than once a day — there's no reason to poll.

```
scarry_scanner.py (one-shot script)
        │
        │ triggered by Darry (night shift) or Larry (on-demand)
        ▼
collect_signals()
        │
        │ queries Milla KG, diary, vault, git log, Tarry expired items
        ▼
filter_false_positives()
        │
        │ removes items already tracked by Tarry, parked, archived, or recently active
        ▼
prioritize()
        │
        │ P0 (time-critical) → P1 (relationships) → P2 (projects) → P3 (admin) → P4 (other)
        ▼
formulate()
        │
        │ generates questions (never instructions) via LLM
        ▼
output()
        │
        ▼
00-inbox/nattrapport-scarry-YYYY-MM-DD.md  +  brains-bus event to Darry
```

---

## Scanner Pipeline

### Step 1 — Collect Signals

Scarry gathers candidate items from multiple sources:

```
collect_signals()
  ├── query_kg()        → Milla KG: entities with action-related predicates
  │                       ("should_do", "wants_to", "needs_to", "deadline_is", "blocker_is")
  ├── scan_diary()      → Milla diary: mentions of action-language
  │                       ("book", "call", "pay", "fix", "check")
  ├── scan_vault()      → Vault notes: action-language without matching completion
  ├── check_projects()  → Git log: projects with status:active but no activity >14 days
  ├── check_tarry()     → Tarry follow-ups that expired without resolution
  └── check_inbox()     → Inbox notes that have sat untriaged for >14 days
```

### Step 2 — Filter False Positives

This is the most critical step. A noisy Scarry is a useless Scarry.

```
filter_false_positives()
  ├── has_active_tarry_reminder()    → Already watched by Tarry — skip
  ├── is_explicitly_parked()         → User chose to park it — skip
  ├── has_recent_activity()          → Activity in last 7 days — skip
  ├── is_project_paused()            → Project status:paused — skip
  ├── is_recurring()                 → Handled by Tarry recurring — skip
  └── is_explicitly_dismissed()      → User said "skip" / "not now" — skip
```

### Step 3 — Prioritize

Remaining items are sorted by urgency:

| Priority | Criteria | Example |
|----------|----------|---------|
| P0 | Time-critical: bills, deadlines <7 days, health with symptoms | Quarterly tax filing due in 5 days |
| P1 | Relationships: promises to people, stale contacts | Email to colleague promised 3 weeks ago |
| P2 | Projects: stale projects, unexecuted ideas | Side project with no commits in 21 days |
| P3 | Admin: renewals, paperwork, subscriptions | Passport expiring in 6 weeks |
| P4 | Everything else | Idea mentioned once, no follow-up |

### Step 4 — Formulate

Scarry asks questions. It never gives instructions.

**Wrong:** "You have 3 overdue health items. Book appointments."
**Right:** "That dental checkup we talked about in February — still not booked. Want to pick a day this week?"

Tone rules:
- Never judgmental ("you should have...")
- Never pushy ("you MUST...")
- Always curious ("this came up — still relevant?")
- Specific ("electric bill, $85, due April 30")
- Time-aware ("mentioned March 15 — 39 days ago")

---

## Output Format

Scarry generates a markdown report with items grouped by priority:

```markdown
# Scarry — 2026-04-23

## P0 — Time-critical
- **Electric bill** — $85, due April 30 (7 days). Mentioned April 16, no action.
  -> Paid? If yes, I can close this.

## P1 — Relationships
- **Emma** — "email her back next week" (April 2). 21 days ago.
  -> Still want to reach out, or has the moment passed?

## P2 — Projects
- **SideProject** — Status active, last commit April 3 (20 days).
  -> Pause formally, or set a sprint?
- **NewSpec** — Spec written April 22, zero implementation.
  -> Backlog? Or should it be built now?

## P3 — Health
- **Dental checkup** — Mentioned February, not booked.
  -> Pick one day. Just one. Book it.

## Parked (intentional)
- Feature X investigation — parked, waiting on dependency
- Language course — parked, revisit in Q3

*2 items closed since last scan (invoice paid, email sent)*
```

---

## Delivery Channels

| Channel | When | What |
|---------|------|------|
| Night shift (via Darry) | Once per night | Full report to `00-inbox/nattrapport-scarry-YYYY-MM-DD.md` |
| Morning brief | Every morning | P0 + P1 summary only, included in Darry's brief |
| On-demand | User asks ("what have I forgotten?" / "scan") | Larry triggers Scarry directly, full report |
| Telegram | P0 items <48h from deadline | Urgent push notification via Carry |

---

## Installation

1. Copy `scarry_scanner.py` to `03-projects/scarry/scarry_scanner.py` in your vault.
2. Copy `scarry-prompt.md` to `03-projects/ml-brainclone/prompts/scarry-prompt.md`.
3. Create the state file on first run (Scarry initializes it automatically if missing):

```json
{
  "last_scan": null,
  "items": [],
  "dismissed": [],
  "parked": [],
  "actioned": []
}
```

4. Configure Darry to trigger Scarry during the night shift (see Darry setup docs).

---

## Quick Start

```bash
# Run Scarry manually (full scan)
python 03-projects/scarry/scarry_scanner.py

# Run with a specific scope
python 03-projects/scarry/scarry_scanner.py --scope health,finance

# Check last scan results
python 03-projects/scarry/scarry_scanner.py --last-report
```

Scarry does not need a startup script or Task Scheduler entry — it is triggered by Darry or Larry, not run as a daemon.

---

## State File

**Path:** `_private/scarry-state.json`

This file is privacy L3 — do not commit it to a public repo.

### Item schema

```json
{
  "id": "scarry-001",
  "category": "health",
  "priority": "P3",
  "summary": "Dental checkup — mentioned but never booked",
  "first_mentioned": "2026-02-10",
  "last_mentioned": "2026-03-05",
  "mention_count": 3,
  "status": "open",
  "dismissed_reason": null,
  "tarry_ref": null,
  "sources": [
    "diary:2026-02-10",
    "kg:user:should_do:dental_checkup"
  ]
}
```

### Status lifecycle

```
open → actioned    (user completed the task)
open → parked      (user deliberately parked it)
open → dismissed   (no longer relevant)
open → tarry       (handed off to a Tarry reminder)
```

The `tarry` status is used for handoff: when a user responds to a Scarry nudge with "remind me next Monday", Larry creates a Tarry reminder and links it via `tarry_ref`.

---

## Milla Integration

Scarry depends heavily on the MemPalace semantic memory system:

| Tool | Purpose |
|------|---------|
| `mempalace_kg_query` | Find entities with action-related predicates (`should_do`, `needs_to`, `deadline_is`) |
| `mempalace_diary_read` | Scan diary entries for action-language that was never followed up |
| `mempalace_search` | Semantic search for procrastinated topics across the vault |
| `mempalace_kg_timeline` | Determine *when* something was first and last mentioned |
| `mempalace_traverse` | Follow connections to find related mentions across different notes |

---

## Tarry Cross-check (False-Positive Filter)

Scarry and Tarry are complementary, never overlapping:

| Aspect | Tarry | Scarry |
|--------|-------|--------|
| Direction | Forward — watches future events | Backward — scans history |
| Created by | User or Larry, explicitly | Scarry discovers implicitly |
| Trigger | Time (clock strikes) | Pattern (silence = signal) |
| Output | Reminder / notification | Question / nudge |
| Lifecycle | Created -> fired -> done | Found -> asked -> dismissed/parked/actioned |

**Cross-check rule:** If an item has an active Tarry reminder, Scarry skips it entirely. This prevents duplicate nudges and keeps Scarry's output focused on things that have genuinely fallen through the cracks.

**Handoff flow:**
1. Scarry: "That dental checkup from February — still not booked"
2. User: "Book it next week"
3. Larry creates a Tarry reminder: "Book dental checkup" (next Monday)
4. Scarry marks item as `status: "tarry"` with `tarry_ref: "rem-20260423-001"`
5. Item no longer appears in future Scarry reports

---

## Darry Scheduling

Scarry runs as part of Darry's night shift (Deep Sleep phase). Darry triggers it via the brains-bus:

```bash
# Darry triggers a Scarry scan
python 03-projects/ml-brainclone/bus/brains-bus.py post \
    --from darry \
    --to scarry \
    --kind scarry-run \
    --payload '{"scope":"full","depth":"standard"}'
```

Scarry posts results back for inclusion in the morning brief:

```bash
# Scarry returns results to Darry
python 03-projects/ml-brainclone/bus/brains-bus.py post \
    --from scarry \
    --to darry \
    --kind scarry-input \
    --payload '{"items":[],"summary":"2 P0, 1 P1, 3 P2"}'
```

---

## Bus Integration

Scarry communicates via the brains-bus (brain name: `scarry`).

| Direction | Kind | Payload |
|-----------|------|---------|
| Darry -> scarry | `scarry-run` | `{scope, depth}` — trigger a scan |
| Scarry -> darry | `scarry-input` | `{items[], summary}` — results for morning brief |
| Scarry -> carry | `carry-deliver` | `{destination: "telegram", items: P0[]}` — urgent delivery |
| Larry -> scarry | `scarry-run` | `{scope: "full"}` — on-demand scan |
| Scarry -> larry | `scarry-result` | `{report_path, p0_count, total}` — scan complete |
| User -> scarry | `scarry-dismiss` | `{item_id, reason}` — close item permanently |
| User -> scarry | `scarry-park` | `{item_id}` — park intentionally |

---

## Privacy Considerations

Scarry scans sensitive domains (health, finance, relationships). Key rules:

- Scarry state file lives in `_private/` (privacy L3)
- Output reports containing L3/L4 references must be tagged `privacy: 3`
- Scarry must never expose L4 material in plain text — reference the note path, not the content
- Telegram delivery of P0 items passes through Parry's privacy filter before sending
- The Parry gatekeeper audits every Scarry report before it reaches the user

---

## File Placement

```
03-projects/
├── scarry/
│   └── scarry_scanner.py          <- Scanner script
├── ml-brainclone/
│   ├── prompts/
│   │   └── scarry-prompt.md       <- Prompt template for formulation step
│   └── notifications/
│       └── scarry.log             <- Run log
├── _private/
│   └── scarry-state.json          <- Persistent state (L3)
└── 00-inbox/
    └── nattrapport-scarry-*.md    <- Output reports
```

---

## See Also

- [tarry-setup.md](tarry-setup.md) — Tarry daemon (forward-looking complement)
- [parry-setup.md](parry-setup.md) — Parry gatekeeper (privacy audit for Scarry output)
- [brains-bus-setup.md](brains-bus-setup.md) — Inter-agent event bus
- [mempalace-setup.md](mempalace-setup.md) — Milla semantic memory (Scarry's primary data source)
- [architecture-overview.md](architecture-overview.md) — Agent ecosystem overview
