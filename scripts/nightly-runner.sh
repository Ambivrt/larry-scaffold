#!/bin/bash
# =============================================================================
# Larry Nightly — Batch Runner
# =============================================================================
# Runs nightly batch jobs: bash script collects data, Claude CLI writes reports.
# Triggered by Windows Task Scheduler or manually.
#
# Usage:
#   ./nightly-runner.sh [batch-number]
#   ./nightly-runner.sh 1        # Batch 1 (vault hygiene)
#   ./nightly-runner.sh 2        # Batch 2 (inbox triage)
#   ./nightly-runner.sh 3        # Batch 3 (morning brief)
#   ./nightly-runner.sh 5        # Batch 5 (distillation)
#   ./nightly-runner.sh 6        # Batch 6 (KG hygiene)
#   ./nightly-runner.sh all      # All batches in sequence
#   ./nightly-runner.sh          # Default: all
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# PATH hardening (defense-in-depth)
# -----------------------------------------------------------------------------
# Task Scheduler runs bash --login. If profile loading fails or the env is
# stripped — make sure all binaries we call are still found.
#
# CRITICAL: On Windows, WindowsApps contains a WSL bash shim that hijacks
# `bash` calls. Git Bash's /usr/bin MUST come first. WindowsApps removed.
export PATH="/usr/bin:$HOME/.local/bin:/c/Program Files/nodejs:/c/Program Files/Git/bin:$PATH"
export PYTHONIOENCODING=utf-8

# Model — read from config, never hardcoded
MODEL="${LARRY_MODEL:-claude-sonnet-4-6}"

VAULT="${VAULT_PATH:?VAULT_PATH must be set}"
NATTSKIFT_DIR="$VAULT/03-projects/ml-brainclone/operations/nattskift"
PROMPT_DIR="$NATTSKIFT_DIR/prompts"
LOG_DIR="$NATTSKIFT_DIR/logs"
TODAY=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)

mkdir -p "$LOG_DIR"

LOGFILE="$LOG_DIR/nightly-$TIMESTAMP.log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOGFILE"
}

run_batch() {
    local batch_num="$1"
    local batch_name="$2"
    local prompt_file="$PROMPT_DIR/$3"

    if [ ! -f "$prompt_file" ]; then
        log "ERROR: Prompt file missing: $prompt_file"
        return 1
    fi

    log "=== Starting Batch $batch_num: $batch_name ==="

    local prompt_content
    prompt_content=$(cat "$prompt_file")

    # Run Claude CLI in print mode (non-interactive)
    # Prompt piped via stdin (not as argument — avoids --option parsing)
    if echo "$prompt_content" | claude --print \
        --dangerously-skip-permissions \
        --model "$MODEL" \
        --max-turns 30 \
        >> "$LOGFILE" 2>&1; then
        log "=== Batch $batch_num DONE ==="
    else
        local exit_code=$?
        log "=== Batch $batch_num FAILED (exit code: $exit_code) ==="
        return 1
    fi
}

# =============================================================================
# Main logic
# =============================================================================

BATCH="${1:-all}"

log "====================================================="
log "Larry Nightly — $TODAY"
log "Batch: $BATCH"
log "====================================================="

# Step 0: Semantic memory — incremental indexing (new/changed files)
# Timeout 300s (5 min) — prevents a hung database operation from killing
# the entire batch.
#
# CRITICAL: Kill the MCP singleton before mine. The singleton holds
# ChromaDB's HNSW index open via PersistentClient. Without killing it,
# mine deadlocks on the exclusive lock. The singleton restarts
# automatically on the next MCP call.
log "--- Step 0: Memory indexing (incremental) ---"
SINGLETON_PIDS=$(pgrep -f "mempalace-singleton" 2>/dev/null || true)
if [ -n "$SINGLETON_PIDS" ]; then
    log "--- Killing mempalace-singleton (pids: $SINGLETON_PIDS) for DB access ---"
    echo "$SINGLETON_PIDS" | xargs kill 2>/dev/null || true
    sleep 2
fi
if timeout 300 python3 -m mempalace mine "$VAULT" >> "$LOGFILE" 2>&1; then
    log "--- Memory indexing done ---"
else
    log "--- Memory indexing FAILED (continuing anyway) ---"
fi

# Step 0b: Palace hygiene — clean stale + duplicate drawers
log "--- Step 0b: Palace hygiene (stale + dedup) ---"
if [ -f "$NATTSKIFT_DIR/palace-hygiene.py" ]; then
    if timeout 300 python3 "$NATTSKIFT_DIR/palace-hygiene.py" >> "$LOGFILE" 2>&1; then
        log "--- Palace hygiene done ---"
    else
        log "--- Palace hygiene FAILED (continuing anyway) ---"
    fi
fi

# Step 0c: FTS5 rebuild — full-text search index
log "--- Step 0c: FTS5 rebuild ---"
FTS5_SCRIPT="$VAULT/03-projects/ml-brainclone/search/vault_fts5_build.py"
if [ -f "$FTS5_SCRIPT" ]; then
    if timeout 120 python3 "$FTS5_SCRIPT" >> "$LOGFILE" 2>&1; then
        log "--- FTS5 rebuild done ---"
    else
        log "--- FTS5 rebuild FAILED (continuing anyway) ---"
    fi
fi

# Step 1: Collect vault data (always, for all batches)
log "--- Step 1: Collecting vault data ---"
if bash "$NATTSKIFT_DIR/collect-vault-data.sh" >> "$LOGFILE" 2>&1; then
    log "--- Data collection done ---"
else
    log "--- Data collection FAILED ---"
    # Continue anyway if possible
fi

# Step 2: Run batch jobs via Claude CLI
case "$BATCH" in
    1)
        run_batch 1 "Vault hygiene" "batch1-vault-hygiene.md"
        ;;
    2)
        run_batch 2 "Inbox triage" "batch2-inbox-triage.md"
        ;;
    3)
        run_batch 3 "Morning brief" "batch3-morning-brief.md"
        ;;
    5)
        run_batch 5 "Distillation" "batch5-distillation.md"
        ;;
    6)
        run_batch 6 "KG hygiene" "batch6-kg-hygiene.md"
        ;;
    all|"")
        log "Running all batches in sequence..."
        run_batch 1 "Vault hygiene" "batch1-vault-hygiene.md" || true
        run_batch 2 "Inbox triage" "batch2-inbox-triage.md" || true
        # Distillation after inbox triage (needs triage data)
        run_batch 5 "Distillation" "batch5-distillation.md" || true
        # KG hygiene after distillation — sees the full night's picture
        run_batch 6 "KG hygiene" "batch6-kg-hygiene.md" || true
        # Morning brief last (summarizes everything)
        run_batch 3 "Morning brief" "batch3-morning-brief.md" || true
        ;;
    *)
        log "Unknown batch number: $BATCH"
        log "Usage: $0 [1|2|3|5|6|all]"
        exit 1
        ;;
esac

log "====================================================="
log "Nightly run complete — $(date +%H:%M:%S)"
log "Logfile: $LOGFILE"
log "====================================================="
