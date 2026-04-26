# Carry Setup — Logistics Daemon

Carry is Larry's logistics daemon. It handles all content transport — inbound, outbound, and internal — so that Larry never has to move files manually between sessions.

- **Larry** — thinks, plans, orchestrates
- **Barry** — sees (images)
- **Harry** — hears and speaks (audio)
- **Parry** — guards, filters, judges
- **Tarry** — remembers when
- **Farry** — understands all languages
- **Carry** — moves content from A to B

---

## What Carry Does

| Domain | Function |
|--------|----------|
| Inbound | Fetches external content (email attachments, RSS, scraped pages) and delivers it to the vault |
| Outbound | Publishes approved content to external channels (social media, email, file delivery) |
| Internal | Sorts inboxes, moves files to correct directories, syncs backups, cleans up temp files |
| Pipelines | Runs multi-step content chains end-to-end (generate -> QA -> sort -> backup -> publish) |

Carry does not interpret content — it moves it. Interpretation, decisions, and prioritization belong to Larry. Carry knows *where* things go, not *why*.

---

## Architecture

Carry is a **daemon**, like Parry and Tarry. It runs as a long-lived background process and polls its queue every 30 seconds.

```
carry_service.py (daemon, pythonw)
        |
        | polls every 30s
        v
_private/carry-queue.json
        |
        |--- process_inbound()    Fetch from source -> deliver to vault
        |--- process_outbound()   Approved? -> deliver to external channel
        |--- process_internal()   Sort, move, archive, cleanup
        |--- run_pipelines()      Execute scheduled pipeline chains
        |--- retry_failed()       Retry with exponential backoff (max 3)
        |
        v
brains-bus  ->  Larry receives carry-delivered / carry-failed events
        |
        v
Telegram notification (on failure or approval request)
```

---

## Inbound Pipeline

Carry fetches data from external sources and delivers it to the right place in the vault.

| Source | Destination | Trigger |
|--------|-------------|---------|
| Email attachment | `00-inbox/` or categorized folder | New attachment detected |
| RSS / news feeds | `04-knowledge/` + memory indexing | Scheduled (cron) |
| Telegram media | Asset directory or vault | Photo/document in chat |
| API pull (external) | Vault note with frontmatter | Larry request or schedule |
| Web scrape result | `04-knowledge/` with source metadata | Larry request |

Carry tags every inbound item with source, timestamp, and format — but never interprets the content.

---

## Outbound Pipeline

Carry publishes and distributes content that Larry/Barry/Harry have produced.

| Content | Destination | Flow |
|---------|-------------|------|
| Social media post | LinkedIn / Instagram / X | Larry writes -> user approves -> Carry publishes |
| Newsletter | Email list | Larry writes -> user approves -> Carry sends |
| Morning brief | User's email | Night shift produces -> Carry delivers |
| File delivery | External recipient | Larry creates -> user approves -> Carry delivers |

### Approval Gate

All outbound content passes through user approval before Carry sends it. Carry **never** sends externally without explicit approval.

Exceptions (no approval needed):
- Email to the user's own address
- Telegram messages to the user
- Internal vault operations

Parry monitors all outbound events and flags any that bypass the approval gate.

---

## Internal Logistics

Carry handles all internal file movements within the system.

| From | To | Trigger |
|------|----|---------|
| `00-inbox/` | Categorized vault folder | Continuous inbox triage |
| Image generator inbox | `generated/{sfw}/{category}/` | New image detected |
| Asset directories | NAS / backup drive | Scheduled (e.g. every 15 min) |
| Night shift reports | Actionable tasks in `00-inbox/` | Report produced |
| Replaced files | `.old/` subfolder | Automatic on replacement |
| `_tmp-*` directories | Deleted | Cleanup after delivery confirmed |

---

## Pipeline Chains

Carry owns entire chains, not just individual steps. Each step is logged. A chain can be interrupted and resumed.

### Example: Image Pipeline (end-to-end)

```
1. Larry requests image -> Barry generates -> asset-inbox/image-00001.jpg
2. Carry: QA check (fingers, anatomy) — flag on fail
3. Carry: Upscale (2x default, 4x on request) -> image-00001-2x.jpg
4. Carry: Sort -> generated/{sfw}/{category}/
5. Carry: Delete 1x original (keep only upscaled)
6. Carry: Write metadata note -> vault (visual index)
7. Carry: Index metadata in memory system
8. Carry: Backup sync -> NAS
9. Carry: If publish requested -> resize per channel -> deliver
```

### Example: Report Pipeline

```
1. Night shift produces report -> 00-inbox/report-*.md
2. Carry: Parse report -> extract actionable items
3. Carry: Create task files per item -> 00-inbox/task-larry-*.md
4. Carry: Archive report -> 06-archive/night-shift/YYYY-MM-DD/
5. Carry: Summarize for morning brief -> deliver
```

### Example: Publish Pipeline

