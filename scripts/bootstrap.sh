#!/bin/bash
# bootstrap.sh — one-shot deploy entry for paper-wiki-starter.
#
# Runs, in order:
#   1. setup.sh              (conda env + mineru + qmd + Ollama + notebooklm)
#   2. scripts/install-skills.sh
#   3. scripts/check-env.sh
#
# Usage: ./scripts/bootstrap.sh
# Safe to re-run — each step is idempotent.

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "=============================================="
echo "paper-wiki-starter — bootstrap"
echo "Repo root: $REPO_ROOT"
echo "=============================================="

cd "$REPO_ROOT"

# --- Prerequisite binaries
for cmd in git conda node npm python; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: required prerequisite '$cmd' not found on PATH."
        echo "Install it first, then re-run this script."
        exit 1
    fi
done

# --- Step 1: environment (MinerU, qmd, Ollama, notebooklm via pip)
if [ -x "./setup.sh" ]; then
    echo ""
    echo ">>> Step 1/3: running setup.sh"
    ./setup.sh
else
    echo "ERROR: ./setup.sh not found or not executable."
    exit 1
fi

# --- Step 2: Claude skills + endnote-cli + obsidian-skills
echo ""
echo ">>> Step 2/3: installing Claude Code skills"
./scripts/install-skills.sh

# --- Step 3: status report
echo ""
echo ">>> Step 3/3: environment status check"
./scripts/check-env.sh || true

echo ""
echo "=============================================="
echo "Bootstrap complete. Manual follow-ups:"
echo "  1. notebooklm login             (Google OAuth)"
echo "  2. Install Obsidian (https://obsidian.md/) and open wiki/ as a vault"
echo "  3. (optional) Install EndNote if using the new-paper metadata flow"
echo "  4. Drop PDFs into raw/pdf/ and run: ./add-paper.sh"
echo "  5. Start Claude Code from this directory: claude"
echo "=============================================="
