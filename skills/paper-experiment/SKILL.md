---
name: paper-experiment
description: |
  在 paper-wiki-starter 项目中产出"可直接照抄"的实验方案卡片 skill。基于 paper-report skill 作为子流程，
  先产出 method/resource 对比 report → 扫描可抄素材 → 用户挑选 → 写实验方案卡到 wiki/experiments/。
  专用于 paper-wiki-starter 项目（即本 scaffold 部署出的工作目录）。

  【自动触发条件——出现以下任一信号时立即加载本 Skill】

  显式触发：
  - "实验方案" / "实验设计" / "复现 X"
  - "baseline 怎么选" / "baseline 配置" / "照抄配置"
  - "metric 怎么选" / "评估指标选型"
  - "/experiment <主题>" / "/paper-experiment <主题>"

  隐式触发：
  - "我要跑 X 实验" / "我准备做 Y"
  - "怎么复现 Z"
  - "做 X 需要哪些数据 / 模型 / 动物 / 患者"

  不触发（应走其他 skill 或直接回答）：
  - "找 idea" / "找方向" → 用 paper-idea
  - "综合分析 X" / "写 report" → 用 paper-report
  - "X 是什么" / "X 论文讲了什么" → 直接答
  - paper-wiki-starter 之外的工作目录
---

# Paper Experiment Skill — v0.1

## 与 paper-report / paper-idea 的分工

| skill | 产出 | 生命周期 | 回答的问题 |
|---|---|---|---|
| paper-report | 事实综合（report） | 查询快照 | X 领域全景是什么 |
| paper-idea | 可执行方向（idea 卡） | 研究资产 | 我应该做什么方向（WHY） |
| **paper-experiment** | **可照抄的实验方案（experiment 卡）** | **研究资产** | **我决定做 X 了，具体怎么做（HOW）** |

paper-experiment **内部调用** paper-report 作为子流程（阶段 1-2），独立价值在阶段 3-5。

## 6 阶段流程

```
[阶段 0] source_idea 识别（入口闸门）—— 决定本 experiment 是否衍生自某 idea 卡

[阶段 1-2] 调 paper-report（override：METHOD_COMPARE + matrix + tradeoff）

[阶段 3] 按 experiment-scanner.md 扫 report 的可抄素材信号
         → 候选 baseline / 数据 / metric / SOP 清单

[阶段 4] 用户挑选（候选 ≠ 卡；合并或拆分由用户决定）

[阶段 5]
  5.0 实验类型识别闸门（7 类 + other）
  5.1 qmd 前置素材加载（6 族穷举并行）
  5.2 按 experiment-template 的"通用骨架 + 类型变体"写入 wiki/experiments/
  5.3 若 source_idea 非空，回写 idea 卡的 linked_experiments 字段
```

## 阶段 0：source_idea 识别（入口闸门）

**目的**：在调 paper-report 之前确定本 experiment 是否有上游 idea 卡。source_idea 值会贯穿全流程（影响 5.3 双向链接回写）。

**判断逻辑**：

1. **用户输入含 `[[idea 卡文件名]]`**（级别 A，显式）：
   - 直接提取 wikilink 作为 `source_idea`
   - 验证文件存在于 `wiki/ideas/<name>.md`；不存在 → 警告 + 退到级别 B
   - 主题字符串 = 用户输入去掉 wikilink 后的剩余部分

2. **用户输入是纯主题字符串**（级别 B，隐式）：
   - Grep `wiki/ideas/*.md` 按 `title` / `tags` / frontmatter 关键词匹配主题
   - 找到 ≥ 1 个候选 → **闸门**：呈候选列表问用户选哪个作 source_idea（或选 `none` 表示无）
   - 找不到候选 → 直接 `source_idea = null`，继续

3. **用户明确声明无上游 idea**（级别 C）：
   - 用户输入含 "无 idea" / "--no-idea" 等关键词 → 跳过 Grep，直接 `source_idea = null`

**闸门呈现**（级别 B 触发时）：