```
1. Larry writes post draft -> _tmp/linkedin-draft.md
2. Carry: Format per channel (character limits, image dimensions, hashtags)
3. Carry: If image -> resize to channel specs (e.g. 1200x627, 1080x1080)
4. Carry: Queue for approval -> user sees draft
5. User: "go" -> Carry publishes via Playwright
6. Carry: Archive published version in vault
7. Carry: Delete _tmp/
```

---

## Quick Start

```bash
# Start Carry manually (stays in terminal)
python 03-projects/carry/carry_service.py

# Start Carry in background (Windows)
pythonw 03-projects/carry/carry_service.py

# Check status
python 03-projects/carry/carry_service.py --status
```

---

## Installation

1. Copy `carry_service.py` to `03-projects/carry/carry_service.py` in your vault.
2. Create the queue file on first run (Carry initializes it automatically if missing):

```json
{
  "active_jobs": [],
  "scheduled_pipelines": [],
  "pending_approval": [],
  "completed_today": []
}
```

3. Register the Windows Task Scheduler autostart (see below).

---

## Windows Task Scheduler Autostart

Carry should start automatically when you log in, like Parry and Tarry.

```powershell
# Register Carry as a scheduled task (run once at setup)
powershell -File 03-projects/carry/startup/carry-start.ps1
```

Or register manually:

```powershell
$action = New-ScheduledTaskAction `
    -Execute "pythonw.exe" `
    -Argument "D:\path\to\vault\03-projects\carry\carry_service.py" `
    -WorkingDirectory "D:\path\to\vault"

$trigger = New-ScheduledTaskTrigger -AtLogon

Register-ScheduledTask `
    -TaskName "Larry Carry" `
    -Action $action `
    -Trigger $trigger `
    -RunLevel Highest `
    -Force
```

---

## Queue File

**Path:** `_private/carry-queue.json`

This file is privacy L3 — do not commit it to a public repo.

### Job schema

```json
{
  "id": "carry-20260423-001",
  "type": "inbound",
  "source": "gmail:attachment",
  "destination": "00-inbox/",
  "status": "in_progress",
  "created": "2026-04-23T08:15:00",
  "retry_count": 0,
  "max_retries": 3,
  "pipeline": null
}
```

### Scheduled pipeline schema

```json
{
  "id": "pipe-nas-sync",
  "name": "NAS Asset Sync",
  "cron": "*/15 * * * *",
  "pipeline": ["robocopy_assets"],
  "enabled": true
}
```

### Pending approval schema

```json
{
  "id": "carry-20260423-002",
  "type": "outbound",
  "destination": "linkedin",
  "content_ref": "_tmp/linkedin-draft.md",
  "status": "awaiting_approval",
  "created": "2026-04-23T09:00:00"
}
```

### Status values

| Status | Meaning |
|--------|---------|
| `queued` | Waiting to be processed |
| `in_progress` | Currently executing |
| `awaiting_approval` | Outbound job waiting for user approval |
| `completed` | Successfully delivered |
| `failed` | All retries exhausted — escalated to Larry |

---

## Retry and Escalation

Carry is built for resilience. Transports that fail are retried with exponential backoff:

| Attempt | Delay | Rationale |
|---------|-------|-----------|
| Retry 1 | Immediate | Network glitch, transient error |
| Retry 2 | +5 minutes | Service temporarily down |
| Retry 3 | +30 minutes | Persistent problem |
| Fail | — | Flag in queue, notify Larry + user via bus and Telegram |

After all retries are exhausted, Carry marks the job as `failed` and posts a `carry-failed` event on the brains-bus. Larry picks it up in the next session (or immediately if running).

---

## Bus Integration

Carry communicates via the brains-bus (brain name: `carry`).

### Events Carry receives

```bash
# Request a file delivery
python 03-projects/ml-brainclone/bus/brains-bus.py post \
    --from larry \
    --to carry \
    --kind carry-deliver \
    --payload '{"source":"00-inbox/report.md","destination":"06-archive/reports/","pipeline":null,"approval_required":false}'

# Request a publish action
python 03-projects/ml-brainclone/bus/brains-bus.py post \
    --from larry \
    --to carry \
    --kind carry-publish \
    --payload '{"channel":"linkedin","content_ref":"_tmp/linkedin-draft.md","schedule_at":null}'

# Request a fetch from external source
python 03-projects/ml-brainclone/bus/brains-bus.py post \
    --from larry \
    --to carry \
    --kind carry-fetch \
    --payload '{"url":"https://example.com/data.json","destination":"04-knowledge/","format":"markdown"}'

# Approve a pending outbound job
python 03-projects/ml-brainclone/bus/brains-bus.py post \
    --from user \
    --to carry \
    --kind carry-approve \
    --payload '{"job_id":"carry-20260423-002"}'

# Cancel a pending job
python 03-projects/ml-brainclone/bus/brains-bus.py post \
    --from user \
    --to carry \
    --kind carry-cancel \
    --payload '{"job_id":"carry-20260423-002"}'
```

