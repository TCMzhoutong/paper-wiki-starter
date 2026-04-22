---
name: paper-idea
description: |
  在 paper-wiki-starter 项目中主动产出研究 idea 的 skill。基于 paper-report skill 作为子流程，
  先产出调研 report → 扫描 idea 信号 → 用户挑选 → 写 idea 卡片到 wiki/ideas/。
  专用于 paper-wiki-starter 项目（即本 scaffold 部署出的工作目录）。

  【自动触发条件——出现以下任一信号时立即加载本 Skill】

  显式触发：
  - "找 idea" / "帮我找 idea" / "帮我想 idea" / "我想要新 idea"
  - "/idea <主题>" / "/paper-idea <主题>"
  - "找研究方向" / "找新点子" / "找选题"

  隐式触发：
  - "我想做 X 但不知道切入点"
  - "X 领域有什么可以做 / 值得做"

  不触发（应走其他 skill 或直接回答）：
  - "综合分析 X" / "写 report" → 用 paper-report
  - "X 是什么" / "X 论文讲了什么" → 直接答
  - paper-wiki-starter 之外的工作目录
---

# Paper Idea Skill — v0.1

## 与 paper-report 的分工

| skill | 产出 | 生命周期 | 使用频率 | LLM 决策深度 |
|---|---|---|---|---|
| paper-report | 事实综合（report） | 查询快照 | 日更 | 浅（只整理） |
| **paper-idea** | **可执行方向（idea 卡）** | **研究资产** | **稀疏** | 深（但仍交还用户决策） |

paper-idea **内部调用** paper-report 作为子流程（阶段 1-2），独立价值在阶段 3-5。

## 5 阶段流程

```
[阶段 1-2] 调用 paper-report skill 产出支撑 report
           ⚠️ 积木偏好 override：强制 gap-ranking + matrix + tradeoff

[阶段 3] 扫描 report 中的 idea 信号（按 signal-scanner.md）
         → 候选 idea 清单

[阶段 4] 用户挑选（不自动落盘——候选 ≠ idea）

[阶段 5] 为每个选中项按 ideas-template.md 写入
         wiki/ideas/<短标题>_<YYYY-MM-DD>.md
```

## 阶段 1-2：调用 paper-report

通过 Skill 工具：

```
Skill: paper-report
args: <用户主题>
```

在传入的 args 结尾**附加 override 指令**：

```
<原用户主题>

[paper-idea 调用 override]：
- 意图强制为 GAP_FINDING（不做常规意图识别）
- 积木组合限定：matrix + gap-ranking + tradeoff（其他积木不选）
- 理由：idea 模式已确定主意图，配最易产出信号的积木
```

paper-report 执行完毕后，记下生成的 report 文件路径。

## 阶段 3：信号扫描

Read `signal-scanner.md`，按其规则扫描刚生成的 report，抽取候选 idea。输出候选清单（最多 10 个）。

## 阶段 4：用户挑选

在对话中呈现候选清单，每个候选有：
- 编号
- 一句话概要（≤ 30 字）
- 信号类别（⭐⭐⭐ / ⭐⭐ / ⭐）
- 信号出处（report 的哪一段）
- effort / risk 粗估

用户回复示例：
- `1 3` → 把 candidate 1 和 3 转为 idea 卡
- `全要` → 全部转（慎用，多数情况不建议）
- `不要` → 终止流程，不生成卡片
- `换一组` → 退回阶段 3 重扫，提示用户是想要更宽/更窄

⚠️ **绝不跳过此闸门**——候选 ≠ idea，idea 必须是用户挑出来的。

## 阶段 5：写入 idea 卡

### 5.1 素材加载（前置，不可跳过）

**为什么需要**：`下一动作`（原子级）/ `最小实验计划` / `可借鉴 baseline 方法` / `风险 Mitigation` 这些字段需要**论文原文级细节**（附录表结构、超参、完整 baseline 描述）。signal-scanner 抓到的一句话信号 + report.md 蒸馏产出不够；`wiki/papers/` 卡片也不够（精读压缩层）。必须回 `raw/md/` 取。

