# Idea 卡片模板

本文件由 paper-idea skill 阶段 5 触发加载。

## 文件命名

```
wiki/ideas/<短标题>_<YYYY-MM-DD>.md
```

**短标题约束**：
- 4-12 个汉字或英文词
- 避免冒号、斜杠、空格、引号
- 同一 idea 迭代多次 → 不同日期后缀，旧版本不主动归档（由用户在 Obsidian 中重命名）

## Frontmatter

```yaml
---
title: "Idea 完整标题"
date: YYYY-MM-DD
status: brainstorm    # brainstorm / shortlisted / in-progress / shelved / done
tags: [领域标签1, 领域标签2]
source_report: "[[支撑 report 文件名]]"
effort: low/medium/high
novelty: unchecked    # brainstorm 阶段默认 unchecked；shortlisted+ 必须改为 low/medium/high
risk: low/medium/high
related_papers: ["[[作者_年份_关键词]]", ...]
related_ideas: ["[[同主题历史 idea_日期]]", ...]    # 同 tags 或同 source_report 的旧 idea，防重复立项；无则 []
linked_experiments: []    # 本 idea 衍生出的 experiment 卡；由 paper-experiment skill 阶段 5.3 自动回写
related_concepts: ["[[概念1]]", ...]
---
```

⚠️ 所有 wikilink 必须用双引号包裹（YAML 数组里裸 `[[X]]` 会被解析为嵌套列表）。

## Status 流转规则

| Status | 语义 | 触发条件 | novelty 要求 |
|---|---|---|---|
| `brainstorm` | 初写，未验证 | paper-idea 生成时默认 | `unchecked` |
| `shortlisted` | 决定优先做 | 用户手动改 | **必须**改为 low/medium/high，要求先做 Google Scholar 检索 |
| `in-progress` | 开始实际做 | 用户手动改 | 保留 shortlisted 阶段的值 |
| `shelved` | 暂停 | 用户手动改 | 末尾补"暂停原因"段 |
| `done` | 完成 | 用户手动改 | 末尾链接产出的论文 / 实验 report |

## 正文骨架

```markdown
# {{Idea 完整标题}}

## 一句话描述

{{what — 1-2 句，强迫收敛到核心问题}}

## 为什么值得做

**正向价值（做了能推进什么）**：
{{why worth — 价值论证。**不要**重复信号出处（那是"溯源"段的事）。
讲这件事做了有什么链路价值——高相关发现什么、低相关发现什么、无论高低是否都能成篇}}

**负向代价（不做会怎样）**：
{{现状下此问题持续带来什么损失 / 谁受影响 / 领域停滞在哪里 / 累积代价。
强迫写出"不做的 cost"——防止 idea 落在"锦上添花"而非"雪中送炭"}}

## 假设与要证明什么

{{建议多条 H1 / H2 / H3，每条必须可证伪。
多假设让研究有多个成功条件，避免"一条假设崩盘全项目 gg"}}

- H1：{{可证伪命题}}
- H2：{{可证伪命题}}

## 下一动作

{{⚠️ 必须是**原子级**具体动作，能在 1-2 小时内启动}}

{{反例：❌ "复现 Liu 的 TOSRR 系统"（这是一个子项目，不是原子动作）}}
{{正例：✅ "发邮件给 Chang Liu 询问专家盲评 raw score 是否可共享"}}

## 最小实验计划

{{5 步以内可验证实验。超过 5 步说明 idea 太大，应拆分为多个 idea}}

1. ...
2. ...
3. ...

## 可借鉴 baseline / 现有工作

### Baseline（整体可对比系统）

{{每个 baseline 是一个可以完整跑起来作对比的系统，from source_report 里的论文}}

- [[论文1]]：扮演 {{SOTA / 弱 baseline / ablation 对照}} 角色
  - **可直接抄的配置**：{{数据集 + metric + 关键超参，来自 qmd doc-grep 的具体段落}}
  - **开源状态**：{{repo link / 需复现}}
  - **踩过的坑（作者自述）**：{{作者 limitation 段的具体自述}}

### 可移植的 Module / Trick（方法级借鉴）

{{不借整体系统，而是抄某个组件 / 技巧装到自己的 model。没有则写"无"}}

- [[论文X]] 的 {{模块名，如 "hierarchical attention" / "role-aware gate"}}：
  - **原论文用来解决什么**：{{该 module 的设计动机}}
  - **实现出处**：{{论文 section 位置 + repo 文件路径（若开源）}}
  - **改造成本**：{{低——直接插入 / 中——需改 forward signature / 高——需重训 backbone}}

### 邻域外参考（若有）

- **邻域外参考**：{{外部工作描述}}——方法学直接借鉴，显式标注不是 source_report 范围内

## 预期结果形态

**成功长什么样**：
{{具体的、可观测的产出。如"1 张 7×5 热力图"，不要写"一篇 paper"}}

**失败情况下仍有什么价值**（⚠️ 必填）：
{{防止 idea 过度乐观。强迫写出 fallback 产出——即便核心假设失败，是否仍能得到有用结论 / 数据 / 工具}}

## 风险与失败模式

{{⚠️ 每条风险**必须**配 1 条 Mitigation 或 Fallback 诊断}}

1. **{{风险名}}**：{{描述}}
   - *Mitigation*：{{具体缓解手段}}
2. **{{风险名}}**：{{描述}}
   - *Mitigation*：{{具体缓解手段}}

## 溯源

- **触发问题**：{{用户原始 query}}
- **支撑 report**：[[...]]
- **信号出处**：{{报告的具体段落位置}}
  > {{引用报告原文快照}}
```

## 字段用途速查

| 字段 | 回答什么问题 |
|---|---|
| `status` | 这 idea 现在在生命周期的哪一步 |
| `effort` | 做一遍要多大代价 |
| `novelty` | 这 idea 原创性够不够（brainstorm 阶段不强求）|
| `risk` | 会不会失败到无产出 |
| `一句话描述` | 这是啥 |
| `为什么值得做` | why 该做这个 |
| `假设` | 要证明 / 反驳什么 |
| **`下一动作`** | **一周后打开这张卡，我该做什么？** |
| `最小实验计划` | 怎么做（5 步内） |
| `可借鉴 baseline` | 能抄谁的整体系统 / 能抄谁的 Module |
| `预期结果形态` | 成功 / 失败都产出什么 |
| `风险与失败模式` | 会在哪卡住 + 怎么救 |
| `溯源` | 这想法是从报告哪里冒出来的 |
| `related_ideas` | 同主题是否已有历史 idea，防重复立项 |
| `linked_experiments` | 本 idea 是否已长出 experiment 卡（由 paper-experiment skill 自动回写） |

## 反例（不要这样写）

❌ 下一动作：`"开始实验"` / `"读相关文献"` / `"写代码"`
　　→ 不是原子级。应写"下载 Liu 2026 附录表 2，提取 RAGAS 子项值"

❌ 最小实验计划 12 步
　　→ 超过 5 步说明 idea 过大，应拆为多个 idea

❌ 风险只列不给 Mitigation
　　→ 不算完整 idea，等同于"我承认有坑但不想处理"

❌ 预期结果只写 "success = 发一篇 paper"
　　→ 太虚。应写具体可观测产出

❌ status=brainstorm 但 novelty 标了 high
　　→ brainstorm 阶段不应 pretend 做过 novelty 检查