### Events Carry emits

| Kind | Payload | When |
|------|---------|------|
| `carry-delivered` | `{job_id, source, destination, success}` | Job completed |
| `carry-approval-needed` | `{job_id, channel, content_preview}` | Outbound job queued for approval |
| `carry-failed` | `{job_id, error, retry_count}` | All retries exhausted |

### Batch transport (from night shift)

```bash
python 03-projects/ml-brainclone/bus/brains-bus.py post \
    --from nightshift \
    --to carry \
    --kind carry-batch \
    --payload '{"pipeline":"report-pipeline","items":["report-1.md","report-2.md"]}'
```

---

## Parry Integration

Parry sees all Carry events and enforces safety:

| Event | Parry checks |
|-------|--------------|
| `carry-publish` to external channel | Approval exists, privacy level appropriate for destination |
| `carry-deliver` with high-privacy content | Destination is internal, not external |
| `carry-fetch` from unknown source | Flags security risk |
| All outbound transports | Logged for audit trail |

Parry never blocks Carry directly — it flags, asks, and logs. The user always decides.

---

## Status Check

Carry writes a heartbeat file while running:

```
_private/.notifications/carry-service.heartbeat
```

The heartbeat is updated every 15 seconds. If it goes stale (>2 min), the Task Scheduler restarts the process.

```powershell
# Check Carry heartbeat
powershell -File 03-projects/carry/startup/carry-status.ps1
```

---

## Relation to the Brains-Bus

Carry uses the brains-bus for coordination but transports content outside the bus. The bus carries signals; Carry carries payloads.

| Aspect | Brains-bus (router) | Carry (logistics) |
|--------|--------------------|--------------------|
| Transports | Events (signals) | Content (files, images, text, data) |
| Format | JSON payload < 64KB | Files, images, documents, API calls |
| Latency | 1-4 seconds | Seconds to minutes (pipeline) |
| Direction | Agent <-> agent | System <-> external, internal <-> internal |
| Error handling | Parry blocks | Retry with backoff |
| Persistence | SQLite WAL | Filesystem + queue JSON |

---

## What Carry Absorbs

Carry consolidates several manual operations that previously ran as standalone scripts or required Larry to do by hand:

| Before Carry | With Carry |
|--------------|------------|
| NAS sync via standalone scheduled task | Carry owns the sync, can also trigger on-demand |
| Image sorting run manually by Larry | Carry sorts automatically when new images arrive |
| Inbox triage at session start | Carry triages continuously |
| Social media publishing via Playwright (manual) | Carry publishes after approval |
| Night report action items read manually | Carry extracts tasks automatically |
| Temp file cleanup done ad-hoc | Carry cleans up after every confirmed delivery |

---

## Dispatching Carry Tasks via task_lib

Larry can request a transport by dispatching a task to the `carry` agent:

```python
from scripts.task_lib import create_task

create_task(
    "carry",
    title="Publish LinkedIn draft",
    description='{"channel":"linkedin","content_ref":"_tmp/linkedin-draft.md"}',
    from_source="larry-session",
    priority="normal",
)
```

The `agent_task_watcher` picks this up and appends it to `carry-queue.json`.

---

## Implementation Phases

### Phase 1 — Internal logistics
- Queue data model (`carry-queue.json`)
- Daemon skeleton (`carry_service.py` with poll, heartbeat, PID)
- Image sorting as a pipeline (generate -> QA -> sort)
- NAS sync absorption (scheduled task -> Carry pipeline)
- Inbox triage (continuous sorting of `00-inbox/`)
- Temp cleanup after delivery
- Bus integration (`carry-deliver`, `carry-delivered`)
- Windows Task Scheduler setup

### Phase 2 — Inbound
- Email attachment -> vault import
- Telegram media -> asset directory or vault
- RSS / news feeds -> `04-knowledge/`
- Web scrape pipeline
- Retry and error handling

### Phase 3 — Outbound
- Social media publishing via Playwright (LinkedIn, Instagram, X)
- Approval gate via Telegram (show draft -> "go" / "edit" / "cancel")
- Channel-specific formatting (resize, character limits, hashtags)

### Phase 4 — Pipeline chains
- Image end-to-end pipeline (generate -> QA -> upscale -> sort -> backup -> publish)
- Report pipeline (report -> extract -> tasks -> archive)
- Publish pipeline (draft -> format -> approve -> publish -> archive)
- Pipeline status dashboard for the user

---

## See Also

- [parry-setup.md](parry-setup.md) — Parry daemon (same process model)
- [tarry-setup.md](tarry-setup.md) — Tarry daemon (same process model)
- [barry-setup.md](barry-setup.md) — Barry image agent (Carry handles post-generation logistics)
- [brains-bus-setup.md](brains-bus-setup.md) — Inter-agent event bus
- [task-dispatch.md](task-dispatch.md) — Task queue system
- [architecture-overview.md](architecture-overview.md) — Agent ecosystem overview