**执行**（对每个选中候选涉及的每篇 related_paper，6 族穷举，全部并行发出）：

1. `qmd doc-toc qmd://papers/<name>` — 拿章节骨架
2. `qmd doc-grep qmd://papers/<name> "<pattern>"` — 按下列 6 族关键词扫描：

   | 族 | 最小关键词集 |
   |---|---|
   | baseline | `baseline` |
   | 配置 | `implementation` / `hyperparam` / `setup` |
   | 评估 | `metric` / `evaluation` |
   | 数据 | `dataset` |
   | 限制 | `limitation` / 中文 "限制" / "不足" |
   | 附录 | `appendix` / `supplement` |

   每个 related_paper **≥ 6 次 doc-grep**（每族 ≥ 1）。N 篇论文 = ≥ 6N 次 grep。中文论文加中文关键词
3. grep 返回 `content` 是整段内容，直接作为素材；需相邻上下文按 address 调 `qmd doc-read`
4. 某族 `total_matches: 0` 不是错误——说明论文未覆盖该维度；5.2 填字段时诚实标注"原文未覆盖"，不凭背景知识补

**Fallback**：

| 情况 | 处置 |
|---|---|
| qmd 未索引该论文（`qmd ls` 确认） | `Read raw/md/<name>.md` 全文 + 在溯源段标注 "qmd 未覆盖，走全文 Read" |
| `raw/md/<name>.md` 不存在（未走 `add-paper.sh`） | `Read wiki/papers/<name>.md` 卡片 + 标注 "raw/md 缺失，细节可能不足" |

### 5.2 按模板填充

Read `ideas-template.md`，为每个选中候选按模板填充，写入：

```
wiki/ideas/<短标题>_<YYYY-MM-DD>.md
```

**关键字段填充规则**：
- `status`：brainstorm（首次生成）
- `novelty`：unchecked（brainstorm 阶段默认，不要凭 LLM 猜测）
- `effort` / `risk`：从 signal-scanner 粗估继承
- `related_ideas`：**Grep `wiki/ideas/`** 找同 `tags` 或同 `source_report` 的历史 idea 卡，列出文件名 wikilink；无则 `[]`（不硬凑）。**不走 qmd**——这是 wiki 内部查重，不是论文原文检索
- `下一动作` / `最小实验计划` / `可借鉴 baseline`（含 Module/Trick）/ `风险 Mitigation` **严格基于 5.1 加载的 qmd 素材**，不允许凭 LLM 背景知识填充。每条具体主张应能追溯到某次 `qmd doc-grep` 或 `qmd doc-read` 返回的段落
- `为什么值得做`的**负向段**（"不做会怎样"）：主要基于 report 全景 + LLM 论证，qmd 可选辅助（grep `limitation` / `remains a challenge` 看作者自述痛点）；不强制 qmd 追溯
- `下一动作`：必须是**原子级具体动作**（1-2 小时内可启动）；如"发邮件给 X 问 Y 是否可共享"、"跑一遍 RAGAS 对 Liu 的 600 条输出"。反例：❌"复现 Liu 的 TOSRR"（太大）

## 阶段 5 后的自审报告

写入后必须在对话中报告：
- 生成的 idea 卡文件名列表
- 每张卡的 `下一动作`（让用户一眼看到下一步）
- 若生成卡片数 ≥ 2，提醒"建议择一优先做，不要并行"——避免 idea 库膨胀

## 边界声明

paper-idea 约束的是流程 + 格式；**不约束**：
- 哪些信号值得转为 idea（用户挑选决定）
- idea 是否真的值得做（novelty 检查在 status 流转到 shortlisted 时才强制）
- 实验计划是否可行（这是用户自己判断）

本 skill 提供的是**可审计的 idea 产出管道**，不是"idea 质量保证"。

## Fallback

| 情况 | 处置 |
|---|---|
| paper-report 调用失败 | 整个 paper-idea 流程终止，提示用户先修 paper-report |
| 阶段 3 扫不出 ≥ 1 个候选 | 不写空卡，回报 "本主题无法浮现 idea，建议换题或扩大 report 素材" |
| 用户回 `不要` | 保留 report，不生成 idea，退出 |
