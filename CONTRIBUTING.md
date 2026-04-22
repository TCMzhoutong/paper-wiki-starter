# Contributing

Thanks for considering a contribution. This project is maintained by a single
researcher in their spare time, so please read this short guide before opening
an issue or PR — it saves everyone friction.

## Scope

`paper-wiki-starter` is a **framework**, not a content repository. Accepted
contributions:

- Bug fixes in `scripts/`, `setup.sh`, `add-paper.sh`, or skill dispatch logic
- New Claude skills that fit the existing workflow topology (report / idea /
  experiment) and declare their upstream dependencies in `skills.lock.yaml`
- Improvements to prompts in `schema/prompts/` (clarity, error handling,
  multilingual support)
- Bootstrap-script portability (macOS, Linux, WSL)
- Translations of `README.md`, `CLAUDE.md`, or `architecture.md`
- Documentation fixes

Not accepted:

- Your own paper notes, PDFs, or personal wiki content — this repo has no
  `wiki/` content and never will
- Skills that wrap commercial or closed-source services without a documented
  opt-out path
- Skills bundled with source code under a GPL-family license (we avoid license
  contagion — link to them in `skills.lock.yaml` instead of vendoring)

## Before filing an issue

1. Reproduce on the `main` branch with `scripts/check-env.sh` output attached
2. If the bug is in a third-party skill or CLI (MinerU, qmd, notebooklm,
   obsidian-cli, endnote-cli), file it upstream — we only handle integration
   glue here

## Pull request conventions

- One logical change per PR
- Commit messages: imperative mood, describe the *why*, not the *what*
  ("fix qmd index rebuild on empty raw/md/" — not "update script")
- New skills: include a `SKILL.md` with frontmatter (`name`, `description`),
  and add an entry to `skills.lock.yaml`
- Do **not** commit:
  - Any `.md` file under `wiki/**`
  - Any file under `raw/**` other than `.gitkeep`
  - `.claude/settings.local.json`
  - `.obsidian/workspace.json`
- Run `scripts/check-env.sh` locally before submitting

## License of your contributions

By submitting a PR you agree that your contribution is licensed under the same
terms as the rest of the repository:

- Code (`.sh`, `.py`, `.yaml`, `.json`) — MIT
- Prose (`.md`, templates) — CC-BY-NC-4.0

If you cannot agree to this dual-license (for example because your employer
requires a CLA), please open an issue to discuss before writing code.

## Maintainer response time

- Issues: best-effort, expect days-to-weeks
- PRs: same; small focused PRs are merged faster than sweeping refactors
- Security reports: please email the maintainer directly rather than filing a
  public issue

## Not a substitute for upstream

If your question is really about MinerU, qmd, Obsidian, or any other upstream
tool — go to their repository first. This project is thin glue; most real bugs
live upstream.