```
阶段 0：检测到 wiki/ideas/ 下可能相关的 idea 卡：
1. [[中药配伍禁忌图谱_2026-04-15]] — tags: [神经符号人工智能, 安全边界]
2. [[名医动态个性化图谱_2026-04-15]] — tags: [个性化, 多模态]

请回复：
- `1` → 设为 source_idea
- `none` → 无上游 idea，独立立项
- `换匹配` → 扩大/收紧匹配重扫
```

⚠️ 级别 B 候选数 > 5 时，按 tag 重合度降序取前 5。

**记录结果**：`source_idea` 值作为全流程常量，后续所有阶段引用此值。

## 阶段 1-2：调用 paper-report

通过 Skill 工具：

```
Skill: paper-report
args: <用户主题>

[paper-experiment 调用 override]：
- 意图强制为 METHOD_COMPARE（不做常规意图识别）
- 积木组合限定：matrix + tradeoff（其他积木不选）
- 理由：experiment 已确定主意图，配最直接给"可抄配置"的积木
```

paper-report 完毕后记下 report 文件路径。

## 阶段 3：信号扫描

Read `experiment-scanner.md`，按 6 类"可抄素材"信号扫 report，输出候选清单（≤ 10）。

## 阶段 4：用户挑选

呈现候选清单，每条含：编号 / 一句话概要（≤ 30 字，动词开头） / 信号类别 / 信号出处（具体到 matrix 行列或 tradeoff 段）/ effort / risk。

用户回复：
- `1 3` → 转候选 1 和 3
- `1+3 合并` / `1,3 分开` → 显式指定合并或拆卡（默认 skill 自动判断：同类型且共享 baseline 则合并，否则分开）
- `全要` / `不要` / `换一组`

⚠️ 绝不跳过此闸门。

## 阶段 5：写入 experiment 卡

### 5.0 实验类型识别闸门（不可跳过）

判断类型（据用户主题 + 选中 baseline 所属论文的 venue/type）：

| 类型代码 | 语义 | 典型信号 |
|---|---|---|
| `computational` | AI / ML 工科 | baseline 是 LLM/CNN/GNN；涉及数据集、超参、GPU、repo |
| `animal` | 动物实验 | "大鼠/小鼠/模型组/给药"；SPF 级、ip/po 给药 |
| `clinical` | 人体临床试验 | "患者/纳排/随机/盲法/终点/注册号"；ChiCTR / ClinicalTrials.gov |
| `in-vitro` | 体外细胞 / 生化 | "细胞系/培养/Western blot/qPCR/流式" |
| `omics` | 多组学 / 生信 | "转录组/代谢组/蛋白组/测序平台/GEO/TCGA" |
| `mixed` | 多类型组合 | 如"网络药理学 + 动物验证 + 临床" |
| `other` | 不属于上述 | 自由形式 + `experiment_type: other: <一句话描述>` |

**闸门呈现**：向用户报告"本 experiment 识别为 `<类型>`，依据 `<信号>`。确认 / 改类型？"

识别错会让"研究对象 + 配置"段用错变体模板——这是本 skill 的核心杠杆点。

### 5.1 qmd 素材加载（前置，不可跳过）

**为什么需要**：experiment 卡要精确到超参/剂量/纳排标准，必须从 `raw/md/` 原文取（signal-scanner 抓的一句话信号 + report.md 蒸馏产出不够；wiki/papers/ 卡片是精读压缩层）。

**执行**（对每个选中候选的每篇 related_paper，6 族穷举 + 并行）：

1. `qmd doc-toc qmd://papers/<name>` — 章节骨架
2. `qmd doc-grep qmd://papers/<name> "<pattern>"` — 按 6 族关键词（随 `experiment_type` 微调）：

   | 族 | 最小关键词集（按 type） |
   |---|---|
   | baseline | `baseline`（computational） / `对照组`（animal/clinical） / `参照`（通用） |
   | 配置 | `implementation` / `hyperparam` / `setup`（computational）；`剂量` / `给药`（animal）；`纳入` / `排除`（clinical）；`细胞系` / `培养`（in-vitro） |
   | 评估 | `metric` / `evaluation`（computational）；`终点`（clinical）；`检测指标`（animal / in-vitro） |
   | 数据 | `dataset`（computational）；`样本量` / `队列`（animal / clinical） |
   | 限制 | `limitation` / 中文 "限制" / "不足" |
   | 附录 | `appendix` / `supplement` / `附录` |

   每个 related_paper **≥ 6 次 doc-grep**（每族 ≥ 1）。N 篇 = ≥ 6N 次 grep。中文论文加中文关键词
