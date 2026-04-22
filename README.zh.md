**🌐 [English](README.md) · [中文](README.zh.md)**

# paper-wiki-starter

一个由 Claude Code 驱动的脚手架，把一堆论文 PDF 变成带双链的 Obsidian 知识库——包含概念页、精读卡片、跨论文综合报告、研究 idea 和实验方案。

本仓库**只包含框架**：工作流规则、提示词模板、Claude skill 和一键部署脚本。**不包含**任何论文内容、个人笔记或模型权重——这些由你自己来填。

> **说明**：`paper-write` skill（端到端论文写作）**未包含**在首个发行版本中。类似功能将在后续版本中加入。当前发布的三个 skill——`paper-report`、`paper-idea`、`paper-experiment`——均可独立完整运行。

---

## 你会得到什么

- **3 个 Claude Code skill**，把自然语言提问转成结构化 wiki 条目：
  - `paper-report`——跨论文综合分析，自动识别意图（gap-finding / landscape / method-compare / …）
  - `paper-idea`——研究 idea 挖掘，强制 novelty 检查
  - `paper-experiment`——可照抄的实验方案（baseline / 数据集 / metric / 参数）
- **提示词模板**（`schema/prompts/`），覆盖 NotebookLM 精读、概念页更新、双链规范
- **一键部署脚本**，自动装好周边 CLI 栈（MinerU、qmd、NotebookLM CLI、endnote-cli、kepano 的 obsidian-skills 包）
- **确定性校验脚本**（`scripts/concept-audit.py`），定期做 wiki 健康检查

## 架构总览

```
raw/ （PDF + MinerU 输出）
    │
    ▼
CLI 工具链：mineru → qmd → obsidian-cli → notebooklm → endnote-cli
    │
    ▼
Claude skills：paper-report ← paper-idea、paper-experiment
    │
    ▼
wiki/ （concepts、papers、reports、ideas、experiments）
```

完整架构：[`architecture.md`](architecture.md) · 工作流规则：[`CLAUDE.md`](CLAUDE.md)

## 快速开始

在已安装 Claude Code 的新机器上：

```bash
git clone https://github.com/TCMzhoutong/paper-wiki-starter.git
cd paper-wiki-starter
./scripts/bootstrap.sh
```

然后在仓库目录下打开 Claude Code，按提示走。完整部署流程（包括不能自动化的几步：NotebookLM OAuth、Obsidian 安装、EndNote），详见 [`BOOTSTRAP.md`](BOOTSTRAP.md)。

## 前置依赖

**必装**：`git`、`conda`、`node ≥ 22`、`npm`、`python ≥ 3.10`、Claude Code。

**bootstrap 自动安装**：MinerU、qmd、notebooklm-py、endnote-cli、kepano/obsidian-skills 全家桶。

**需手动装**（脚本会在相应节点停下来告诉你）：Obsidian 桌面版、NotebookLM OAuth 登录、EndNote（可选）。

完整依赖矩阵 + 上游 URL + license：见 [`DEPENDENCIES.md`](DEPENDENCIES.md)。

## 目录结构

```
paper-wiki-starter/
├── CLAUDE.md                  ← Claude Code 会话级规则
├── architecture.md            ← 架构说明
├── BOOTSTRAP.md               ← 给 Claude Code 用的部署提示词
├── DEPENDENCIES.md            ← 第三方组件清单 + license
├── skills.lock.yaml           ← 机器可读依赖声明
├── schema/prompts/            ← 模板（论文卡 / 概念更新 / NotebookLM 提示词）
├── scripts/
│   ├── bootstrap.sh           ← 一键部署
│   ├── install-skills.sh      ← Claude skill + CLI 装载
│   ├── check-env.sh           ← 环境状态检查
│   └── concept-audit.py       ← wiki 健康检查
├── skills/                    ← 第一方 Claude skill（随仓库发布）
│   ├── paper-report/
│   ├── paper-idea/
│   └── paper-experiment/
├── setup.sh                   ← 环境安装（conda + MinerU + qmd + Ollama）
├── add-paper.sh               ← PDF → Markdown → qmd 索引 工作流
├── wiki/                      ← 你自己的笔记（已 gitignore）
└── raw/                       ← 你的 PDF 和 MinerU 输出（已 gitignore）
```

## 四大标准工作流

| 工作流 | Claude 里的触发句 | 产出位置 |
|---|---|---|
| **新增论文** | 把 PDF 扔进去，跑 `./add-paper.sh` | `wiki/papers/<标题>.md` |
| **研究报告** | "写一份关于 X 的 report"、"对比 A vs B" | `wiki/reports/<主题>_<日期>.md` |
| **找 idea** | "找 X 方向的 idea"、"/idea X" | `wiki/ideas/<短标题>_<日期>.md` |
| **实验方案** | "X 的 baseline 怎么设计"、"/experiment X" | `wiki/experiments/<短标题>_<日期>.md` |

每个工作流的详细规则（意图识别、积木装配、校验闸门）在各自 skill 的 `SKILL.md` 里。

## License

- **代码**（`.sh`、`.py`、`.yaml`、`.json`）—— [MIT](LICENSE)
- **内容**（提示词模板、skill 指令、文档）—— [CC-BY-NC-4.0](docs/content-licensing.md)

提示词模板的商业使用需另行授权。非商业的学术、个人、科研用途无需额外许可。

## 参与贡献

见 [`CONTRIBUTING.md`](CONTRIBUTING.md)。简短版：欢迎框架层改进，不接受个人笔记的 PR。不要把 PDF 提 PR 过来。

## 致谢

本项目站在以下开源工作的肩膀上：

- [**MinerU**](https://github.com/opendatalab/MinerU)——PDF 转 Markdown
- [**MinerU-Document-Explorer (qmd)**](https://github.com/opendatalab/MinerU-Document-Explorer)——本地 markdown 索引 + 语义检索
- [**notebooklm-py**](https://github.com/teng-lin/notebooklm-py)——Google NotebookLM 自动化
- [**kepano/obsidian-skills**](https://github.com/kepano/obsidian-skills)——obsidian-cli、defuddle 等
- [**endnote-cli**](https://github.com/TCMzhoutong/endnote-cli)——EndNote `.enl` 库访问
- [**Obsidian**](https://obsidian.md/)——整套系统围绕运转的 vault 浏览器
