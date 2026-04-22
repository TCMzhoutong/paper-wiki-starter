# Paper-Write 融合规范（精简版）

本文档是 paper_wiki 项目内"论文写作流程"的速查规范。完整规则见 `~/.claude/skills/paper-write/`。

## 一句话定位

paper-write skill 是**端到端论文写作的编排器**，内部调用 paper-bootstrap / results-analysis / scientific-writing / manuscript-optimizer / citation-verifier / submission-audit / rebuttal-response 等原版 skill，并注入 wiki 上下文（reports / papers / concepts / raw md）。仅在 paper_wiki 项目内触发。

## 工作区

```
papers-draft/<slug>/        ← 与 wiki/ raw/ schema/ 同级
├── input/                  ← 实验数据、reviewer 评论
├── notes/                  ← project_truth / decision_log / result_summary / paper_handoff
├── figures/
└── output/
    ├── doc/                ← 各 section .md + 最终 submission.md / submission.bib
    └── review/             ← citation-audit / terminology-audit / submission-audit / unlink-report
```

slug 命名：`<short-en-title>_<YYYYMMDD>`，如 `rag-eval_20260416`。

## 5 阶段流程

| 阶段 | 内容 | 内部调用 |
|---|---|---|
| 0 | 立项意图识别（idea 衍生 / experiment 衍生 / 独立项目）| — |
| 1 | Bootstrap + Wiki Context 注入 | paper-bootstrap |
| 2 | 结果翻译 → result_summary.md | results-analysis |
| 3 | 起草 + 三级级联检索（reports → papers → raw/md）| scientific-writing |
| 4 | 优化 + 验证（术语挂 wiki/concepts/，引用挂 wiki/papers/）| manuscript-optimizer + citation-verifier |
| 5 | 投稿预检 + unlink → submission.md + submission.bib | submission-audit + final-unlink |

## 三级级联检索（Phase 3 核心）

```
查询时按写作目标层级下钻：
  Layer 1 → wiki/reports/      (结构性论述：Related Work / Gap)
  Layer 2 → wiki/papers/       (论文级语义锚点：tldr / limitation)
  Layer 3 → raw/md/ (qmd)     (精确数字 / 原话引用)
  
冷启动缺失：
  L1 缺 → 自动调 paper-report (intent=LANDSCAPE 或 GAP_FINDING)
  L2 缺 → 引导走 add-paper.sh
  L3 缺 → 标注 "qmd 未覆盖" 或 "raw/md 缺失"
  全 miss + 脱离 wiki domain → fallback 外部检索
```

## 双链规范

**铁律**：双链单向流动，**只有 draft → wiki**。

| 场景 | `[[X]]` |
|---|---|
| draft → wiki/concepts/ /papers/ /reports/ /ideas/ /experiments/ | ✅ 用 |
| draft 内部互相引用 | ❌ 用相对路径 |
| paperA → paperB | ❌ 严禁 |
| **最终投稿手稿** `submission.md` | ❌ Phase 5 unlink 全 strip |

## Phase 5 Unlink

所有 `[[concept]]` → 保留表面文本  
所有 `[[paper-key]]` → 按 `target_venue` 转换（apa / acl / nature / gb-7714 / ...）  
收集所有 paper 引用 → 生成 `submission.bib`

## 关键铁律

1. **paper-write 不创建 idea / experiment 卡**（只消费，不污染上游）
2. **不允许引用未在 wiki/papers/ 精读过的论文**（critical 阻塞 Phase 5）
3. **不允许编造具体数字**（raw/md 没有则改写为不带数字的表述）
4. **paper-bootstrap 默认路径覆盖**：传 `papers-draft/<slug>/`，不要用 Nature 原版的 `/data/boom/Papers`
5. **nature-portfolio-playbook 在 paper_wiki 内不调用**（除非 target_venue 在 Nature 系）

## 消歧

- 与其他 paper-* skill 的分工、与 Nature 原版 skill 的分工：详见 `SKILL.md` 顶部"与其他 skill 的分工"表
- 一句话：端到端写论文走 paper-write；单点需求（改图 / 改引用 / 改 rebuttal / 投稿前预检）直接用对应 Nature skill；项目外走 Nature 原版

## 详细规则索引

- `~/.claude/skills/paper-write/SKILL.md` — 主流程
- `~/.claude/skills/paper-write/retrieval-cascade.md` — 三级级联算法 + section-to-layer 映射表
- `~/.claude/skills/paper-write/wikilink-rules.md` — draft 双链规则
- `~/.claude/skills/paper-write/citation-verifier-extension.md` — wiki 引用校验层
- `~/.claude/skills/paper-write/manuscript-optimizer-extension.md` — wiki 术语审计层
- `~/.claude/skills/paper-write/final-unlink.md` — 投稿前 unlink + BibTeX 生成

**规则单一来源**：以 skill 文件为准，本文档只是项目内的速查索引。
