#!/bin/bash
# install-skills.sh — deploy first-party skills + upstream skills + CLI tools.
# Idempotent; safe to re-run.
#
# Source of truth for what gets installed: skills.lock.yaml
# (This script hardcodes the install logic rather than parsing YAML, to avoid
#  a dependency on a YAML parser at bootstrap time.)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$CLAUDE_SKILLS_DIR"

# --- [1/4] first-party skills ---------------------------------------------
echo "--- [1/4] first-party skills -> $CLAUDE_SKILLS_DIR ---"
for skill in paper-report paper-idea paper-experiment; do
    src="$REPO_ROOT/skills/$skill"
    dst="$CLAUDE_SKILLS_DIR/$skill"
    if [ ! -d "$src" ]; then
        echo "  SKIP: $skill (not found at $src)"
        continue
    fi
    if [ -e "$dst" ]; then
        backup="${dst}.bak.$(date +%s)"
        echo "  BACKUP existing -> $backup"
        mv "$dst" "$backup"
    fi
    cp -r "$src" "$dst"
    echo "  OK:   $skill"
done

# --- [2/4] endnote-cli ----------------------------------------------------
echo ""
echo "--- [2/4] endnote-cli (pip) ---"
if command -v endnote-cli >/dev/null 2>&1; then
    echo "  already installed"
else
    pip install "endnote-cli[all]" || \
        echo "  WARN: endnote-cli install failed — install manually with: pip install 'endnote-cli[all]'"
fi

# --- [3/4] notebooklm Claude skill (ships with the pip package) -----------
echo ""
echo "--- [3/4] notebooklm skill ---"
if command -v notebooklm >/dev/null 2>&1; then
    if [ -e "$CLAUDE_SKILLS_DIR/notebooklm" ]; then
        echo "  already installed"
    else
        echo "  running: notebooklm skill install"
        notebooklm skill install || \
            echo "  WARN: 'notebooklm skill install' failed — run manually after login"
    fi
else
    echo "  notebooklm CLI not found on PATH."
    echo "  After setup.sh installs notebooklm-py, run:"
    echo "    notebooklm skill install"
fi

# --- [4/4] obsidian-skills bundle (kepano/obsidian-skills) ----------------
echo ""
echo "--- [4/4] obsidian-skills bundle (kepano/obsidian-skills) ---"
if [ -d "$CLAUDE_SKILLS_DIR/obsidian-cli" ] && [ -d "$CLAUDE_SKILLS_DIR/obsidian-markdown" ]; then
    echo "  already installed (obsidian-cli + obsidian-markdown present)"
else
    if command -v npx >/dev/null 2>&1; then
        echo "  trying: npx --yes skills add git@github.com:kepano/obsidian-skills.git"
        if npx --yes skills add git@github.com:kepano/obsidian-skills.git 2>/dev/null; then
            echo "  OK via npx skills"
        else
            echo "  npx skills failed — falling back to git clone"
            tmp="$HOME/.claude/skills/_obsidian-skills-tmp"
            rm -rf "$tmp"
            git clone --depth 1 https://github.com/kepano/obsidian-skills.git "$tmp"
            for sub in obsidian-cli obsidian-markdown obsidian-bases defuddle json-canvas; do
                if [ -d "$tmp/$sub" ]; then
                    if [ -e "$CLAUDE_SKILLS_DIR/$sub" ]; then
                        mv "$CLAUDE_SKILLS_DIR/$sub" "$CLAUDE_SKILLS_DIR/$sub.bak.$(date +%s)"
                    fi
                    cp -r "$tmp/$sub" "$CLAUDE_SKILLS_DIR/"
                    echo "  OK:   $sub"
                fi
            done
            rm -rf "$tmp"
        fi
    else
        echo "  SKIP: npx not available. Install Node.js 22+ and re-run."
    fi
fi

echo ""
echo "=== install-skills.sh complete ==="
echo "Skills under $CLAUDE_SKILLS_DIR:"
ls -1 "$CLAUDE_SKILLS_DIR" 2>/dev/null | sed 's/^/  /'
