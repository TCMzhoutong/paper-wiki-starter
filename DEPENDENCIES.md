# Dependencies

This document lists every third-party component `paper-wiki-starter` relies on.
We do **not** bundle any of their source code — the `bootstrap.sh` /
`install-skills.sh` scripts install each from its upstream canonical location.

If you spot a license discrepancy or an outdated version, please open an issue.

---

## Claude Code skills (upstream)

| Name | Upstream repo | License | Required by | Install |
|---|---|---|---|---|
| `notebooklm` (skill + CLI) | [teng-lin/notebooklm-py](https://github.com/teng-lin/notebooklm-py) | MIT | paper-report | `pip install 'notebooklm-py[browser]'` then `notebooklm skill install` |
| `obsidian-cli` (part of obsidian-skills) | [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) | MIT | paper-report | `npx skills add git@github.com:kepano/obsidian-skills.git` — installs `obsidian-markdown`, `obsidian-cli`, `obsidian-bases`, `defuddle`, `json-canvas` together |

## CLI tools

| Name | Upstream repo | License | Role | Install |
|---|---|---|---|---|
| `mineru` | [opendatalab/MinerU](https://github.com/opendatalab/MinerU) | AGPL-3.0 (verify) | PDF → Markdown | `conda create -n mineru python=3.12 && conda run -n mineru pip install 'mineru[all]'` (first run downloads models) |
| `qmd` | [opendatalab/MinerU-Document-Explorer](https://github.com/opendatalab/MinerU-Document-Explorer) | MIT | Local markdown index + hybrid search | `npm install -g mineru-document-explorer` (first run downloads ~2 GB of models) |
| `notebooklm` CLI | [teng-lin/notebooklm-py](https://github.com/teng-lin/notebooklm-py) | MIT | Google NotebookLM automation | Included with the Python package (`pip install notebooklm-py[browser]`); then run `notebooklm login` once |
| `endnote-cli` | [TCMzhoutong/endnote-cli](https://github.com/TCMzhoutong/endnote-cli) | Apache-2.0 | Read/write EndNote `.enl` libraries | `pip install 'endnote-cli[all]'` |

## Runtime / GUI dependencies (not auto-installable)

| Name | License / source | Role | Notes |
|---|---|---|---|
| [Obsidian](https://obsidian.md/) | Proprietary (free for personal use) | Vault browser | Install the desktop app manually; point it at the `wiki/` directory as a vault |
| [Conda / Miniconda](https://docs.conda.io/) | BSD-3-Clause | Python env manager | Required for MinerU's isolated environment |
| [Node.js](https://nodejs.org/) ≥ 22 | MIT | CLI runtime | Required for `qmd` and the obsidian-skills installer |
| [Ollama](https://ollama.com/) | MIT | Local LLM (MinerU's optional title-aid) | Optional; pull `gemma4` if you want title-aided conversion |
| [EndNote](https://endnote.com/) | Clarivate (commercial) | Reference manager | Optional; only needed if you use the "new paper" metadata-extraction flow |

## License compatibility

- Nothing in `paper-wiki-starter`'s source tree is GPL-derived. All redistributed
  files are MIT (code) or CC-BY-NC-4.0 (content) — both original work of the
  repository author.
- `mineru` (AGPL-3.0, if confirmed) is invoked only as an external process via
  `conda run` — no linking or bundling occurs — so AGPL obligations do not
  propagate to this repo.
- `kepano/obsidian-skills` ships multiple skills together under MIT; we install
  the entire bundle rather than vendor individual sub-skills.

## Known uncertainties

- **MinerU license** is listed as AGPL-3.0 above pending verification from the
  upstream `LICENSE` file. If AGPL is confirmed, downstream *redistributors* of
  the full stack should note the separation between our MIT/CC-BY-NC code and
  the externally installed MinerU binary.
- Some skills under `skills/` may retain references to legacy `~/.codex/skills/`
  paths in their comments or helper scripts. These are cosmetic — the bootstrap
  scripts install into `~/.claude/skills/` and `install-skills.sh` normalizes
  paths on copy.

## What this repository does **not** redistribute

- No paper PDFs or Markdown extracts (see `.gitignore` — `raw/**` is excluded)
- No user wiki notes (see `.gitignore` — `wiki/**/*.md` is excluded)
- No third-party skill source code (installed at runtime from upstream)
- No MinerU model weights (downloaded on first run from upstream)
