#!/bin/bash
# check-env.sh — report whether each dependency is installed and reachable.
# Exit 0 if all required deps present; 1 otherwise.

missing_required=0

check() {
    local name="$1"
    local cmd="$2"
    local required="$3"           # "required" | "optional"
    local version_flag="${4:---version}"
    if command -v "$cmd" >/dev/null 2>&1; then
        local ver
        ver=$("$cmd" "$version_flag" 2>&1 | head -1 | tr -d '\r' | cut -c1-80)
        printf "  [OK] %-20s %s\n" "$name" "$ver"
    else
        if [ "$required" = "required" ]; then
            printf "  [--] %-20s (REQUIRED — missing)\n" "$name"
            missing_required=$((missing_required + 1))
        else
            printf "  [  ] %-20s (optional — missing)\n" "$name"
        fi
    fi
}

check_skill() {
    local name="$1"
    local required="$2"
    if [ -e "$HOME/.claude/skills/$name" ]; then
        printf "  [OK] %-20s\n" "$name"
    else
        if [ "$required" = "required" ]; then
            printf "  [--] %-20s (REQUIRED — missing)\n" "$name"
            missing_required=$((missing_required + 1))
        else
            printf "  [  ] %-20s (optional — missing)\n" "$name"
        fi
    fi
}

echo "=============================================="
echo "paper-wiki-starter — environment check"
echo "=============================================="
echo ""

echo "Core runtimes:"
check "git"          git         required
check "conda"        conda       required
check "node"         node        required
check "npm"          npm         required
check "python"       python      required
echo ""

echo "CLI tools:"
check "qmd"          qmd         required
check "notebooklm"   notebooklm  required
check "endnote-cli"  endnote-cli optional
check "defuddle"     defuddle    optional
check "ollama"       ollama      optional
echo ""

echo "Claude skills (~/.claude/skills/):"
check_skill paper-report        required
check_skill paper-idea          required
check_skill paper-experiment    required
check_skill notebooklm          required
check_skill obsidian-cli        required
check_skill obsidian-markdown   optional
check_skill defuddle            optional
echo ""

echo "Conda envs:"
if command -v conda >/dev/null 2>&1; then
    if conda env list 2>/dev/null | awk '{print $1}' | grep -qx "mineru"; then
        echo "  [OK] mineru env present"
    else
        echo "  [--] mineru env missing (run setup.sh)"
        missing_required=$((missing_required + 1))
    fi
fi
echo ""

if [ "$missing_required" -gt 0 ]; then
    echo "FAIL: $missing_required required item(s) missing."
    echo "      Run: ./scripts/bootstrap.sh"
    exit 1
fi
echo "OK: all required dependencies present."
