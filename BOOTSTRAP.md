# Bootstrap — How to Deploy with Claude Code

This file is the **canonical entry prompt** for setting up `paper-wiki-starter`
on a fresh machine via Claude Code.

## Quick start — copy-paste to Claude Code

Open Claude Code in any directory and paste the following prompt:

> I want to deploy `paper-wiki-starter`. Please:
>
> 1. Clone `https://github.com/<your-username>/paper-wiki-starter` into
>    `~/projects/paper-wiki-starter`
> 2. Read `BOOTSTRAP.md`, `DEPENDENCIES.md`, and `skills.lock.yaml` in that repo
> 3. Run `./scripts/bootstrap.sh` and report back anything that needs my
>    attention (GUI installs, OAuth logins, API keys)
> 4. Do **not** create any example content in `wiki/` or `raw/` — those
>    directories are for my own data
>
> Work through each step, pause when you hit something requiring my input, and
> tell me what it is before waiting.

Claude Code will execute the bootstrap, stopping at the manual steps listed
below.

---

## What `bootstrap.sh` does automatically

1. Verifies prerequisites (`conda`, `node`, `npm`, `git`) and reports missing
2. Runs `setup.sh` — creates the `mineru` conda env, installs MinerU + qmd,
   pulls Ollama `gemma4` if available
3. Runs `scripts/install-skills.sh` — installs the 3 first-party skills into
   `~/.claude/skills/`, installs upstream `notebooklm` and
   `kepano/obsidian-skills`, and `endnote-cli`
4. Indexes the (currently empty) `raw/md/` directory with `qmd`

## Manual steps (cannot be automated)

You will be asked to do these yourself when the script pauses:

| Step | Command | Why manual |
|---|---|---|
| NotebookLM login | `notebooklm login` | OAuth requires a browser session |
| Obsidian install | Download from [obsidian.md](https://obsidian.md/) | GUI app, no CLI install |
| Obsidian vault setup | Open Obsidian → "Open folder as vault" → point at `wiki/` | Manual UI action |
| EndNote (optional) | Install EndNote separately | Commercial software |
| CUDA PyTorch (optional, for GPU MinerU) | See `setup.sh` step 1 | Machine-specific CUDA version |

## What to expect on first run

- MinerU model weights: ~500 MB – 2 GB download
- qmd model weights: ~2 GB download (embedding-gemma, qwen3-reranker,
  qmd-query-expansion)
- Total disk: ~5 GB after full install
- First-time setup: 20–40 minutes depending on network

## After setup completes

1. Drop PDFs into `raw/pdf/`
2. Run `./add-paper.sh` to convert them
3. Start Claude Code from the repo root and begin reading workflows

For detailed workflow instructions, see `CLAUDE.md`.
