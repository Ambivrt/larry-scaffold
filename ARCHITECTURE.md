# Architecture

## Overview

The system is a personal knowledge vault (Obsidian) with an AI assistant (Claude Code) that has direct file access. No cloud APIs between you and your notes. No intermediary services. The AI reads and writes your files directly.

```
                    ┌─────────────────┐
                    │   Git (GitHub)  │
                    │   private repo  │
                    └───┬─────────┬──┘
                        │         │
               ┌────────┘         └────────┐
               ▼                           ▼
          ┌──────────┐              ┌──────────┐
          │ Primary  │              │  Other   │
          │ Machine  │              │ Machine  │
          └────┬─────┘              └──────────┘
               │
      ┌────────┤
      ▼        ▼
 ┌─────────┐ ┌────────┐
 │Claude   │ │Obsidian│
 │Code     │ │CLI     │
 └─────────┘ └────────┘
```

Your primary machine runs Claude Code directly in the vault. Additional machines can clone and sync via Git. No cloud drive needed.

---

## Tri-Modal Architecture

Three modes. One brain. Specialized per modality.

| Mode | Modality | Role |
|------|----------|------|
| **Text** | Text | Orchestrator. Thinks, writes, codes, plans, remembers. The main brain. |
| **Image** | Vision | Sees, creates, remembers visually. Input (camera/analysis) and output (generation). |
| **Audio** | Sound | Hears, speaks, creates music/audio. Voice in, voice out, TTS, transcription, composition. |

All three modes handle all four privacy levels. All three have access to the freedom router.

### Orchestration Model

Text mode is the orchestrator. Image and Audio are invoked when the task requires it.

```
YOU
 │
 ▼
TEXT MODE (primary)
 │
 ├─ Text task? → Handles directly
 │
 ├─ Image task? → Invokes IMAGE MODE
 │   ├─ "Analyze this image" → Vision
 │   ├─ "Create a diagram" → Generation
 │   └─ "What do you see?" → Vision
 │
 ├─ Audio task? → Invokes AUDIO MODE
 │   ├─ "Transcribe this" → STT
 │   ├─ "Read this aloud" → TTS
 │   └─ "Create a jingle" → Music
 │
 └─ Multi-modal? → Orchestrates sequence
     └─ "Photograph the whiteboard, transcribe,
         summarize, and read aloud" →
         Image (capture→analysis) → Text (summary) → Audio (TTS)
```

You can also go directly to Image or Audio mode without Text orchestrating — but Text always has context of what happened.

---

## Freedom Router

The router solves one question: the primary model said no — who says yes?

```
REQUEST
  │
  ▼
┌─────────────────────────────┐
│  1. Try primary model       │
│     (best available)        │
│                             │
│     Text: Claude            │
│     Image: Claude Vision    │
│     Audio: Gemini TTS       │
└─────────────┬───────────────┘
              │
         Delivers?
        ╱         ╲
      Yes           No (guardrails/limitation)
      │              │
      ▼              ▼
   DONE      ┌──────────────────┐
             │  2. Route to     │
             │     freer model  │
             │                  │
             │  E.g., Venice,   │
             │  local model,    │
             │  uncensored API  │
             └────────┬─────────┘
                      │
                   Delivers?
                  ╱         ╲
                Yes           No
                │              │
                ▼              ▼
             DONE        Flag: "No model
                          delivered"
```

### What the router does

- Detects guardrail refusals from the primary model
- Routes to the next model in the fallback chain
- Logs: which model refused, which delivered, why (if detectable)
- Flags when no model delivers

### What the router does NOT do

- **Does NOT route based on privacy level.** Privacy level determines which models are *allowed* — that's your configuration, not the router's decision.
- **Does NOT route based on cost.** Best model first, always.
- **Does NOT censor.** If the primary model refuses, it routes onward. It doesn't judge why.

---

## Model Configuration per Mode

Customize these to your preferences and available accounts.

### Text mode

| Priority | Model | Strength | Limitation |
|----------|-------|----------|------------|
| **Primary** | Claude (Opus/Sonnet) | Best at reasoning, code, context | Guardrails on some content |
| **Fallback 1** | Venice (DeepSeek/Qwen, E2EE) | Freer, end-to-end encrypted | Weaker on complex code |
| **Fallback 2** | Local (Ollama/LM Studio) | Zero footprint, fully offline | Resource-heavy, lower quality |

