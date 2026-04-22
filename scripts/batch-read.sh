#!/bin/bash
# batch-read.sh — headless bulk paper-card generation.
#
# For each *.md under raw/md/ that does not yet have a matching card in
# wiki/papers/, run a one-shot `claude -p` invocation that follows the
# CLAUDE.md 新增论文流程 (stages A/B/C).
#
# Each invocation gets a fresh Claude context, so context does not bloat
# even for hundreds of papers. Concept consolidation is intentionally
# deferred to the 校验维护流程 — no per-paper ambiguity flagging here.
#
# Usage:
#   ./scripts/batch-read.sh                # reads all unread papers in raw/md/
#   ./scripts/batch-read.sh /some/md/dir   # reads unread papers in a custom dir

set -u

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
MD_DIR="${1:-$ROOT/raw/md}"
LOG="$ROOT/batch-read.log"

# Claude Code resolves CLAUDE.md from CWD upward — make sure we are at repo root.
cd "$ROOT"

if ! command -v claude >/dev/null 2>&1; then
    echo "ERROR: 'claude' CLI not found on PATH. Install Claude Code first." >&2
    exit 1
fi

if [ ! -d "$MD_DIR" ]; then
    echo "ERROR: md directory not found: $MD_DIR" >&2
    exit 1
fi

echo "=== Batch read started: $(date) ===" | tee -a "$LOG"
echo "    MD dir:     $MD_DIR" | tee -a "$LOG"
echo "    Cards dir:  $ROOT/wiki/papers" | tee -a "$LOG"
echo "" | tee -a "$LOG"

total=0; ok=0; fail=0; skip=0

for md in "$MD_DIR"/*.md; do
    [ -f "$md" ] || continue
    name=$(basename "$md" .md)
    total=$((total + 1))

    if [ -f "$ROOT/wiki/papers/$name.md" ]; then
        echo "[$total] SKIP $name" | tee -a "$LOG"
        skip=$((skip + 1))
        continue
    fi

    echo "[$total] PROCESSING $name ..." | tee -a "$LOG"

    result=$(claude -p "精读 raw/md/$name.md（fallback 模式，不走 NotebookLM）。按 CLAUDE.md 新增论文流程的阶段 A/B/C 生成 wiki/papers/$name.md。完成后只在 stdout 输出一行：DONE 或 FAIL: <原因>。" 2>>"$LOG" | tail -1)

    echo "  -> $result" | tee -a "$LOG"
    case "$result" in
        DONE*) ok=$((ok + 1)) ;;
        *)     fail=$((fail + 1)) ;;
    esac
done

echo "" | tee -a "$LOG"
echo "=== Batch read finished: $(date) ===" | tee -a "$LOG"
echo "Total: $total  |  OK: $ok  |  FAIL: $fail  |  SKIP: $skip" | tee -a "$LOG"
echo "" | tee -a "$LOG"
echo "Next step: in Claude Code, run the 校验维护流程 to dedupe concepts" | tee -a "$LOG"
echo "           and resolve alias conflicts across the new batch." | tee -a "$LOG"

# Exit non-zero if anything failed, so CI / wrapping scripts notice.
[ "$fail" -eq 0 ]
