#!/bin/bash
# =============================================================================
# Larry Session Init Hook — load-context.sh
# =============================================================================
# Runs on SessionStart. Reads active context, Barry counter, and agent status.
# Configure in ~/.claude/settings.json under hooks.SessionStart.
# =============================================================================

VAULT="${VAULT_PATH:-.}"

echo "--- Active Context ---"
cat "$VAULT/_active-context.md" 2>/dev/null || echo "(no _active-context.md found)"

echo ""
echo "--- Barry Counter ---"
if [ -f "${ASSETS_PATH:-.}/.counter" ]; then
    echo "Barry image counter: $(cat "${ASSETS_PATH}/.counter")"
else
    echo "Barry counter not found (Barry not configured)"
fi

echo ""
echo "--- Harry Status ---"
cat "$VAULT/03-projects/harry/harry.md" 2>/dev/null || echo "(Harry not configured)"

echo ""
echo "--- Barry Status ---"
cat "$VAULT/03-projects/barry/barry.md" 2>/dev/null || echo "(Barry not configured)"