### Image mode

| Priority | Model | Strength | Limitation |
|----------|-------|----------|------------|
| **Primary — Analysis** | Claude Vision | Best image understanding, OCR | Guardrails on some content |
| **Primary — Generation** | Venice Studio (Chroma) | Free tier, good quality | Browser-based (Playwright) |
| **Fallback — Generation** | Venice API (Flux/others) | More models available | Credits required |

### Audio mode

| Priority | Model | Strength | Limitation |
|----------|-------|----------|------------|
| **Primary — TTS** | Gemini TTS (Vertex AI) | 30 voices, emotion tags, free tier | Requires GCP account |
| **Primary — STT** | Whisper (OpenAI) | Best transcription | Logging |
| **Fallback — TTS** | Local TTS (Coqui) | Private | Less natural |
| **Fallback — STT** | Local Whisper | Private | Lower quality |

---

## Privacy Levels — Allowed Models

You configure which models are *allowed* per privacy level. The router picks the best one within the allowed pool.

| Level | Description | Suggested model policy |
|-------|-------------|----------------------|
| **L1 — Open** | Public info, work content | All models |
| **L2 — Personal** | Private but not sensitive | All models |
| **L3 — Private** | Sensitive: health, finance, relationships | E2EE models preferred (e.g., Venice) |
| **L4 — Subconscious** | Deeply personal, AI observations | E2EE models or local only |

See [docs/privacy-architecture.md](docs/privacy-architecture.md) for the full privacy model.

---

## Sync Architecture

| Layer | Purpose | Direction |
|-------|---------|-----------|
| **Git (GitHub)** | Vault sync between machines | Push/pull |
| **Obsidian CLI** | Programmatic vault access from terminal | Local (requires Obsidian running) |
| **Claude Code** | AI-powered vault access (primary interface) | Local or remote |

### Access Methods

| Method | Capabilities | When to use |
|--------|-------------|------------|
| **Claude Code (local)** | Full: read, write, agents, memory, skills | Primary daily use |
| **Claude Code (remote)** | Full: same as local, via SSH/remote session | Away from primary machine |
| **Obsidian app** | Read, write, graph view, search | Visual browsing, graph exploration |
| **Obsidian CLI** | Search, create, daily notes | Quick captures from terminal |
| **Git client (mobile)** | Read, basic edit | On the go (Working Copy, etc.) |

---

## Vault Structure

```
00-inbox/          — Brain dumps, quick thoughts, unprocessed
01-personal/       — Profile, interests, goals, health
02-work/           — Job, clients, deliverables
03-projects/       — Active projects with status and deadlines
04-knowledge/      — Research, articles, insights, tutorials
05-templates/      — Note templates (project, meeting, research, daily)
06-archive/        — Completed material, inactive projects
_private/          — Privacy level 3-4 (sensitive and deeply personal)
```

### Special Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Vault rules, structure, conventions — read by Claude Code |
| `_active-context.md` | Working memory between sessions — read at session start |

---

## Vault Visualization — Obsidian Bases

`.base` files in `_bases/` create live database views on top of vault frontmatter. Built into Obsidian v1.9.10+. No plugin required. Faster than Dataview.

```
_bases/
├── projects-active.base    ← Active projects (filtered, table + card view)
├── inbox-triage.base       ← Inbox triage, sorted by date
└── knowledge-base.base     ← Research and insights
```

Bases query YAML frontmatter directly. As long as notes have `status`, `tags`, `created`, etc., views stay current automatically.

**Relationship to the AI layer:** Bases answer structured questions ("show all active projects"). The AI answers semantic questions ("what connects these projects?"). Complementary, not redundant.

See [docs/obsidian-bases.md](docs/obsidian-bases.md) for full syntax reference.

---

## Design Principles

1. **Primary model first, always.** Best available model. Fallback only on refusal.
2. **Privacy is configuration, not routing.** You decide which models are allowed. The router doesn't.
3. **Text orchestrates.** Image and Audio act on Text's request or your direct input. Text always has context.
4. **Freedom over moral panic.** If a model refuses, route onward. Never censor your own thoughts.
5. **Zero footprint as an option.** Always possible to run fully local/private. Not the default, but available.
6. **Text-only vault.** No binary files stored in the vault. Reference external paths for media.
7. **Git is the source of truth.** No cloud drives. Git push/pull between machines.
