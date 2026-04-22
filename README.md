**🌐 [English](README.md) · [中文](README.zh.md)**

# paper-wiki-starter

A Claude-Code-driven scaffold for turning a pile of research paper PDFs into a hyperlinked Obsidian vault — concept pages, reading cards, cross-paper reports, research ideas, and experiment plans.

This repository contains the **framework**: workflow rules, prompt templates, Claude skills, and a bootstrap script. It contains **zero** paper content, zero personal notes, and zero model weights. You bring those.

> **Note**: the `paper-write` skill (end-to-end manuscript drafting) is **not** included in this initial release. A similar workflow will be added in a future update. The three shipped skills — `paper-report`, `paper-idea`, and `paper-experiment` — are fully functional standalone.

---

## What you get

- **3 Claude Code skills** that turn natural-language questions into structured wiki entries:
  - `paper-report` — cross-paper synthesis, intent-aware (gap-finding / landscape / method-compare / …)
  - `paper-idea` — research-idea scouting with mandatory novelty check
  - `paper-experiment` — transferable experiment plans with "steal-able" baselines, datasets, metrics
- **Prompt templates** (`schema/prompts/`) covering NotebookLM paper review, Claude concept update, and wikilink conventions
- **Bootstrap scripts** that install the surrounding CLI stack (MinerU, qmd, NotebookLM CLI, endnote-cli, kepano's obsidian-skills bundle) with a single command
- **Deterministic audit helpers** (`scripts/concept-audit.py`) for periodic wiki health checks

## Architecture at a glance

```
raw/ (PDFs + MinerU output)
    │
    ▼
CLI tools: mineru → qmd → obsidian-cli → notebooklm → endnote-cli
    │
    ▼
Claude skills: paper-report ← paper-idea, paper-experiment
    │
    ▼
wiki/ (concepts, papers, reports, ideas, experiments)
```

Full picture: [`architecture.md`](architecture.md) · Workflow rules: [`CLAUDE.md`](CLAUDE.md)

## Quick start

On a fresh machine with Claude Code installed:

```bash
git clone https://github.com/TCMzhoutong/paper-wiki-starter.git
cd paper-wiki-starter
./scripts/bootstrap.sh
```

Then open Claude Code in the repo directory and follow the prompts. For the full deployment walk-through (including the steps that can't be automated — NotebookLM OAuth, Obsidian install, EndNote), see [`BOOTSTRAP.md`](BOOTSTRAP.md).

## Prerequisites

**Required**: `git`, `conda`, `node ≥ 22`, `npm`, `python ≥ 3.10`, Claude Code.

**Installed automatically by the bootstrap**: MinerU, qmd, notebooklm-py, endnote-cli, kepano/obsidian-skills bundle.

**Manual install (bootstrap tells you when)**: Obsidian desktop app, NotebookLM OAuth login, EndNote (optional).

Full dependency matrix with upstream URLs and licenses: [`DEPENDENCIES.md`](DEPENDENCIES.md).

## Directory layout

```
paper-wiki-starter/
├── CLAUDE.md                  ← session-wide rules for Claude Code
├── architecture.md            ← how the pieces fit
├── BOOTSTRAP.md               ← Claude-Code-facing deploy prompt
├── DEPENDENCIES.md            ← third-party inventory + licenses
├── skills.lock.yaml           ← machine-readable dep spec
├── schema/prompts/            ← templates (paper cards, concept updates, NotebookLM prompts)
├── scripts/
│   ├── bootstrap.sh           ← one-shot deploy
│   ├── install-skills.sh      ← Claude skills + CLI wrappers
│   ├── check-env.sh           ← status report
│   ├── batch-read.sh          ← headless bulk paper-card generation
│   └── concept-audit.py       ← wiki health check
├── skills/                    ← first-party Claude skills (shipped)
│   ├── paper-report/
│   ├── paper-idea/
│   └── paper-experiment/
├── setup.sh                   ← environment installer (conda + MinerU + qmd + Ollama)
├── add-paper.sh               ← PDF → Markdown → qmd-indexed workflow
├── wiki/                      ← YOUR curated notes (gitignored)
└── raw/                       ← YOUR PDFs + MinerU output (gitignored)
```

## Canonical workflows

| Workflow | Trigger phrase in Claude | Output |
|---|---|---|
| **Add paper** | Drop PDF, run `./add-paper.sh` | `wiki/papers/<title>.md` |
| **Research report** | "write a report on X", "compare A vs B" | `wiki/reports/<topic>_<date>.md` |
| **Idea scouting** | "find ideas in X", "/idea X" | `wiki/ideas/<slug>_<date>.md` |
| **Experiment plan** | "baseline for X", "/experiment X" | `wiki/experiments/<slug>_<date>.md` |

Details for each workflow — intent detection, block assembly, validation gates — live inside the respective skill's `SKILL.md`.

### Bulk paper reading

For ingesting tens or hundreds of papers at once without bloating a single Claude Code session's context:

```bash
./add-paper.sh                 # MinerU-convert all PDFs in raw/pdf/
./scripts/batch-read.sh        # headless loop: one `claude -p` per paper
```

Run this from a **regular terminal** (PowerShell / Git Bash), not from inside an interactive Claude Code session. Each paper runs in its own fresh Claude context — no carry-over, no bloat. The script is idempotent (skips papers whose cards already exist) and safe to Ctrl-C and resume. Progress is streamed to `batch-read.log`.

After the batch finishes, ask Claude Code once to run the **校验维护流程** (concept health audit). This dedupes concepts and resolves alias conflicts across the whole batch in a single pass — the designed-in "cleanup stage" that keeps bulk mode fast.

## License

- **Code** (`.sh`, `.py`, `.yaml`, `.json`) — [MIT](LICENSE)
- **Content** (prompt templates, skill instructions, documentation prose) — [CC-BY-NC-4.0](docs/content-licensing.md)

Commercial use of the prompt templates requires separate licensing. Non-commercial academic, personal, and research use is explicitly permitted.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Short version: framework improvements welcome, personal notes aren't. Don't PR PDFs.

## Acknowledgements

Stands on the shoulders of:

- [**MinerU**](https://github.com/opendatalab/MinerU) — PDF → Markdown conversion
- [**MinerU-Document-Explorer (qmd)**](https://github.com/opendatalab/MinerU-Document-Explorer) — local markdown index + semantic search
- [**notebooklm-py**](https://github.com/teng-lin/notebooklm-py) — Google NotebookLM automation
- [**kepano/obsidian-skills**](https://github.com/kepano/obsidian-skills) — obsidian-cli, defuddle, and friends
- [**endnote-cli**](https://github.com/TCMzhoutong/endnote-cli) — EndNote `.enl` library access
- [**Obsidian**](https://obsidian.md/) — the vault browser the whole thing orbits around
