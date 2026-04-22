# Architecture

## Overview

`paper-wiki-starter` is a Claude-Code-driven research-reading framework. It turns a local folder of paper PDFs into a hyperlinked Obsidian vault of concept pages, report notes, research ideas, and experiment plans — all via Claude Code skills that coordinate a small set of CLI tools.

The system is not a web app, a database, or a cloud service. It is a file-system convention + a set of agent workflows.

## Layered topology

```
┌─────────────────────────────────────────────────────────────────┐
│  raw/                 ← immutable sources (read-only)           │
│   ├── pdf/            PDFs you drop in                          │
│   └── md/             MinerU-produced Markdown (indexed by qmd) │
├─────────────────────────────────────────────────────────────────┤
│  CLI tool chain       (installed via setup.sh + install-skills) │
│   mineru              PDF → MD conversion                        │
│   qmd                 local semantic index + hybrid search      │
│   obsidian-cli        vault link/orphan/alias management        │
│   notebooklm          LLM paper read via Google NotebookLM      │
│   endnote-cli         bibliographic metadata from .enl library  │
├─────────────────────────────────────────────────────────────────┤
│  Claude Code skills   (orchestration layer — the brains)        │
│   paper-report        cross-paper synthesis → wiki/reports/     │
│   paper-idea          idea scouting         → wiki/ideas/       │
│   paper-experiment    experiment planning   → wiki/experiments/ │
│   paper-write         (coming soon)         → papers-draft/     │
├─────────────────────────────────────────────────────────────────┤
│  wiki/                ← curated knowledge (hand- + agent-edited)│
│   ├── concepts/       concept pages, aliases, [[backlinks]]     │
│   ├── papers/         per-paper reading cards                   │
│   ├── reports/        synthesis outputs                         │
│   ├── ideas/          brainstorming cards                       │
│   └── experiments/    transferable experiment recipes           │
└─────────────────────────────────────────────────────────────────┘
```

## Skill dependency graph

```
paper-idea       ──→ paper-report          (mandatory sub-call)
paper-experiment ──→ paper-report          (mandatory sub-call)
paper-report     ──→ notebooklm skill      (conditional: ≥4 papers)
```

All three user-authored skills share two CLI dependencies: `qmd` (index query) and `obsidian-cli` (vault ops). `paper-report` additionally drives `notebooklm` for deep multi-paper synthesis.

## Data flow — four canonical workflows

| Workflow | Entry | Chain |
|---|---|---|
| Add paper | drop PDF → `./add-paper.sh` | `mineru` → `raw/md/` → `qmd index` → NotebookLM read → Claude card → `wiki/papers/` |
| Research report | ask Claude "write a report on X" | `paper-report` skill → qmd query → NotebookLM aggregate → `wiki/reports/` |
| Idea scouting | ask Claude "find ideas in X" | `paper-idea` → internally calls `paper-report` → user picks → `wiki/ideas/` |
| Experiment plan | ask Claude "experiment for X" | `paper-experiment` → calls `paper-report` → user picks → `wiki/experiments/` |

Each workflow is fully described in `CLAUDE.md` (project rules) and the respective skill's `SKILL.md` (agent instructions).

## Separation of concerns

- **`CLAUDE.md`** — project-level rules loaded into every Claude Code session
- **skill `SKILL.md`** — agent-level rules loaded only when the skill is invoked
- **`schema/prompts/`** — templates used inside skills (wiki-link conventions, paper-card format, NotebookLM prompts)
- **`scripts/`** — deterministic Python/shell helpers (no LLM), e.g. concept-audit

Rules live in exactly one place. `CLAUDE.md` deliberately does not duplicate skill rules — the skill is the single source of truth for its own workflow.

## What this repo ships vs what you bring

**Ships**: the infrastructure — rules, templates, skills, bootstrap scripts, and dependency lock.

**You bring**: your PDFs, your notes, your NotebookLM account, your EndNote library, your Obsidian install. The repo has zero content of its own.
