"""概念健康审计脚本 — 检测、索引、合并 wiki/concepts/ 下的概念。

子命令：
    python scripts/concept-audit.py audit [--semantic]     检测重复/冲突（输出候选清单）
    python scripts/concept-audit.py index                  构建概念索引 (concept-index.json)
    python scripts/concept-audit.py merge <keep> <remove>  合并两个概念
    python scripts/concept-audit.py merge --batch <file>   批量合并

merge 使用脚本做链接替换 + aliases 合并，obsidian CLI 做文件删除（进回收站）和验证。
Obsidian 必须处于运行状态。
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import yaml
from collections import defaultdict
from pathlib import Path

WIKI_ROOT = Path(__file__).parent.parent / "wiki"
CONCEPT_DIR = WIKI_ROOT / "concepts"
SCRIPTS_DIR = Path(__file__).parent
INDEX_PATH = SCRIPTS_DIR / "concept-index.json"
REVIEWED_PATH = SCRIPTS_DIR / "reviewed-pairs.json"
VAULT_NAME = "paper_wiki"


# ════════════════════════════════════════════════════════════
#  Shared
# ════════════════════════════════════════════════════════════

def load_concepts(concept_dir: Path = CONCEPT_DIR) -> list[dict]:
    concepts = []
    for f in sorted(concept_dir.glob("*.md")):
        content = f.read_text(encoding="utf-8")
        m = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
        aliases = []
        if m:
            try:
                fm = yaml.safe_load(m.group(1))
                aliases = fm.get("aliases", []) or []
                aliases = [a for a in aliases if isinstance(a, str)]
            except Exception:
                pass
        concepts.append({"name": f.stem, "aliases": aliases, "path": str(f)})
    return concepts


def obsidian_cmd(cmd: str) -> str:
    """Run an obsidian CLI command and return stdout only (stderr discarded)."""
    full_cmd = f'obsidian {cmd} vault="{VAULT_NAME}"'
    result = subprocess.run(
        full_cmd, shell=True, capture_output=True, text=True, encoding="utf-8",
    )
    # obsidian CLI outputs version warnings to stderr — ignore them.
    # Some commands output to stderr even on success — only use stdout.
    output = result.stdout.strip()
    # Filter out any obsidian warning lines that leak into stdout
    lines = [
        line for line in output.splitlines()
        if not line.startswith("Your Obsidian installer")
        and "Loading updated app package" not in line
    ]
    return "\n".join(lines)


# ════════════════════════════════════════════════════════════
#  Sub-command: audit
# ════════════════════════════════════════════════════════════

def check_alias_conflicts(concepts):
    alias_map = defaultdict(list)
    for c in concepts:
        for a in c["aliases"]:
            alias_map[a.lower()].append(c["name"])
    issues = []
    for alias, owners in alias_map.items():
        unique_owners = list(dict.fromkeys(owners))  # dedupe preserving order
        if len(unique_owners) > 1:
            # Real conflict: same alias points to different concepts
            issues.append({
                "type": "ALIAS_CONFLICT", "severity": "ERROR",
                "msg": f"Alias \"{alias}\" 指向多个概念: {', '.join(unique_owners)}",
            })
        elif len(owners) > len(unique_owners):
            # Same concept has duplicate aliases (case variants)
            issues.append({
                "type": "ALIAS_REDUNDANT", "severity": "WARNING",
                "msg": f"\"{unique_owners[0]}\" 有冗余 alias \"{alias}\"（大小写重复）",
            })
    return issues


def check_cross_reference(concepts):
    name_set = {c["name"].lower(): c["name"] for c in concepts}
    issues = []
    for c in concepts:
        for a in c["aliases"]:
            if a.lower() in name_set and a.lower() != c["name"].lower():
                other = name_set[a.lower()]
                issues.append({
                    "type": "CROSS_REFERENCE", "severity": "WARNING",
                    "msg": f"\"{c['name']}\" 的 alias \"{a}\" 和独立概念 \"{other}\" 同名",
                })
    return issues


def check_case_duplicates(concepts):
    normalized = defaultdict(list)
    for c in concepts:
        key = re.sub(r"[\s\-_]", "", c["name"].lower())
        normalized[key].append(c["name"])
    return [
        {"type": "CASE_DUPLICATE", "severity": "ERROR",
         "msg": f"大小写/空格变体重复: {', '.join(names)}"}
        for names in normalized.values() if len(names) > 1
    ]


def _edit_distance(s1, s2):
    if len(s1) < len(s2):
        return _edit_distance(s2, s1)
    if not s2:
        return len(s1)
    prev = range(len(s2) + 1)
    for c1 in s1:
        curr = [prev[0] + 1]
        for j, c2 in enumerate(s2):
            curr.append(min(prev[j + 1] + 1, curr[j] + 1, prev[j] + (c1 != c2)))
        prev = curr
    return prev[len(s2)]


def check_edit_distance(concepts, max_dist=2):
    issues = []
    names = [c["name"] for c in concepts]
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            n1, n2 = names[i], names[j]
            if n1 in n2 or n2 in n1:
                continue
            if len(n1) <= 3 or len(n2) <= 3:
                continue
            dist = _edit_distance(n1, n2)
            if 0 < dist <= max_dist and dist / min(len(n1), len(n2)) <= 0.3:
                issues.append({
                    "type": "NEAR_DUPLICATE", "severity": "WARNING",
                    "msg": f"编辑距离={dist}: \"{n1}\" ↔ \"{n2}\"",
                })
    return issues


def check_semantic(concepts, threshold=0.85):
    try:
        from sentence_transformers import SentenceTransformer
        import numpy as np
    except ImportError:
        print("  [SKIP] sentence-transformers 未安装", file=sys.stderr)
        return []

    model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
    texts = [" | ".join([c["name"]] + c["aliases"]) for c in concepts]
    labels = [c["name"] for c in concepts]

    emb = model.encode(texts, show_progress_bar=False)
    emb = emb / np.linalg.norm(emb, axis=1, keepdims=True)
    sim = emb @ emb.T

    issues = []
    for i in range(len(labels)):
        for j in range(i + 1, len(labels)):
            s = float(sim[i][j])
            if s >= threshold and labels[i] not in labels[j] and labels[j] not in labels[i]:
                issues.append({
                    "type": "SEMANTIC_SIMILAR", "severity": "REVIEW",
                    "msg": f"语义相似度={s:.3f}: \"{labels[i]}\" ↔ \"{labels[j]}\"",
                })
    return sorted(issues, key=lambda x: x["msg"], reverse=True)


def _load_reviewed() -> set[tuple[str, str]]:
    """Load previously reviewed pairs that were confirmed as 'keep both'."""
    if REVIEWED_PATH.exists():
        pairs = json.loads(REVIEWED_PATH.read_text(encoding="utf-8"))
        return {(p[0], p[1]) for p in pairs}
    return set()


def _save_reviewed(pairs: set[tuple[str, str]]):
    data = sorted([list(p) for p in pairs])
    REVIEWED_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def _is_reviewed(issue: dict, reviewed: set) -> bool:
    """Check if a WARNING/REVIEW issue was already reviewed."""
    msg = issue.get("msg", "")
    # Extract concept pair from msg like '编辑距离=1: "A" ↔ "B"'
    m = re.search(r'"([^"]+)"\s*↔\s*"([^"]+)"', msg)
    if not m:
        return False
    a, b = m.group(1), m.group(2)
    return (a, b) in reviewed or (b, a) in reviewed


def cmd_audit(args):
    semantic = "--semantic" in args
    mark_reviewed = "--mark-reviewed" in args
    concepts = load_concepts()
    reviewed = _load_reviewed()
    print(f"Loaded {len(concepts)} concepts, "
          f"{sum(len(c['aliases']) for c in concepts)} aliases")
    if reviewed:
        print(f"  ({len(reviewed)} reviewed pairs will be hidden)")
    print()

    all_issues = []
    for fn in [check_alias_conflicts, check_cross_reference,
               check_case_duplicates, check_edit_distance]:
        all_issues.extend(fn(concepts))

    if semantic:
        print("Running semantic check...")
        all_issues.extend(check_semantic(concepts))

    # Filter out reviewed pairs (only for WARNING/REVIEW, never for ERROR)
    new_issues = []
    hidden = 0
    for issue in all_issues:
        if issue["severity"] in ("WARNING", "REVIEW") and _is_reviewed(issue, reviewed):
            hidden += 1
        else:
            new_issues.append(issue)

    if not new_issues:
        msg = "No issues found."
        if hidden:
            msg += f" ({hidden} reviewed pairs hidden)"
        print(msg)
        return

    severity_order = {"ERROR": 0, "WARNING": 1, "REVIEW": 2}
    new_issues.sort(key=lambda x: severity_order.get(x["severity"], 99))
    marker = {"ERROR": "!!!", "WARNING": " ! ", "REVIEW": " ? "}

    print(f"Found {len(new_issues)} issue(s)" +
          (f" ({hidden} reviewed hidden)" if hidden else "") + ":\n")
    for issue in new_issues:
        print(f"  [{marker.get(issue['severity'], '   ')}] {issue['msg']}")

    by_type = defaultdict(int)
    for i in new_issues:
        by_type[i["type"]] += 1
    print(f"\nSummary: " + ", ".join(f"{t}={c}" for t, c in by_type.items()))

    # Mark all current WARNING/REVIEW as reviewed
    if mark_reviewed:
        for issue in new_issues:
            if issue["severity"] in ("WARNING", "REVIEW"):
                m = re.search(r'"([^"]+)"\s*↔\s*"([^"]+)"', issue.get("msg", ""))
                if m:
                    reviewed.add((m.group(1), m.group(2)))
        _save_reviewed(reviewed)
        print(f"\nMarked {len(reviewed)} pairs as reviewed → {REVIEWED_PATH.name}")


# ════════════════════════════════════════════════════════════
#  Sub-command: index
# ════════════════════════════════════════════════════════════

def cmd_index(args):
    """构建 concept-index.json：{ 变体名(小写) → 规范名 }。"""
    concepts = load_concepts()

    index = {}
    for c in concepts:
        canonical = c["name"]
        index[canonical.lower()] = canonical
        for a in c["aliases"]:
            key = a.lower()
            if key in index and index[key] != canonical:
                print(f"  WARN: \"{a}\" 已映射到 \"{index[key]}\"，跳过 \"{canonical}\"",
                      file=sys.stderr)
                continue
            index[key] = canonical

    INDEX_PATH.write_text(
        json.dumps(index, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )
    print(f"Built index: {len(index)} entries ({len(concepts)} canonical + "
          f"{len(index) - len(concepts)} aliases) → {INDEX_PATH.name}")


# ════════════════════════════════════════════════════════════
#  Sub-command: merge
# ════════════════════════════════════════════════════════════

def merge_one(keep_name: str, remove_name: str, dry_run: bool = False) -> bool:
    """合并一对概念。返回是否成功。

    流程：aliases 读取(obsidian) → aliases 合并(脚本) → 链接替换(脚本) → 删除(obsidian)
    """
    keep_path = CONCEPT_DIR / f"{keep_name}.md"
    remove_path = CONCEPT_DIR / f"{remove_name}.md"

    if not keep_path.exists():
        print(f"  SKIP: \"{keep_name}\" 不存在", file=sys.stderr)
        return False
    if not remove_path.exists():
        print(f"  SKIP: \"{remove_name}\" 不存在", file=sys.stderr)
        return False

    # Step 1: Get aliases from both (obsidian aliases for remove, yaml for keep)
    remove_alias_str = obsidian_cmd(f'aliases file="{remove_name}"')
    remove_aliases = set(remove_alias_str.strip().splitlines()) if remove_alias_str.strip() else set()

    keep_content = keep_path.read_text(encoding="utf-8")
    keep_m = re.match(r"^---\s*\n(.*?)\n---", keep_content, re.DOTALL)
    keep_fm = yaml.safe_load(keep_m.group(1)) if keep_m else {}
    keep_aliases = set(keep_fm.get("aliases", []) or [])

    new_aliases = keep_aliases | remove_aliases | {remove_name}
    new_aliases.discard(keep_name)
    new_aliases = sorted(new_aliases)

    # Step 2: Get affected files via obsidian backlinks (faster + more accurate than rglob)
    backlinks_raw = obsidian_cmd(f'backlinks file="{remove_name}" format=json')
    try:
        backlinks = json.loads(backlinks_raw) if backlinks_raw.strip() else []
        affected_files = [b["file"] for b in backlinks if isinstance(b, dict)]
    except (json.JSONDecodeError, KeyError):
        # Fallback: scan files
        affected_files = []
        for md in WIKI_ROOT.rglob("*.md"):
            if md == remove_path:
                continue
            text = md.read_text(encoding="utf-8")
            if f"[[{remove_name}]]" in text or f"[[{remove_name}|" in text:
                affected_files.append(str(md.relative_to(WIKI_ROOT.parent)))

    if dry_run:
        print(f"  [DRY] \"{remove_name}\" → \"{keep_name}\": "
              f"{len(affected_files)} files, new aliases={new_aliases}")
        for f in affected_files:
            print(f"         {f}")
        return True

    # Step 3: Merge aliases into keep (script edits frontmatter)
    if keep_m:
        old_fm = keep_m.group(1)
        if "aliases:" in old_fm:
            new_fm = re.sub(r"aliases:.*", f"aliases: {new_aliases}", old_fm)
        else:
            new_fm = old_fm + f"\naliases: {new_aliases}"
        keep_path.write_text(keep_content.replace(old_fm, new_fm), encoding="utf-8")

    # Step 4: Global link replacement (script does text replace)
    replaced = 0
    for md in WIKI_ROOT.rglob("*.md"):
        if md == remove_path:
            continue
        text = md.read_text(encoding="utf-8")
        new_text = text.replace(f"[[{remove_name}]]", f"[[{keep_name}]]")
        new_text = re.sub(
            rf"\[\[{re.escape(remove_name)}\|([^\]]+)\]\]",
            rf"[[{keep_name}|\1]]",
            new_text,
        )
        if new_text != text:
            md.write_text(new_text, encoding="utf-8")
            replaced += 1

    # Step 5: Delete via obsidian CLI (trash, recoverable)
    obsidian_cmd(f'delete file="{remove_name}"')

    print(f"  DONE: \"{remove_name}\" → \"{keep_name}\": "
          f"aliases={new_aliases}, {replaced} files updated, "
          f"{remove_name}.md → trash")
    return True


def cmd_merge(args):
    dry_run = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]

    if "--batch" in args:
        idx = args.index("--batch")
        if idx + 1 >= len(args):
            print("用法: merge --batch <plan.json> [--dry-run]", file=sys.stderr)
            sys.exit(1)
        plan = json.loads(Path(args[idx + 1]).read_text(encoding="utf-8"))
    elif len(args) >= 2:
        plan = [{"keep": args[0], "remove": args[1]}]
    else:
        print("用法:")
        print("  merge <保留> <删除> [--dry-run]")
        print("  merge --batch <plan.json> [--dry-run]")
        print("\nplan.json 格式:")
        print('  [{"keep": "大语言模型", "remove": "大型语言模型"}, ...]')
        sys.exit(1)

    ok = 0
    for pair in plan:
        if merge_one(pair["keep"], pair["remove"], dry_run=dry_run):
            ok += 1

    action = "预览" if dry_run else "合并"
    print(f"\n{action}完成: {ok}/{len(plan)}")

    if not dry_run and ok > 0:
        print("\nRebuilding index...")
        cmd_index([])

        # Verify: check for broken links
        print("\nVerifying (obsidian unresolved)...")
        result = obsidian_cmd("unresolved total")
        print(f"  Unresolved links: {result}")


# ════════════════════════════════════════════════════════════
#  Main
# ════════════════════════════════════════════════════════════

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0)

    cmd = sys.argv[1]
    args = sys.argv[2:]

    if cmd == "audit":
        cmd_audit(args)
    elif cmd == "index":
        cmd_index(args)
    elif cmd == "merge":
        cmd_merge(args)
    else:
        print(f"Unknown command: {cmd}\nAvailable: audit, index, merge")
        sys.exit(1)


if __name__ == "__main__":
    main()
