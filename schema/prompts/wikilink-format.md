# Obsidian 双链格式规范

生成任何 wiki/ 下的文件时，必须遵守以下规范。

## 文件命名

- 论文卡片：`wiki/papers/作者_年份_关键词.md`
- 概念页：`wiki/concepts/概念名.md`
- 报告：`wiki/reports/主题_YYYY-MM-DD.md`
- idea 卡片：`wiki/ideas/短标题_YYYY-MM-DD.md`
- experiment 卡片：`wiki/experiments/短标题_YYYY-MM-DD.md`

## 双链规则

1. 每个文件必须包含至少 1 个 `[[wikilink]]`
2. 论文卡片中，所有关键概念必须链接：`[[概念名]]`
3. 概念页中，必须反向链接提及该概念的论文：`[[作者_年份_关键词]]`
4. 新概念如果 `wiki/concepts/` 中不存在对应文件，仍然写 `[[概念名]]`
5. `[[X]]` 命名必须和实际文件名完全对应（大小写、空格、下划线）
6. 写 `[[X]]` 前必须先参考上下文里的规范名/aliases 映射：
   - 命中规范名或别名 → 用规范名
   - 全新概念 → 创建概念页时必须同时登记 aliases（中英文对译、标准缩写）
   - 合并判断采取保守策略：只合并明显的同义变体（中英文对译、标准缩写），家族 vs 变体、泛称 vs 特化等情况一律视为不同概念

## Frontmatter 规范

每个文件必须包含 YAML frontmatter。列表字段统一用方括号数组格式。

### 论文卡片

```yaml
---
title: "论文完整标题"
authors: [作者1, 作者2]
date: 2026-03          # 精确到月，支撑时间范围筛选
venue: "期刊名/会议名"  # 文献来源：具体期刊、会议、书籍或网站名称
tags: [期刊论文, 实证研究]
tldr: "一句话总结，Read limit=20 时能直接看到"
pdf: "[[raw/pdf/文件名.pdf]]"
---
```

`tags` 只放**描述论文本身性质**的分类标签，可以多个。常见值：
- 发表形式：`期刊论文`、`会议论文`、`学位论文`、`预印本`、`专利`
- 研究类型：`实证研究`、`综述`、`方法论`、`案例研究`、`数据集`

研究领域和使用的方法不放 tags——这些由正文里的 `[[wikilink]]` 表达，通过概念页的反向链接检索。

### 概念页

```yaml
---
title: "概念名"
aliases: [英文名, 缩写]
tags: [领域标签]
related: ["[[相关概念1]]", "[[相关概念2]]"]
---
```

### 报告

```yaml
---
title: "报告主题"
date: 2026-04-11
tags: [领域标签]
papers: ["[[作者1_年份_关键词]]", "[[作者2_年份_关键词]]"]
related: ["[[相关概念]]", "[[相关报告]]"]
---
```

字段分工：
- `papers` — 本报告直接涉及/综述的论文（报告的核心主题）
- `related` — 相关的概念页或其他报告（广义关联）

所有 wikilink 必须用双引号包裹（YAML 方括号数组里裸的 `[[X]]` 会被解析为嵌套列表，导致 Grep 失败）。

### Idea 卡片

```yaml
---
title: "Idea 完整标题"
date: 2026-04-14
status: brainstorm        # brainstorm / shortlisted / in-progress / shelved / done
tags: [领域标签]
source_report: "[[支撑 report 文件名]]"
effort: low               # low / medium / high
novelty: unchecked        # unchecked（brainstorm 阶段默认）/ low / medium / high
risk: low                 # low / medium / high
related_papers: ["[[作者_年份_关键词]]"]
related_ideas: ["[[同主题历史 idea_日期]]"]
linked_experiments: []
related_concepts: ["[[概念]]"]
---
```

字段分工：
- `source_report` — 触发本 idea 的调研报告（单值）
- `status` — 生命周期状态，支持按状态过滤盘点
- `effort` / `novelty` / `risk` — 快速 triage；`novelty` 在 brainstorm 阶段默认 `unchecked`，流转到 `shortlisted` 时强制做文献检查后填入
- `related_papers` / `related_concepts` — 推进 idea 时反复引用的对象（广义关联）
- `related_ideas` — 同 `tags` 或同 `source_report` 的历史 idea 卡，防重复立项；无则 `[]`
- `linked_experiments` — 本 idea 衍生出的 experiment 卡；由 paper-experiment skill 阶段 5.3 自动回写

Idea 卡片详细模板（含正文章节）见 `~/.claude/skills/paper-idea/ideas-template.md`。

### Experiment 卡片

```yaml
---
title: "实验方案完整标题"
date: 2026-04-15
status: planned              # planned / running / done / abandoned
experiment_type: computational   # computational / animal / clinical / in-vitro / omics / mixed / other
tags: [领域标签]
source_report: "[[支撑 report]]"
source_idea: null            # 或 "[[衍生自的 idea 卡]]"
target: "一句话：要做什么实验"
effort: low                  # low / medium / high
risk: low                    # low / medium / high
related_papers: ["[[提供 baseline 的论文]]"]
related_concepts: ["[[核心概念]]"]
---
```

字段分工：
- `experiment_type` — 7 类之一（computational / animal / clinical / in-vitro / omics / mixed / other），决定"研究对象 + 具体配置"段用哪个子模板
- `source_report` — 支撑本方案的调研报告（单值）
- `source_idea` — 如本 experiment 是某 idea 长出来的，填 idea 卡文件名；否则 `null`
- `target` — 一句话描述要做什么
- `status` — 生命周期状态
- `effort` / `risk` — 快速 triage；由 scanner 粗估继承，可手动改
- `related_papers` — 提供 baseline / 参照的论文
- `related_concepts` — 广义关联

Experiment 卡片详细模板（通用骨架 + 7 类变体）见 `~/.claude/skills/paper-experiment/experiment-template.md`。

## Draft 双链规则（papers-draft/）

`papers-draft/<slug>/` 是 paper-write skill 的工作区。核心原则：

- **双链单向流动**：只允许 draft → wiki；draft 内部、draft 之间、wiki 回指 draft 均不用 `[[X]]`
- draft 内部跨文件引用用**相对路径**（避免同名文件冲突）
- 不同 paper 项目互相**严禁**双链（应通过共同引用 wiki/ 资源间接关联）
- 投稿手稿 `output/doc/submission.md` 由 Phase 5 unlink 全部 strip `[[X]]`

**规则单一来源**：完整规则表、冲突处理、unlink 算法见 `~/.claude/skills/paper-write/wikilink-rules.md` 和 `final-unlink.md`。本文件只做简述索引，避免三源漂移。

## 标题层级

- `#` h1：文件标题（与 frontmatter title 一致）
- `##` h2：主要章节（摘要、方法、结果等）
- `###` h3：子章节

## 特殊语法

- 高亮：`==重要内容==`
- 标注：`> [!note] 标题` / `> [!warning]` / `> [!tip]`
- 标签：`#tag` 行内标签
