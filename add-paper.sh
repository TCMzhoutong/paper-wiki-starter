#!/bin/bash
# add-paper.sh — Convert PDFs with MinerU and add to paper_md/ for qmd indexing
# Usage:
#   ./add-paper.sh paper.pdf              # single file
#   ./add-paper.sh paper1.pdf paper2.pdf  # multiple files
#   ./add-paper.sh                        # all PDFs in paper_raw/

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PAPER_RAW="$REPO_ROOT/raw/pdf"
PAPER_MD="$REPO_ROOT/raw/md"
MINERU_TMP="$HOME/mineru_tmp_output"

if [ $# -eq 0 ]; then
    echo "No files specified, converting all PDFs in $PAPER_RAW/"
    files=("$PAPER_RAW"/*.pdf)
else
    files=("$@")
fi

if [ ${#files[@]} -eq 0 ]; then
    echo "No PDF files found."
    exit 1
fi

echo "=== Converting ${#files[@]} PDF(s) with MinerU ==="

for pdf in "${files[@]}"; do
    if [ ! -f "$pdf" ]; then
        echo "SKIP: $pdf not found"
        continue
    fi

    name=$(basename "$pdf" .pdf)
    echo ""
    echo "--- Converting: $name ---"

    # Run MinerU conversion
    conda run -n mineru mineru -p "$pdf" -o "$MINERU_TMP"

    if [ $? -ne 0 ]; then
        echo "FAIL: $name"
        continue
    fi

    # Find the generated MD file
    md_file=$(find "$MINERU_TMP/$name" -name "*.md" -type f | head -1)
    if [ -z "$md_file" ]; then
        echo "FAIL: No MD file generated for $name"
        continue
    fi

    md_dir=$(dirname "$md_file")

    # Copy MD file to paper_md/
    cp "$md_file" "$PAPER_MD/$name.md"

    # Copy images/ folder if exists
    if [ -d "$md_dir/images" ]; then
        mkdir -p "$PAPER_MD/images"
        cp "$md_dir/images/"* "$PAPER_MD/images/" 2>/dev/null
    fi

    echo "OK: $name.md + images copied to paper_md/"
done

# Cleanup temp output
rm -rf "$MINERU_TMP"

echo ""
echo "=== Reindexing qmd ==="
qmd index

echo ""
echo "=== Done ==="