3. grep 返回 `content` 直接作素材；需相邻上下文按 address 调 `qmd doc-read`
4. 某族 `total_matches: 0` 不是错误——5.2 填字段时诚实标注"原文未覆盖"，不凭背景知识补

**Fallback**：

| 情况 | 处置 |
|---|---|
| qmd 未索引该论文（`qmd ls` 确认） | `Read raw/md/<name>.md` 全文 + 溯源段标注 "qmd 未覆盖" |
| `raw/md/<name>.md` 不存在 | `Read wiki/papers/<name>.md` 卡片 + 标注 "raw/md 缺失，细节可能不足" |

### 5.2 按模板填充

Read `experiment-template.md`，按 5.0 识别的类型选"研究对象 + 具体配置"变体：
- 通用骨架 9 段所有类型共有
- 第 3 段按类型选子模板（computational / animal / clinical / in-vitro / omics / mixed / other）
- mixed 类型：第 3 段内嵌多个子段（每阶段一个），显式写**阶段间衔接关系**

写入：

```
wiki/experiments/<短标题>_<YYYY-MM-DD>.md
```

**关键字段填充规则**：
- `status`：planned（首次生成）
- `experiment_type`：5.0 识别的类型代码（若 other 必须补一句话描述）
- `source_idea`：若本 experiment 衍生自某 idea 卡，填 `[[idea 卡文件名]]`；否则 `null`
- `related_papers`：选中 baseline 所属论文
- `effort` / `risk`：从 signal-scanner 粗估继承
- `借鉴的先前研究` / `研究对象 + 具体配置` / `实施 checklist` / `已知陷阱` **严格基于 5.1 的 qmd 素材**，每条主张可追溯到 `qmd doc-grep` 或 `qmd doc-read` 返回的段落
- 禁止凭 LLM 背景知识填具体剂量 / 超参 / 纳排标准

### 5.3 双向链接回写

若 `source_idea` 非空：**Edit 该 idea 卡 frontmatter** 的 `linked_experiments` 字段，追加本 experiment 卡文件名：

```yaml
linked_experiments: ["[[<本 experiment 文件名>]]", ...]
```

只追加，不覆盖已有值。若 idea 卡已被删/重命名 → 不中断，仅在自审报告中警告。

## 阶段 5 后的自审报告

写入后必须在对话中报告：
- 生成的 experiment 卡文件名
- 识别的实验类型 + 用户是否确认
- 用了哪些论文的哪些配置（具体到 qmd address）
- `source_idea` 是否回写成功
- 若生成卡 ≥ 2，提醒"建议择一先跑"

## 边界声明

本 skill 约束流程 + 格式；**不约束**：
- 实验方案是否"最优"（LLM judgment + 用户判断）
- 伦理审批是否充分（由用户自行申请）
- 复现代码是否能跑（由用户实测）

本 skill 提供**可审计的实验方案产出管道**，不是"实验方案质量保证"。

## Fallback

| 情况 | 处置 |
|---|---|
| 阶段 0 用户指定的 idea 卡不存在 | 警告 + 退到级别 B（Grep 匹配）；仍不行则 source_idea = null 继续 |
| paper-report 调用失败 | 整个流程终止，提示先修 paper-report |
| 阶段 3 扫不出 ≥ 1 个候选 | 不写空卡，回报 "本主题无法浮现可抄素材" |
| 5.0 实验类型无法判定 | 退到 `other` + 用户填一句话描述 |
| 5.3 idea 卡回写失败 | 不中断，自审报告警告 |
| 用户回 `不要` | 保留 report，不生成卡，退出 |
