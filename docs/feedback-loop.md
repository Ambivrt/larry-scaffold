# Feedback Loop — Automated Mistake Detection

A nightly batch that turns accumulated user corrections into a prioritized, living "don't repeat this" list injected at session start.

Inspired by Dave Killeen's Dex pattern (mistakes.md injected via hooks), adapted for a multi-agent vault architecture with existing feedback memory infrastructure.

---

## Problem

Over time, your system accumulates hundreds of feedback memories (user corrections, style preferences, workflow rules). They all live in flat memory files with equal weight. Session init loads them all — but a feedback rule created two months ago about date formatting has the same priority as a critical privacy rule created yesterday.

Without prioritization, the most important rules get buried. Without automated detection, the same mistakes recur because the feedback loop is purely reactive (user corrects → memory saved).

---

## Architecture

Three components. No new daemons.

```
┌──────────────────────────────────────────────────────────┐
│                    NIGHTLY BATCH                          │
│                                                          │
│  1. Python collector reads feedback/* files               │
│     → .data/feedback-items.txt (condensed)               │
│                                                          │
│  2. Python collector reads recent nattrapport-*.md       │
│     → .data/recent-nattrapporter.txt                     │
│                                                          │
│  3. Claude batch cross-references rules vs. reports      │
│     → Detects violations, categorizes, scores severity   │
│     → Updates _private/feedback-tracker.json             │
│     → Writes 00-inbox/nattrapport-feedback-audit.md      │
│                                                          │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│                   SESSION INIT                            │
│                                                          │
│  Step 2e: Read HOT 10 from nattrapport-feedback-audit.md │
│  → Prioritized rules active in working memory            │
│  → Silent report: "(Feedback: N hot, M broken)"         │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Component 1 — Collector (Python)

`feedback-audit-collect.py` runs before the Claude batch. It:

- Reads all `memory/feedback/*.md` files
- Parses frontmatter (name, description, type) and first paragraph
- Loads or initializes `_private/feedback-tracker.json`
- Registers new items in the tracker (severity/category filled by Claude later)
- Collects nattrapport files from last 3 days
- Writes condensed `.data/` files for Claude consumption

This keeps the Claude batch focused on analysis, not file-system traversal.

### Component 2 — Claude Batch (Nattskift Prompt)

The batch prompt reads the pre-collected data and:

**Cross-references:** For each feedback rule, scans nattrapport text for violation signals. Example: feedback says "always use GWS CLI for mail" + nattrapport shows MCP mail calls → violation detected.

**Categorizes** each rule:
- `communication` — tone, language, style
- `technical` — tools, APIs, infrastructure
- `privacy` — data layers, access control
- `workflow` — process, ordering, priorities
- `identity` — persona, creative ownership, relationships

**Scores severity** (1-3):
- 3 = Direct harm (privacy leak, wrong external communication, data loss)
- 2 = Time waste or irritation (wrong tool, bad tone, unnecessary questions)
- 1 = Style preference (spelling, formatting, word choice)

**Updates tracker:** Bumps `trigger_count` for violated rules, timestamps `last_seen`.

**Generates report** with four sections:
- **HOT 10** — Top 10 rules by severity DESC, trigger_count DESC
- **BROKEN** — Rules violated in recent nattrapport evidence
- **CANDIDATES** — New patterns not yet formalized as feedback rules
- **STALE** — Rules referencing obsolete tools, duplicating others, or never triggered

### Component 3 — Feedback Tracker (JSON)

`_private/feedback-tracker.json` — persistent state across nightly runs:

```json
{
  "version": 1,
  "last_audit": "2026-05-05",
  "items": {
    "feedback_no_cigars": {
      "severity": 1,
      "trigger_count": 0,
      "last_seen": "",
      "category": "identity"
    },
    "feedback_privacy_awareness": {
      "severity": 3,
      "trigger_count": 2,
      "last_seen": "2026-05-04",
      "category": "privacy"
    }
  }
}
```

---

## Scheduling

Runs after KG hygiene, before morning brief:

| Batch | Time | Purpose |
|-------|------|---------|
| ... | 04:00 | KG hygiene |
| **Feedback audit** | **04:30** | **Cross-reference + prioritize** |
| Morning brief | 06:00 | Summary (can reference audit) |

In the `all` sequence of the nightly runner:
1. Python collector runs first (fast, <10s)
2. Claude batch runs second (analysis, ~2-5 min)

---

## Session Init Integration

Add to your CLAUDE.md session init sequence:

```markdown
### Step 2e — Hot mistakes
If `00-inbox/nattrapport-feedback-audit.md` exists: read the HOT 10 section.
These are the prioritized feedback rules — keep them active in working memory.
Report silently: `(Feedback: N hot, M broken)`.
```

---

## Scaling

The collector handles 150+ feedback files in <1 second. The Claude batch processes the condensed summary, not raw files. Cost is one Haiku/Sonnet call per night (~$0.01-0.05).

As feedback files grow beyond 200, the STALE section becomes increasingly valuable — it identifies rules to merge or archive, keeping the active set manageable.
