---
name: paper-report
description: |
  跨论文综合分析与 report 产出 skill，专用于 paper-wiki-starter 项目（即本 scaffold 部署出的工作目录，含 CLAUDE.md + schema/prompts/ + wiki/ 结构）。
  通过"积木式"组合应对多类型科研问题（科研缺口、领域演进、方法对比、资源对比、因果归因、分类等）。

  【自动触发条件——出现以下任一信号时立即加载本 Skill】

  显式触发：
  - "写 report" / "写一份报告" / "出一份 report"
  - "/report <主题>" / "/paper-report <主题>"
  - "综合分析" / "跨论文对比" / "找 gap" / "找科研空白"

  隐式触发（用户问的是跨论文问题）：
  - "XX 领域研究进展" / "目前都有哪些路径"
  - "对比 N 种方法" / "X 方法 vs Y 方法"
  - "哪些论文做过 X" / "X 还有什么没人做"
  - "X 是怎么演变的" / "几年来的发展"
  - "数据集 / 工具 / baseline 优劣"

  不触发：
  - 单论文问题（"X 是什么"、"X 论文讲了什么"）→ 直接答
  - 项目无关的通用问答
  - paper-wiki-starter 之外的工作目录
---

# Paper Report Skill — v0.5

跨论文综合分析与 report 产出。本 skill **不替你思考**，它约束的是：
- 流程的可重复性（trigger + 步骤顺序）
- 输出的一致性（骨架 + frontmatter）
- 积木库扩充的反馈回路

判断层（选哪些论文 / 用什么维度 / 什么算 gap）依旧是 LLM judgment，不可强制。

## 三阶段流程

```
[阶段 1] 检索 → 候选论文清单 → 用户确认（强制闸门）
[阶段 2] 分析 → 识别意图 → 选积木 → 填充
[阶段 3] 写入 → 套通用骨架 → wiki/reports/<主题>_<日期>.md
```

## 阶段 1：检索（轻量内联，不另开文件）

1. 从用户问题中抽取 3-5 个候选关键词/概念
2. 对每个 Glob 匹配 `wiki/concepts/*.md`：
   - **命中** → 用 `obsidian backlinks file="<概念>"` 拿权威反向链接清单（高精度）
     输出包含完整反向链接图（concept + paper），需用 `grep "^wiki/papers/"` 过滤只保留论文
     命令要求 Obsidian 应用正在运行
   - **未命中** → 用 `mcp__qmd__query <关键词>` 在 raw 层语义检索（高召回）
3. 合并去重，得到候选论文集合
4. **综述论文优先标注**：在候选集中识别 frontmatter `tags: [综述]` 的论文，标记为"必读"
   - LANDSCAPE / EVOLUTION / TAXONOMY 类问题：综述应作为基础证据，进入阶段 2 前**必须先 Read 完整内容**
   - 其他意图：综述可选读，但仍在闸门列出供用户决定
5. **意图歧义检查**：若用户题目使用了"演进 / 发展 / 现状 / 趋势 / 路径 / 进展"等模糊动词
   → 阶段 1 闸门**必须**附上 2-3 个候选意图解读供用户选（如"时间演进 / 路径演进 / 论文内追溯"）
   → 不做这一步会导致后续意图判断不可重复
6. ⚠️ **强制人机校验闸门**：返回包含
   - 候选论文集合（标注哪些是综述/必读）
   - 意图候选解读（若步骤 5 触发）
   请用户确认后再进入阶段 2
   - 跳过此步是硬错误，会让 skill 退化回"我的即兴判断"

Fallback：Obsidian 应用未运行导致 `obsidian backlinks` 失败时 → 改用 `grep "\[\[<概念>\]\]" wiki/papers/` 作为替代（在 paper_wiki 规范下 alias 回写到卡片，Grep 能覆盖 alias 匹配）。

## 阶段 2：分析

进入此阶段时 **Read 以下文件**：
- `meta-prompt.md` — 元提示词（意图识别 + 积木选择规则）
- `blocks/_index.md` — 积木库索引

按 meta-prompt 的指引：
1. 识别问题意图类型（GAP_FINDING / LANDSCAPE / RESOURCE_COMPARE / METHOD_COMPARE / EVOLUTION / ATTRIBUTION / TAXONOMY / OTHER）
2. 从积木库选 2-4 个积木块
3. 依次 **Read 选中的 `blocks/<name>.md`**，按各自 micro-template 填充

按论文数选数据源：
- **2-3 篇** → Claude 直接 Read 论文卡片（最短路径）
- **≥4 篇** → Read `notebooklm-flow.md`，按其步骤调用 `notebooklm` skill 完成跨文档综合
  - 路径前置确认：在对话中告知用户"将走 NotebookLM 路径（5-15 分钟）"，给"OK / 直读"两个选项
  - Fallback：认证/上传/索引失败 → 退回 Claude 直读 + 标注降级原因（详见 notebooklm-flow.md）

## 阶段 3：写入

Read `report-template.md`，套通用骨架，写入：

```
wiki/reports/<主题简称>_<YYYY-MM-DD>.md
```

写入后必须报告（这是 skill 自审，不是套话）：
- 选用了哪些积木块（让用户审 skill 是否选对了）
- 是否触发了 OTHER 自由形式（提示积木库可能需要扩展）
- 是否有缺失积木的临时替代（缺什么 → 用什么替）

## 边界声明

本 skill 约束的是流程；**不约束**：
- 选哪些论文（LLM judgment + 用户确认闸门）
- 用什么对比维度（积木 micro-prompt 给原则，LLM 即兴）
- 什么算 gap / 什么算 trade-off（LLM judgment）

如果对结果不满意，先定位是哪一层：
- 流程层（skill 跑错了步骤）→ 调 SKILL.md
- 判断层（LLM 选错论文/维度）→ 重跑或在确认闸门修正
- 积木层（缺合适积木）→ 反馈累积到 _index.md，下一轮新建积木

## 命令使用铁律

任何命令（CLI / MCP / 第三方 skill 提供的命令）在 skill 文档中首次出现时，**必须先 `--help` 实测一次确认 syntax**，不可只依赖文档。

**为什么必须明写**：LLM 看到不确定 syntax 时倾向走 fallback，导致 skill 名义主路径从未被实际使用。文档准确性**直接驱动行为**——错的文档等于失效的功能。
